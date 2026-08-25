#!/usr/bin/env python3
"""Commit-boundary adversarial-review gate (replaces the Stop-based review-gate.sh).

Design (agreed with Ale 2026-08-25; hardened after 2 adversarial review rounds):
  - Trigger is the `git commit` boundary. Iterate freely while uncommitted;
    review fires once, at commit, on the STAGED diff.
  - Convergence: a clearance token holds sha256(git diff --cached). The gate
    allows a commit iff the token matches the *current* staged diff, so it
    self-invalidates the moment staged content changes again. The `commit-review`
    skill writes the token via `--clear` as its FINAL act, AFTER all fixes are
    re-staged. That ordering is the convergence guarantee.
  - Token lives in the per-worktree git dir (rev-parse --git-path), so parallel
    Conductor worktrees never cross-validate.
  - Verifiability invariant: we only vouch for a commit whose committed content
    == the hashed staged content, so commits that bundle staging (-a/--all,
    pathspec, chained `git add`) are denied with guidance to stage-then-plain-
    commit. Fail CLOSED throughout: git errors/timeouts -> require review.

Modes:
  (default, reads hook JSON on stdin)  PreToolUse gate for Bash tool calls.
  --clear                              Write the clearance token for the current
                                       staged diff. Run by the skill, last.
"""
import sys, os, json, subprocess, hashlib, re, shlex
from typing import NoReturn

SKILL = "commit-review"
DENY_LIMIT = 3        # consecutive denies on identical hash -> surface to user
GIT_TIMEOUT = 45      # seconds; a timeout is treated as an error -> fail closed

# --- trivial-path filters: a commit touching only these needs no review. ---
TRIVIAL_EXT = re.compile(
    r"\.(md|markdown|mdx|rst|adoc|txt|lock|sum|png|jpg|jpeg|webp|gif|ico|ttf|otf|woff2?)$", re.I)
TRIVIAL_NAME = re.compile(
    r"(^|/)(LICENSE|CHANGELOG|README)[^/]*$"
    r"|(^|/)\.gitignore$"
    r"|(^|/)(package-lock\.json|npm-shrinkwrap\.json|pnpm-lock\.yaml)$", re.I)
TRIVIAL_TEST = re.compile(
    r"(^|/)(tests?|__tests__|spec|specs|fixtures?|testdata|__mocks__|goldens)/"
    r"|_test\.|(^|/)test_|\.test\.|\.spec\.", re.I)
TRIVIAL_CTX = re.compile(r"(^|/)\.context/")

def is_trivial(path):
    return bool(TRIVIAL_EXT.search(path) or TRIVIAL_NAME.search(path)
                or TRIVIAL_TEST.search(path) or TRIVIAL_CTX.search(path))

# ---------------------------------------------------------------------------
# git helpers. Every call reports (rc, stdout); rc != 0 means error/timeout and
# callers MUST fail closed (assume review is needed).
def git(root, *args):
    try:
        p = subprocess.run(["git", "-C", root, *args],
                           capture_output=True, text=True, timeout=GIT_TIMEOUT)
        return p.returncode, p.stdout
    except Exception:
        return 1, ""

def repo_root(cwd):
    """Return the repo top-level path, "" if `cwd` is genuinely not a repo, or
    None if git errored/timed out (unknown -> caller must fail closed)."""
    try:
        p = subprocess.run(["git", "-C", cwd, "rev-parse", "--show-toplevel"],
                           capture_output=True, text=True, timeout=GIT_TIMEOUT)
        return p.stdout.strip() if p.returncode == 0 else ""
    except Exception:
        return None

def git_path(root, name):
    rc, out = git(root, "rev-parse", "--git-path", name)
    if rc != 0 or not out.strip():
        return None
    p = out.strip()
    return p if os.path.isabs(p) else os.path.join(root, p)

def staged_hash(root):
    """sha256 of the full staged diff. None on git error (-> fail closed)."""
    try:
        p = subprocess.run(["git", "-C", root, "diff", "--cached"],
                           capture_output=True, timeout=GIT_TIMEOUT)
        if p.returncode != 0:
            return None
        return hashlib.sha256(p.stdout).hexdigest()
    except Exception:
        return None

def _raw_nontrivial(root, ref_args):
    """Non-trivial, non-submodule paths from `git diff <ref_args> --raw`.
    Returns a list, or None on git error (caller fails closed)."""
    rc, out = git(root, "-c", "core.quotepath=false", "diff", *ref_args, "--raw")
    if rc != 0:
        return None
    paths = []
    for line in out.splitlines():
        if not line.startswith(":"):
            continue
        meta, _, pathpart = line.partition("\t")
        fields = meta[1:].split()
        if len(fields) < 2:
            continue
        if fields[1] == "160000":          # submodule gitlink bump -> ignore
            continue
        path = pathpart.split("\t")[-1]    # rename/copy: take the new path
        if path and not is_trivial(path):
            paths.append(path)
    return paths

def nontrivial_staged(root):
    return _raw_nontrivial(root, ["--cached"])

def any_nontrivial_worktree(root):
    """True if the working tree has ANY non-trivial change (staged/unstaged/
    untracked). True on git error (fail closed)."""
    rc, out = git(root, "-c", "core.quotepath=false", "status", "--porcelain")
    if rc != 0:
        return True
    for line in out.splitlines():
        path = line[3:] if len(line) > 3 else ""
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        path = path.strip().strip('"')
        if path and not is_trivial(path):
            return True
    return False

# ---------------------------------------------------------------------------
# shell parsing. Target is an honest agent following instructions, not an
# evader -- quote-aware "good enough" parsing, fail closed on ambiguity.
def split_segments(cmd):
    """Quote-aware split into pipeline/list segments on && || ; | and newline."""
    segs, buf, i, n = [], [], 0, len(cmd)
    quote = None
    while i < n:
        c = cmd[i]
        if quote:
            buf.append(c)
            if c == "\\" and quote == '"' and i + 1 < n:
                buf.append(cmd[i + 1]); i += 2; continue
            if c == quote:
                quote = None
            i += 1; continue
        if c in ("'", '"'):
            quote = c; buf.append(c); i += 1; continue
        if c == "\\" and i + 1 < n:
            buf.append(c); buf.append(cmd[i + 1]); i += 2; continue
        if cmd[i:i+2] in ("&&", "||"):
            segs.append("".join(buf)); buf = []; i += 2; continue
        if c in (";", "|", "\n"):
            segs.append("".join(buf)); buf = []; i += 1; continue
        buf.append(c); i += 1
    segs.append("".join(buf))
    return [s.strip() for s in segs if s.strip()]

def tokenize(seg):
    try:
        return shlex.split(seg, posix=True)
    except ValueError:
        return seg.split()

WRAPPERS = {"command", "env", "nice", "time", "sudo", "builtin", "exec", "then",
            "do", "!"}
GLOBAL_VALUE = {"--git-dir", "--work-tree", "--namespace", "-c", "--exec-path",
                "--config-env"}
COMMIT_VALUE_LONG = {"--message", "--file", "--author", "--date",
                     "--reuse-message", "--reedit-message", "--fixup",
                     "--squash", "--template"}
COMMIT_VALUE_SHORT = {"-m", "-F", "-C", "-c", "-U", "-t"}
# git subcommands that are definitely not a commit (skip alias resolution).
KNOWN_NONCOMMIT = {
    "status", "add", "stage", "diff", "log", "show", "rev-parse", "config",
    "remote", "fetch", "pull", "push", "clone", "init", "branch", "checkout",
    "switch", "restore", "reset", "stash", "tag", "merge", "rebase",
    "cherry-pick", "revert", "mv", "rm", "ls-files", "ls-tree", "cat-file",
    "blame", "bisect", "reflog", "worktree", "submodule", "describe",
    "shortlog", "grep", "clean", "apply", "format-patch", "am", "send-email",
    "gc", "fsck", "notes", "archive", "cherry", "range-diff", "symbolic-ref",
    "update-index", "update-ref", "for-each-ref", "check-ignore", "check-attr",
    "hash-object", "count-objects", "prune", "repack", "help", "version",
    "whatchanged", "verify-commit", "annotate",
}

def strip_leading(toks):
    """Drop leading env-assignments, wrapper commands, and their flags so we see
    the real command (e.g. `sudo -n git ...`, `env -i FOO=1 git ...`)."""
    out = list(toks)
    while out:
        t = out[0]
        if (re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t) or t in WRAPPERS
                or (t.startswith("-") and len(t) > 1)):
            out = out[1:]
        else:
            break
    return out

def scan_commit_args(rest):
    dry = amend = stages = pathspec = False
    saw_dd = False
    k = 0
    while k < len(rest):
        t = rest[k]
        if saw_dd:
            pathspec = True; k += 1; continue
        if t == "--":
            saw_dd = True; k += 1; continue
        if not t:
            k += 1; continue
        if t[0] in "<>":            # redirection operator/target -> not a pathspec
            k += 1; continue
        if t.startswith("--"):
            opt = t.split("=", 1)[0]
            if opt == "--dry-run": dry = True
            elif opt == "--amend": amend = True
            elif opt == "--all": stages = True
            elif opt in ("--include", "--only"): pathspec = True
            elif opt in COMMIT_VALUE_LONG and "=" not in t:
                k += 2; continue
            k += 1; continue
        if t.startswith("-") and len(t) > 1:
            cluster = t[1:]
            if "a" in cluster:
                stages = True
            if ("-" + cluster[-1]) in COMMIT_VALUE_SHORT:
                k += 2; continue     # trailing value-opt consumes next token
            k += 1; continue
        pathspec = True; k += 1      # bare token = pathspec
    return {"dry_run": dry, "amend": amend, "stages": stages, "has_pathspec": pathspec}

class Aliases:
    """Lazily resolve git aliases, cached PER directory — a repo-local alias only
    exists in the repo the commit actually targets (reached via cd/-C), not the
    session cwd. One `git config` call per distinct repo, only when needed."""
    def __init__(self):
        self.cache = {}
    def get(self, dirpath, name):
        root = repo_root(dirpath)
        key = root if root else dirpath
        if key not in self.cache:
            m = {}
            rc, out = git(key, "config", "--get-regexp", r"^alias\.")
            if rc == 0:
                for line in out.splitlines():
                    k, _, val = line.partition(" ")
                    nm = k[len("alias."):]
                    try:
                        toks = shlex.split(val)
                    except ValueError:
                        toks = val.split()
                    if toks:
                        m[nm] = toks
            self.cache[key] = m
        return self.cache[key].get(name)

def classify_git_segment(toks, cur, aliases):
    """Return (kind, info, cdir):
       kind is None (not a relevant git command), 'add' (stages), or 'commit'.
       info is the scan_commit_args dict for a commit; cdir is a `-C <dir>` value."""
    if not toks or os.path.basename(toks[0]).lower() != "git":
        return None, None, None
    j, cdir = 1, None
    while j < len(toks):
        t = toks[j]
        if t == "-C" and j + 1 < len(toks):
            cdir = toks[j + 1]; j += 2; continue
        if t.startswith("--git-dir="):
            j += 1; continue
        if t in GLOBAL_VALUE and j + 1 < len(toks):
            j += 2; continue
        if t.startswith("-"):
            j += 1; continue
        break
    if j >= len(toks):
        return None, None, None
    sub = toks[j]
    if sub in ("add", "stage"):
        return "add", None, None
    baked = []
    if sub != "commit":
        if sub in KNOWN_NONCOMMIT:
            return None, None, None
        target = cur
        if cdir:
            target = cdir if os.path.isabs(cdir) \
                else os.path.normpath(os.path.join(cur, cdir))
        exp = aliases.get(target, sub)      # resolve against the commit's repo
        if not exp or exp[0] != "commit":
            return None, None, None
        baked = exp[1:]                     # e.g. alias.ca = "commit -a"
    return "commit", scan_commit_args(baked + toks[j + 1:]), cdir

def analyze(cmd, base_dir, aliases):
    """Return list of commit occurrences: {info, dir, staged_before}."""
    cur = base_dir
    staged_before = False
    commits = []
    for seg in split_segments(cmd):
        toks = strip_leading(tokenize(seg))
        if not toks:
            continue
        if os.path.basename(toks[0]).lower() == "cd":
            args = [t for t in toks[1:] if not t.startswith("-")]
            if args:
                cur = args[0] if os.path.isabs(args[0]) \
                    else os.path.normpath(os.path.join(cur, args[0]))
            else:
                cur = os.path.expanduser("~")
            continue
        kind, info, cdir = classify_git_segment(toks, cur, aliases)
        if kind == "add":
            staged_before = True
        elif kind == "commit":
            gdir = cur
            if cdir:
                gdir = cdir if os.path.isabs(cdir) \
                    else os.path.normpath(os.path.join(cur, cdir))
            commits.append({"info": info, "dir": gdir, "staged_before": staged_before})
    return commits

# ---------------------------------------------------------------------------
def read_state(path):
    try:
        with open(path) as f:
            h, n = f.read().split()
            return h, int(n)
    except Exception:
        return None, 0

def write_state(path, h, n):
    try:
        with open(path, "w") as f:
            f.write(f"{h} {n}")
    except Exception:
        pass

def clear_state(path):
    try:
        if path:
            os.remove(path)
    except Exception:
        pass

def deny(reason) -> NoReturn:
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }}))
    sys.exit(0)

def allow() -> NoReturn:
    sys.exit(0)

def deny_with_backstop(root, h, bundled) -> NoReturn:
    state_path = git_path(root, "review-commit-denies")
    prev_h, prev_n = read_state(state_path) if state_path else (None, 0)
    n = prev_n + 1 if prev_h == h else 1
    if state_path:
        write_state(state_path, h or "?", n)
    if n >= DENY_LIMIT:
        deny(
            f"Commit-review gate: blocked {n}x on the same pending change without "
            f"a clearance token. STOP retrying the commit. Likely the `{SKILL}` "
            f"skill did not run `commit-review-gate.py --clear` as its final, "
            f"SEPARATE step, or content changed between clear and commit. Surface "
            f"this to the user and ask how to proceed rather than looping."
        )
    if bundled:
        deny(
            f"Commit-review gate: this commit bundles staging (-a/--all, a "
            f"pathspec, or a chained `git add`), so the gate cannot verify that "
            f"what you commit equals what was reviewed. Stage the final content "
            f"first (the `{SKILL}` skill does this), then run a PLAIN `git commit` "
            f"(message flags only: no -a, no pathspec, no chained add)."
        )
    deny(
        f"Commit-review gate: the staged diff is unreviewed. Invoke the `{SKILL}` "
        f"skill — it runs >=2 adversarial reviewers in parallel on the staged "
        f"diff, routes accepted findings to a separate fix agent, does a "
        f"confirm-only pass, writes the ledger, then clears this gate as its final "
        f"SEPARATE step. Then retry a plain `git commit`. Do not bypass."
    )

# ---------------------------------------------------------------------------
def do_clear() -> NoReturn:
    root = repo_root(os.getcwd())
    if not root:
        print("commit-review-gate: not inside a git repo", file=sys.stderr)
        sys.exit(1)
    h = staged_hash(root)
    if h is None:
        print("commit-review-gate: could not read staged diff", file=sys.stderr)
        sys.exit(1)
    tok = git_path(root, "review-commit-cleared")
    if not tok:
        print("commit-review-gate: could not resolve token path", file=sys.stderr)
        sys.exit(1)
    with open(tok, "w") as f:
        f.write(h)
    clear_state(git_path(root, "review-commit-denies"))
    print(f"commit-review gate cleared for staged diff {h[:12]}")
    sys.exit(0)

def do_gate() -> NoReturn:
    try:
        data = json.load(sys.stdin)
        assert isinstance(data, dict)
    except Exception:
        allow()                       # unparseable hook input -> don't block
    if data.get("tool_name") != "Bash":
        allow()
    ti = data.get("tool_input")
    cmd = ti.get("command", "") if isinstance(ti, dict) else ""
    if not cmd:
        allow()

    base_dir = data.get("cwd") or os.getcwd()
    aliases = Aliases()
    commits = analyze(cmd, base_dir, aliases)
    real = [c for c in commits if not c["info"]["dry_run"]]
    if not real:
        allow()                       # no real git commit (cheap path, no git I/O)
    if len(real) >= 2:
        deny(
            "Commit-review gate: this command contains more than one git commit. "
            "Run each commit as a SEPARATE Bash tool call so the gate can verify "
            "each one against its own review."
        )

    c = real[0]
    root = repo_root(c["dir"])
    if root is None:                  # git errored/timed out -> can't verify
        deny(
            "Commit-review gate: could not resolve the git repository (git errored "
            "or timed out), so review can't be verified. Retry; if it persists, "
            "surface to the user rather than bypassing."
        )
    if not root:
        allow()                       # "" = genuinely not a repo; git will error
    info, staged_before = c["info"], c["staged_before"]

    rc, _ = git(root, "diff", "--cached", "--quiet")
    staged_empty = (rc == 0)
    if info["amend"] and staged_empty:
        allow()                       # reword-only amend -> nothing new to review

    if info["stages"] or info["has_pathspec"] or staged_before:
        # index doesn't represent what a -a/pathspec/chained-add commit writes.
        if info["stages"] and not info["has_pathspec"] and not staged_before:
            # `-a` commits all TRACKED changes = staged ∪ unstaged-tracked.
            # (Avoid `git diff HEAD`, which errors on an unborn HEAD.)
            staged_p = _raw_nontrivial(root, ["--cached"])
            unstaged_p = _raw_nontrivial(root, [])
            if staged_p is None or unstaged_p is None:
                has_nontrivial = True                 # git error -> fail closed
            else:
                has_nontrivial = bool(staged_p or unstaged_p)
        else:
            has_nontrivial = any_nontrivial_worktree(root)
        if not has_nontrivial:
            allow()
        deny_with_backstop(root, staged_hash(root) or "?", bundled=True)

    nts = nontrivial_staged(root)
    if nts is not None and not nts:
        allow()                       # nothing non-trivial staged (pure git)

    h = staged_hash(root)
    tok = git_path(root, "review-commit-cleared")
    token_val = None
    if tok and os.path.exists(tok):
        try:
            with open(tok) as f:
                token_val = f.read().strip()
        except Exception:
            token_val = None

    if h is not None and token_val == h:
        clear_state(git_path(root, "review-commit-denies"))
        allow()

    deny_with_backstop(root, h or "?", bundled=False)

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--clear":
        do_clear()
    else:
        do_gate()
