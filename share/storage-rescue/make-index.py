#!/usr/bin/env python3
"""Write ~/.agents/ARCHIVE.md (and INDEX.md on each mounted archive drive) from the manifests."""
import os, sys, time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import offload  # noqa: E402

LOCAL = Path.home() / ".agents" / "archive"
DIRNAME = os.environ.get("STORAGE_ARCHIVE_DIRNAME", "Mac-Archive")  # override only for tests
DRIVES = {"Dev": f"/Volumes/Dev/{DIRNAME}", "TOSHIBA-L": f"/Volumes/TOSHIBA L/{DIRNAME}"}
OK = ("verified", "identical-already-present-verified", "archive-verified")


def jobs():
    out = {}
    for label in DRIVES:
        for r in offload.read_manifest(LOCAL / f"{label}-manifest.jsonl"):
            j = out.setdefault(r["job"], {"size": {}, "copies": set(), "state": "copied", "when": ""})
            if r["status"] in OK:
                j["size"][label] = j["size"].get(label, 0) + r.get("source_bytes", r["size"])
                j["copies"].add(label)
            elif r["status"] == "source-deleted":
                j["state"], j["when"] = "moved off the Mac", r.get("at", "")[:10]
            elif r["status"] == "source-partly-deleted":
                j["state"], j["when"] = "partly moved (some files stayed)", r.get("at", "")[:10]
            elif r["status"] == "source-kept":
                j["state"] = "still on the Mac (copy kept as backup)"
    return out


def render():
    home = os.path.realpath(Path.home())
    rows = []
    for job, j in sorted(jobs().items()):
        size = max(j["size"].values()) if j["size"] else 0
        rows.append(f"| `{job.replace(home, '~')}` | {size / 1e6:,.1f} MB | {j['state']} {j['when']} | {', '.join(sorted(j['copies']))} |")
    return "\n".join([
        "# Archived files",
        "",
        "Some files and folders were moved from this Mac to the external Toshiba drive",
        "(APFS volume `Dev`, folder `Mac-Archive`; second copy on exFAT volume `TOSHIBA L`, folder `Mac-Archive`).",
        "",
        "- If something listed here is missing on the Mac, it was archived on purpose. Do not recreate it.",
        "- Restore: `storage-restore <original path>` (also works for a parent folder). It never overwrites.",
        "- List: `storage-restore --list [path]`.",
        "- If the drive is not connected, ask the user to connect it. Do not unplug or replug it during a copy.",
        "- Source of truth: `~/.agents/archive/*-manifest.jsonl` (paths, SHA-256, sizes).",
        "",
        f"Generated {time.strftime('%Y-%m-%d %H:%M')}.",
        "",
        "| Original path | Size | State | Copies |",
        "|---|---|---|---|",
        *rows,
        "",
    ])


def write(path, text):
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text, encoding="utf-8")
    os.replace(tmp, path)


if __name__ == "__main__":
    text = render()
    write(Path.home() / ".agents" / "ARCHIVE.md", text)
    for root in DRIVES.values():
        if os.path.isdir(root):
            write(Path(root) / "INDEX.md", text)
    print(text.count("\n| `"), "entries written")
