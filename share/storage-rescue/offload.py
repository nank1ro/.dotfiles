#!/usr/bin/env python3
"""Storage Rescue offload: copy to one or more archive roots, verify, re-verify, then delete sources.

Usage: offload.py PLAN.json copy|reverify|delete|status

Based on the storage-rescue offload protocol. Additions: several roots (each needs every job
verified and re-verified before a source is deleted), volume UUID binding with a stop on
disconnect, xattr preservation for copy jobs on roots that support it, and a local manifest
mirror per root under ~/.agents/archive/.
"""
import base64, ctypes, errno, fcntl, gzip, hashlib, json, os, plistlib, secrets, stat, subprocess, sys, tarfile, time, unicodedata
from compression import zstd
from pathlib import Path

CHUNK = 8 * 1024 * 1024
F_NOCACHE = 48
RENAME_EXCL = 0x4
XATTR_NOFOLLOW = 0x1
_libc = ctypes.CDLL(None, use_errno=True)
BAD = {c: "_" for c in '<>:"\\|?*'}
RESERVED = {"CON", "PRN", "AUX", "NUL", *(f"COM{i}" for i in range(1, 10)), *(f"LPT{i}" for i in range(1, 10))}
VERIFIED = ("verified", "identical-already-present-verified", "archive-verified")
LOCAL_DIR = Path(os.environ.get("STORAGE_RESCUE_LOCAL", Path.home() / ".agents" / "archive"))


class DriveGone(Exception):
    pass

# ---------- volume binding

def volume_uuid(path):
    out = subprocess.run(["diskutil", "info", "-plist", path], capture_output=True)
    if out.returncode != 0:
        return None
    return plistlib.loads(out.stdout).get("VolumeUUID")

class Root:
    def __init__(self, spec):
        self.path = Path(spec["path"])
        self.uuid = spec["uuid"]
        self.label = spec["label"]
        self.xattrs = spec.get("xattrs", False)
        self.mount = Path(spec["mount"])
        self.dev = None

    def check(self):
        """Raise DriveGone unless the expected volume is mounted at the expected place."""
        if not os.path.ismount(self.mount):
            raise DriveGone(f"{self.label}: {self.mount} is not mounted")
        dev = os.stat(self.mount).st_dev
        if self.dev is None:
            if volume_uuid(str(self.mount)) != self.uuid:
                raise DriveGone(f"{self.label}: volume at {self.mount} is not UUID {self.uuid}")
            if os.stat(Path.home()).st_dev == dev:
                raise DriveGone(f"{self.label}: root is on the Mac's own disk")
            self.dev = dev
        elif dev != self.dev:
            raise DriveGone(f"{self.label}: volume changed since the run started")

    @property
    def manifests(self):
        return [self.path / "Transfer-Logs" / "manifest.jsonl", LOCAL_DIR / f"{self.label}-manifest.jsonl"]

# ---------- helpers (from the reference implementation)

def safe_name(name):
    name = unicodedata.normalize("NFC", name)
    name = "".join(BAD.get(c, c) if ord(c) >= 32 else "_" for c in name)
    stripped = name.rstrip(" .")
    if stripped != name:
        name = stripped + "_"
    if name.split(".")[0].upper() in RESERVED:
        name = "_" + name
    return name or "_"

def hash_nocache(path):
    h = hashlib.sha256()
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    try:
        fcntl.fcntl(fd, F_NOCACHE, 1)
        while True:
            b = os.read(fd, CHUNK)
            if not b:
                break
            h.update(b)
    finally:
        os.close(fd)
    return h.hexdigest()

def hash_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            b = f.read(CHUNK)
            if not b:
                break
            h.update(b)
    return h.hexdigest()

INCOMPLETE = "previous-line-incomplete"  # marker written after a line an interrupted append cut off

def record(manifests, obj):
    obj = dict(obj, at=time.strftime("%Y-%m-%dT%H:%M:%S"))
    line = (json.dumps(obj, ensure_ascii=False) + "\n").encode("utf-8")
    for m in manifests:
        m.parent.mkdir(parents=True, exist_ok=True)
        for attempt in range(6):
            try:
                with open(m, "ab+") as f:
                    data, end = line, f.seek(0, os.SEEK_END)
                    if end:
                        f.seek(end - 1)
                        if f.read(1) != b"\n":  # the last append was cut off: start a new line, mark it
                            data = b"\n" + json.dumps({"status": INCOMPLETE}).encode() + b"\n" + line
                    f.write(data); f.flush(); os.fsync(f.fileno())
                break
            except OSError as e:
                if e.errno not in (17, 70) or attempt == 5:
                    raise
                time.sleep(5)

def read_manifest(path):
    """The records of a manifest. A line cut off by a disconnect is skipped (never trusted) when it is
    the last line or record() marked it; any other unreadable line is an error."""
    if not path.exists():
        return []
    out, bad = [], None
    with open(path, "rb") as f:
        for n, line in enumerate(f, 1):
            if not line.strip():
                continue
            try:
                r = json.loads(line)
            except ValueError:
                r = None
            if bad and not (isinstance(r, dict) and r.get("status") == INCOMPLETE):
                raise ValueError(f"{path}: line {bad} is not a valid record")
            bad = None
            if not isinstance(r, dict):
                bad = n
            elif r.get("status") != INCOMPLETE:
                out.append(r)
    if bad:
        print(f"WARNING: ignoring the incomplete last line {bad} of {path}", file=sys.stderr, flush=True)
    return out

def unique(p):
    if not p.exists() and not p.is_symlink():
        return p
    suffix = next((s for s in (".tar.gz", ".tar.zst") if p.name.endswith(s)), p.suffix)
    stem = p.name[: len(p.name) - len(suffix)] if suffix else p.name
    i = 2
    while True:
        q = p.with_name(f"{stem} ({i}){suffix}")
        if not q.exists() and not q.is_symlink():
            return q
        i += 1

def check_dest(dst, root):
    real_root = os.path.realpath(root)
    parent = os.path.realpath(dst.parent)
    if os.path.commonpath([parent, real_root]) != real_root:
        raise IOError(f"destination resolves outside the drive root: {dst}")
    if dst.is_symlink():
        raise IOError(f"destination is a symlink: {dst}")

def create_temp(dst):
    for _ in range(100):
        part = dst.with_name(f"{dst.name}.sr-{secrets.token_hex(6)}.part")
        try:
            fd = os.open(part, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o666)
        except FileExistsError:
            continue
        st = os.fstat(fd)
        return part, os.fdopen(fd, "wb"), (st.st_dev, st.st_ino)
    raise IOError(f"could not create a temporary file next to {dst}")

def drop_temp(part, ident):
    try:
        st = os.lstat(part)
    except FileNotFoundError:
        return
    if (st.st_dev, st.st_ino) == ident:
        os.unlink(part)

_excl_rename = {}

def has_excl_rename(folder):
    dev = os.stat(folder).st_dev
    if dev not in _excl_rename:
        a, fo, ident = create_temp(Path(folder) / ".sr-probe")
        fo.close()
        b = Path(folder) / f".sr-probe-{secrets.token_hex(6)}.part"
        ok = _libc.renamex_np(os.fsencode(a), os.fsencode(b), RENAME_EXCL) == 0
        err = ctypes.get_errno()
        if ok:
            os.unlink(b)
        else:
            drop_temp(a, ident)
            if err not in (errno.ENOTSUP, errno.EINVAL):
                raise OSError(err, os.strerror(err), str(folder))
        _excl_rename[dev] = ok
    return _excl_rename[dev]

def create_final(dst):
    wanted = dst
    for _ in range(1000):
        dst = unique(wanted)
        try:
            fd = os.open(dst, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o666)
        except FileExistsError:
            continue
        st = os.fstat(fd)
        return dst, os.fdopen(fd, "wb"), (st.st_dev, st.st_ino)
    raise IOError(f"no free destination name for {wanted}")

def open_output(dst):
    if has_excl_rename(dst.parent):
        part, fo, ident = create_temp(dst)
        return part, fo, ident, False
    path, fo, ident = create_final(dst)
    return path, fo, ident, True

def publish(part, dst):
    if _libc.renamex_np(os.fsencode(part), os.fsencode(dst), RENAME_EXCL) != 0:
        err = ctypes.get_errno()
        raise OSError(err, os.strerror(err), str(dst))

def finish(part, dst):
    wanted = dst
    for _ in range(1000):
        dst = unique(wanted)
        try:
            publish(part, dst)
            return dst
        except FileExistsError:
            continue
    raise IOError(f"no free destination name for {wanted}")

def give_up(job, path, ident, direct, manifests, attempt=None):
    if not direct:
        drop_temp(path, ident)
        return
    print("UNVERIFIED FILE LEFT ON THE DRIVE", path, flush=True)
    try:
        record(manifests, {"job": job, "attempt": attempt, "dest": str(path), "status": "unverified-leftover"})
    except OSError:
        pass

def _raise(err):
    raise err

def _entry(p, st):
    m = st.st_mode
    kind = "f" if stat.S_ISREG(m) else "d" if stat.S_ISDIR(m) else "l" if stat.S_ISLNK(m) else "o"
    if kind == "d":  # no mtime/ctime: they change when entries are added or removed
        return [kind, 0, 0, st.st_ino, 0, "", stat.S_IMODE(m)]
    return [kind, st.st_size, st.st_mtime_ns, st.st_ino, st.st_ctime_ns, os.readlink(p) if kind == "l" else ""]

def inventory(src):
    src = Path(src)
    top = os.lstat(src)
    if not stat.S_ISDIR(top.st_mode):
        return {".": _entry(src, top)}
    inv = {}
    for root, dirs, files in os.walk(src, onerror=_raise):
        dirs.sort()
        for name in dirs + sorted(files):
            p = os.path.join(root, name)
            inv[os.path.relpath(p, src)] = _entry(p, os.lstat(p))
    return inv

# ---------- xattrs (macOS libc, never following symlinks)

def list_xattrs(path):
    p = os.fsencode(path)
    n = _libc.listxattr(p, None, 0, XATTR_NOFOLLOW)
    if n <= 0:
        return {}
    buf = ctypes.create_string_buffer(n)
    n = _libc.listxattr(p, buf, n, XATTR_NOFOLLOW)
    out = {}
    for name in buf.raw[:n].split(b"\0"):
        if not name:
            continue
        size = _libc.getxattr(p, name, None, 0, 0, XATTR_NOFOLLOW)
        if size < 0:
            continue
        val = ctypes.create_string_buffer(max(size, 1))
        size = _libc.getxattr(p, name, val, size, 0, XATTR_NOFOLLOW)
        out[name.decode("utf-8", "surrogateescape")] = val.raw[:size]
    return out

def copy_xattrs(src, dst):
    """Copy xattrs and verify them. Returns names macOS refused to set (protected attributes)."""
    want = {k: v for k, v in list_xattrs(src).items() if k not in SKIP_XATTRS}
    refused = []
    for name, val in want.items():
        rc = _libc.setxattr(os.fsencode(dst), name.encode("utf-8", "surrogateescape"), val, len(val), 0, XATTR_NOFOLLOW)
        if rc != 0:
            refused.append(name)
    got = list_xattrs(dst)
    for name, val in want.items():
        if name not in refused and got.get(name) != val:
            raise IOError(f"xattr {name} did not verify on {dst}")
    return refused

SKIP_XATTRS = {"com.apple.provenance"}  # set by macOS itself; cannot be restored

def xattr_map(src, inv):
    """rel -> {name: base64 value} for every entry (symlinks too), so restore can put them back."""
    out = {}
    for rel in ([] if "." in inv else ["."]) + list(inv):
        p = src if rel == "." else src / rel
        x = {k: base64.b64encode(v).decode() for k, v in list_xattrs(p).items() if k not in SKIP_XATTRS}
        if x:
            out[rel] = x
    return out

# ---------- copy mode

def set_meta(src, dst, root, mode):
    """xattrs (on roots that keep them) while the file is writable, then the permission bits."""
    refused = None
    if root.xattrs:
        os.chmod(dst, 0o600)
        refused = copy_xattrs(src, dst)
    try:
        os.chmod(dst, mode)
    except OSError:
        if root.xattrs:
            raise
    return refused

def copy_verified(job, src, dst, root, manifests, attempt=None):
    dst.parent.mkdir(parents=True, exist_ok=True)
    check_dest(dst, root.path)
    st0 = os.lstat(src)
    if not stat.S_ISREG(st0.st_mode):
        raise IOError(f"not a regular file: {src}")
    mode = stat.S_IMODE(st0.st_mode)
    if dst.exists():
        if os.path.samefile(src, dst):
            raise IOError(f"destination is the source itself: {dst}")
        if dst.stat().st_size == st0.st_size:
            src_sha = hash_file(src)
            if hash_nocache(dst) == src_sha:
                set_meta(src, dst, root, mode)
                record(manifests, {"job": job, "attempt": attempt, "src": str(src), "dest": str(dst), "rel": str(dst.relative_to(root.path)),
                                   "size": st0.st_size, "mode": mode, "sha256": src_sha, "status": "identical-already-present-verified"})
                return
        dst = unique(dst)
    part, fo, ident, direct = open_output(dst)
    h = hashlib.sha256()
    try:
        with open(src, "rb") as fi, fo:
            while True:
                b = fi.read(CHUNK)
                if not b:
                    break
                h.update(b); fo.write(b)
            fo.flush(); os.fsync(fo.fileno())
            st = os.fstat(fo.fileno())
            ident = (st.st_dev, st.st_ino)
        st1 = os.lstat(src)
        if _entry(src, st1) != _entry(src, st0):
            raise IOError(f"source changed during copy: {src}")
        if part.stat().st_size != st0.st_size or hash_nocache(part) != h.hexdigest():
            raise IOError(f"verification failed: {src}")
        dst = part if direct else finish(part, dst)
    except BaseException:
        give_up(job, part, ident, direct, manifests, attempt)
        raise
    os.utime(dst, ns=(st0.st_atime_ns, st0.st_mtime_ns))
    refused = set_meta(src, dst, root, mode)
    record(manifests, {"job": job, "attempt": attempt, "src": str(src), "dest": str(dst), "rel": str(dst.relative_to(root.path)),
                       "size": st0.st_size, "mode": mode, "sha256": h.hexdigest(), "status": "verified",
                       **({"xattrs_refused": refused} if refused else {})})

def copy_job(job, src, dst_root, root, inv, manifests, attempt=None):
    special = [k for k, v in inv.items() if v[0] not in ("f", "d")]
    if special:
        raise IOError(f"symlinks or special files, use tgz or tar mode: {special[:5]}")
    if inv.get(".", [""])[0] == "f":
        copy_verified(job, src, dst_root, root, manifests, attempt)
        return
    dst_root.mkdir(parents=True, exist_ok=True)
    for rel, (kind, *_rest) in inv.items():
        out = dst_root.joinpath(*[safe_name(p) for p in Path(rel).parts])
        if kind == "d":
            out.mkdir(parents=True, exist_ok=True)
        else:
            copy_verified(job, src / rel, out, root, manifests, attempt)
    if root.xattrs:  # folders (for example .screenstudio bundles) can carry Finder info too
        for rel, (kind, *_rest) in [(".", ("d",))] + list(inv.items()):
            if kind == "d":
                out = dst_root if rel == "." else dst_root.joinpath(*[safe_name(p) for p in Path(rel).parts])
                copy_xattrs(src if rel == "." else src / rel, out)

# ---------- archive mode

class _Hashing:
    def __init__(self, f): self.f, self.h = f, hashlib.sha256()
    def read(self, n=-1):
        b = self.f.read(n); self.h.update(b); return b

class _NoCache:
    def __init__(self, path):
        self.fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW); fcntl.fcntl(self.fd, F_NOCACHE, 1)
    def read(self, n=-1): return os.read(self.fd, CHUNK if n is None or n < 0 else n)
    def close(self): os.close(self.fd)

def _kind(t):
    return "f" if t.isreg() else "d" if t.isdir() else "l" if t.issym() else "h" if t.islnk() else "p" if t.isfifo() else "o"

class _ZstdTar:
    """tar stream through zstd level 3: about 6x faster than gzip -9 here, and slightly smaller."""
    def __init__(self, f):
        self.z = zstd.ZstdFile(f, "w", level=3)
        self.tar = tarfile.open(fileobj=self.z, mode="w|", format=tarfile.PAX_FORMAT)
    def __enter__(self): return self.tar
    def __exit__(self, *exc):
        self.tar.close(); self.z.close()

def _tar_writer(out, comp):
    if comp == "zst":
        return _ZstdTar(out)
    return tarfile.open(fileobj=out, mode="w|gz" if comp == "gz" else "w|", format=tarfile.PAX_FORMAT)

def _tar_reader(raw, comp):
    if comp == "zst":
        return zstd.ZstdFile(raw)
    return gzip.GzipFile(fileobj=raw) if comp == "gz" else raw

def pack_job(job, src, dest, root, inv, manifests, comp="zst", attempt=None):
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest = unique(dest)
    check_dest(dest, root.path)
    part, out, ident, direct = open_output(dest)
    expected, total = {}, 0
    entries = [src] + [src / rel for rel in inv if rel != "."]
    try:
        with out:
            with _tar_writer(out, comp) as tar:
                for p in entries:
                    arc = src.name if p == src else str(Path(src.name) / p.relative_to(src))
                    ti = tar.gettarinfo(str(p), arcname=arc)
                    if ti is None:
                        raise IOError(f"cannot archive socket or device: {p}")
                    ti.uname = ti.gname = ""
                    if ti.isreg():
                        with open(p, "rb") as f:
                            hr = _Hashing(f); tar.addfile(ti, hr)
                        expected[arc] = ("f", ti.size, hr.h.hexdigest()); total += ti.size
                    else:
                        tar.addfile(ti); expected[arc] = (_kind(ti), 0, ti.linkname)
            out.flush(); os.fsync(out.fileno())
            st = os.fstat(out.fileno())
            ident = (st.st_dev, st.st_ino)
        seen = {}
        reader = _NoCache(part)
        hashed = _Hashing(reader)  # SHA-256 of the compressed file, from this same read
        try:
            raw = _tar_reader(hashed, comp)
            with tarfile.open(fileobj=raw, mode="r|") as tar:
                for m in tar:
                    if m.isreg():
                        f, h = tar.extractfile(m), hashlib.sha256()
                        while True:
                            b = f.read(CHUNK)
                            if not b:
                                break
                            h.update(b)
                        seen[m.name] = ("f", m.size, h.hexdigest())
                    else:
                        seen[m.name] = (_kind(m), 0, m.linkname)
            while hashed.read(CHUNK):  # the readers may stop before trailing padding
                pass
        finally:
            reader.close()
        if seen != expected:
            raise IOError(f"archive verification failed: {src}")
        dest = part if direct else finish(part, dest)
    except BaseException:
        give_up(job, part, ident, direct, manifests, attempt)
        raise
    files = {k: v[2] for k, v in expected.items() if v[0] == "f"}
    for k, (kind, _size, target) in expected.items():
        if kind == "h":
            files[k] = files[target]
    record(manifests, {"job": job, "attempt": attempt, "src": str(src), "dest": str(dest), "rel": str(dest.relative_to(root.path)),
                       "size": dest.stat().st_size, "sha256": hashed.h.hexdigest(), "status": "archive-verified",
                       "members": len(expected), "source_bytes": total, "files": files})

# ---------- phase 1: copy

def note_appledouble(root):
    out = root / "Transfer-Logs" / "appledouble-before.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    known = set()
    if out.exists():
        with open(out, encoding="utf-8") as f:
            known = set(json.load(f))
    known |= {os.path.join(d, n) for d, _s, fs in os.walk(root, onerror=_raise) for n in fs if n.startswith("._")}
    tmp = out.with_name(f"{out.name}.{secrets.token_hex(6)}.tmp")
    with open(tmp, "x", encoding="utf-8") as f:
        json.dump(sorted(known), f, ensure_ascii=False); f.flush(); os.fsync(f.fileno())
    os.replace(tmp, out)

def in_use(src):
    args = ["lsof", "-n", "+D", str(src)] if os.path.isdir(src) else ["lsof", "-n", str(src)]
    out = subprocess.run(args, capture_output=True, text=True)
    return [l for l in out.stdout.splitlines()[1:]]

PART = __import__("re").compile(r".+\.sr-[0-9a-f]{12}\.part$")

def drop_stale_parts(root):
    """Remove temporary files an interrupted run of this tool left in its own archive folder."""
    for d, _s, fs in os.walk(root.path):
        for n in fs:
            if PART.match(n):
                p = os.path.join(d, n)
                if stat.S_ISREG(os.lstat(p).st_mode):
                    os.unlink(p); print("removed leftover", p, flush=True)

def same_source(src, copied):
    """The source is still in the state its job-copied record describes."""
    try:
        inv = inventory(src)
        return (inv == copied["inventory"] and copied.get("top") in (None, _entry(src, os.lstat(src)))
                and xattr_map(src, inv) == copied.get("xattrs", {}))
    except OSError:
        return False

def run_copy_phase(plan, root):
    root.check()
    root.path.mkdir(parents=True, exist_ok=True)
    drop_stale_parts(root)
    note_appledouble(root.path)
    done = {}  # job -> its latest job-copied record, unless the source was deleted after it
    for r in read_manifest(root.manifests[0]):
        if r["status"] == "job-copied":
            done[r["job"]] = r
        elif r["status"] in ("source-deleted", "source-partly-deleted"):
            done.pop(r["job"], None)
    for j in plan["jobs"]:
        job, src = j["src"], Path(j["src"])
        if not src.exists() and not src.is_symlink():
            print("MISSING", job, flush=True)
            continue
        if job in done and same_source(src, done[job]):
            continue
        attempt = secrets.token_hex(8)
        try:
            root.check()
            record(root.manifests, {"job": job, "status": "job-start", "attempt": attempt})
            users = in_use(src)
            if users:
                raise IOError(f"in use: {users[:2]}")
            inv = inventory(src)
            top = _entry(src, os.lstat(src))  # the item itself: a folder's mode and inode are not in inv
            xmap = xattr_map(src, inv)
            dest = root.path.joinpath(*[safe_name(p) for p in Path(j["dest"]).parts])
            if j["mode"] == "copy":
                copy_job(job, src, dest, root, inv, root.manifests, attempt)
            else:
                pack_job(job, src, dest, root, inv, root.manifests, comp={"tgz": "gz", "tzst": "zst", "tar": None}[j["mode"]], attempt=attempt)
            if inventory(src) != inv or _entry(src, os.lstat(src)) != top:
                raise IOError("source changed during the job")
            root.check()
            record(root.manifests, {"job": job, "attempt": attempt, "status": "job-copied", "inventory": inv, "top": top, "xattrs": xmap})
            print("OK", root.label, job, flush=True)
        except DriveGone as e:
            print("STOP", e, flush=True)
            return False
        except Exception as e:
            try:
                root.check()
            except DriveGone as gone:
                print("STOP", gone, "(during", job, ")", flush=True)
                return False
            record(root.manifests, {"job": job, "attempt": attempt, "status": "failed", "error": str(e)})
            print("FAILED", root.label, job, e, flush=True)
    return True

# ---------- phase 2: re-verify (after unmount and mount)

def attempts(recs):
    """job -> (its latest job-copied record, the verified records of the attempt that wrote it).

    Records carry the id of their attempt. Older manifests have none; there an attempt is
    everything since the job's previous job-copied or failed record, the latest per source.
    """
    open_, out = {}, {}
    for r in recs:
        key, st = r.get("attempt") or ("legacy", r["job"]), r["status"]
        if st == "job-start":
            open_[key] = {}
        elif st in VERIFIED:
            open_.setdefault(key, {})[r["src"]] = r
        elif st in ("job-copied", "failed"):
            rs = open_.pop(key, {})
            if st == "job-copied":
                out[r["job"]] = (r, list(rs.values()))
    return out

def dest_path(root, r):
    return root.path / r["rel"] if r.get("rel") else Path(r["dest"])

def run_reverify_phase(root, jobs=None):
    """Re-hash destinations (only those of `jobs` when given) after the drive was remounted.

    Returns dest -> passed, for the latest attempt of each job; a missing destination fails."""
    root.check()
    latest = attempts(read_manifest(root.manifests[0]))
    checked = {}
    for r in [r for job, (_copied, rs) in latest.items() if jobs is None or job in jobs for r in rs]:
        try:
            ok = hash_nocache(dest_path(root, r)) == r["sha256"]
        except OSError:
            root.check()
            ok = False
        checked[r["dest"]] = checked.get(r["dest"], True) and ok
        record(root.manifests, {"job": r["job"], "dest": r["dest"], "status": "reverified" if ok else "reverify-failed"})
    print("reverify done", root.label, flush=True)
    return checked

def cleanup_appledouble(root_path):
    """Remove only ._ files macOS generated for files this tool wrote (see external-drives.md)."""
    logs = Path(root_path) / "Transfer-Logs"
    with open(logs / "appledouble-before.json", encoding="utf-8") as f:
        before = {os.path.normpath(p) for p in json.load(f)}
    recs = read_manifest(logs / "manifest.jsonl")
    dests = {os.path.normpath(r["dest"]) for r in recs if r.get("dest")}
    written = {os.path.normpath(r["dest"]) for r in recs if r["status"] in ("verified", "archive-verified")}
    removed = 0
    for d, _s, fs in os.walk(root_path):
        for n in fs:
            p = os.path.normpath(os.path.join(d, n))
            if not n.startswith("._") or p in before or p in dests or os.path.join(d, n[2:]) not in written:
                continue
            if not stat.S_ISREG(os.lstat(p).st_mode):
                continue
            fd = os.open(p, os.O_RDONLY | os.O_NOFOLLOW)
            try:
                magic = os.read(fd, 4)
            finally:
                os.close(fd)
            if magic == b"\x00\x05\x16\x07":
                os.unlink(p); removed += 1
    return removed

# ---------- phase 3: delete

def source_hashes(latest):
    out = {}
    for _copied, rs in latest.values():
        for r in rs:
            if r["status"] == "archive-verified":
                parent = Path(r["job"]).parent
                for arc, sha in r["files"].items():
                    out[str(parent / arc)] = sha
            else:
                out[r["src"]] = r["sha256"]
    return out

def why_keep(src, inv, hashes_list, xmaps, tops):
    if inventory(src) != inv:
        return "source changed since it was copied"
    if any(t is not None and _entry(src, os.lstat(src)) != t for t in tops):  # None: legacy record
        return "the item itself (permissions or identity) changed since it was copied"
    if any(xattr_map(src, inv) != x for x in xmaps):
        return "extended attributes changed since it was copied"
    for rel, e in inv.items():
        if e[0] == "f":
            p = src if rel == "." else src / rel
            h = hash_file(p)
            for hashes in hashes_list:
                if hashes.get(str(p)) != h:
                    return f"content differs from a verified copy: {p}"
    return None

def _remove(p, is_dir, inside_job):
    rm = os.rmdir if is_dir else os.unlink
    try:
        rm(p)
    except PermissionError:
        os.chflags(p, 0, follow_symlinks=False)
        if inside_job:
            os.chmod(os.path.dirname(p), 0o700)
        rm(p)

def _still_verified(p, recorded, hashes):
    now = _entry(p, os.lstat(p))
    if now == list(recorded):
        return True
    same_but_ctime = now[:4] + now[5:] == list(recorded[:4]) + list(recorded[5:])
    return same_but_ctime and now[0] == "f" and hash_file(p) == hashes.get(str(p))

def remove_recorded(src, inv, hashes):
    if "." in inv:
        items = [(".", src)]
    else:
        deepest_first = sorted(inv, key=lambda r: len(Path(r).parts), reverse=True)
        items = [(rel, src / rel) for rel in deepest_first] + [(None, src)]
    left = []
    for rel, p in items:
        try:
            if rel is None or inv[rel][0] == "d":
                _remove(p, True, rel is not None)
            elif not _still_verified(p, inv[rel], hashes):
                left.append(f"{rel}: changed")
            else:
                _remove(p, False, rel != ".")
        except OSError as e:
            left.append(f"{rel or '.'}: {e.strerror}")
    return left

def job_state(recs, checked=None):
    """job -> (inventory of the latest job-copied, every destination of that attempt passed re-verification).

    With `checked` (dest -> passed, from a re-verification done in this run) only that one counts."""
    if checked is None:
        passed = {r["dest"] for r in recs if r["status"] == "reverified"}
        failed = {r["dest"] for r in recs if r["status"] == "reverify-failed"}
    else:
        passed = {d for d, ok in checked.items() if ok}
        failed = set(checked) - passed
    inv, ok = {}, {}
    for job, (copied, rs) in attempts(recs).items():
        d = {r["dest"] for r in rs}
        inv[job], ok[job] = copied["inventory"], bool(d) and d <= passed and not (d & failed)
    return inv, ok

def run_delete_phase(plan, roots, checked=None):
    """Delete sources whose copies passed a re-verification of this run: `checked` (one dest -> passed
    per root, from re-verifying after a remount), or else a re-verification done here."""
    for root in roots:
        root.check()
    if checked is None:
        present = {j["src"] for j in plan["jobs"] if os.path.lexists(j["src"])}
        checked = [run_reverify_phase(root, present) for root in roots]
    recs_list = [read_manifest(r.manifests[0]) for r in roots]
    states = [job_state(recs, c) for recs, c in zip(recs_list, checked)]
    latest_list = [attempts(recs) for recs in recs_list]
    hashes_list = [source_hashes(latest) for latest in latest_list]
    all_m = [m for r in roots for m in r.manifests]
    for j in plan["jobs"]:
        job, src = j["src"], Path(j["src"])
        if not src.exists() and not src.is_symlink():
            continue
        reason = None
        for root, (inv, ok) in zip(roots, states):
            if job not in inv:
                reason = f"no completed copy on {root.label}"
            elif not ok.get(job):
                reason = f"not every destination on {root.label} passed re-verification"
            if reason:
                break
        invs = [s[0].get(job) for s in states]
        if reason is None and any(i != invs[0] for i in invs):
            reason = "the copies were made from different source states"
        if reason is None:
            reason = why_keep(src, invs[0], hashes_list, [latest[job][0].get("xattrs", {}) for latest in latest_list],
                              [latest[job][0].get("top") for latest in latest_list])
        if reason is None:
            left = remove_recorded(src, invs[0], hashes_list[0])
            record(all_m, {"job": job, "status": "source-partly-deleted" if left else "source-deleted", "left": left})
            print("DELETED" if not left else "LEFT", job, left[:5], flush=True)
            continue
        record(all_m, {"job": job, "status": "source-kept", "reason": reason})
        print("KEPT", job, reason, flush=True)

def status(plan, roots):
    for root in roots:
        recs = read_manifest(root.manifests[0])
        inv, ok = job_state(recs)
        failed = [r["job"] for r in recs if r["status"] == "failed"]
        print(f"{root.label}: {len(inv)}/{len(plan['jobs'])} jobs copied, {sum(ok.values())} fully re-verified, {len(failed)} failure records")

def main():
    plan_path, phase = sys.argv[1], sys.argv[2]
    plan = json.load(open(plan_path))
    roots = [Root(r) for r in plan["roots"]]
    only = sys.argv[3] if len(sys.argv) > 3 else None
    if phase == "copy":
        for root in roots:
            if only and root.label != only:
                continue
            if not run_copy_phase(plan, root):
                sys.exit(2)
    elif phase == "reverify":
        for root in roots:
            if not only or root.label == only:
                run_reverify_phase(root)
    elif phase == "delete":
        run_delete_phase(plan, roots)
    elif phase == "status":
        status(plan, roots)
    else:
        sys.exit("phase must be copy, reverify, delete or status")

if __name__ == "__main__":
    main()
