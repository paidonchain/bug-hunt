#!/usr/bin/env python3
"""Build the Daily Bug Hunt static site into _site/.

Only puzzles released up to today (UTC) are included, so unreleased puzzles and
their answers never reach the public site. Puzzle N is released on START + (N-1) days.
Answers are stored as salted SHA-256 hashes so the answer isn't readable at a glance.
"""
import datetime as dt, hashlib, json, os, shutil, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
START = dt.date.fromisoformat(os.environ.get("BUGHUNT_START", "2026-11-26"))
REPO = "https://github.com/paidonchain/bug-hunt"


def released(today):
    n = (today - START).days + 1
    out = []
    for p in sorted((ROOT / "puzzles").glob("[0-9][0-9][0-9]-*")):
        m = json.loads((p / "puzzle.json").read_text())
        if m["id"] > n:
            continue
        code = (p / m["file"]).read_text()
        salt = hashlib.sha256(f"bughunt-{m['id']}".encode()).hexdigest()[:16]
        out.append({
            "id": m["id"], "title": m["title"], "difficulty": m["difficulty"],
            "date": (START + dt.timedelta(days=m["id"] - 1)).isoformat(),
            "code": code, "salt": salt,
            "answers": [hashlib.sha256(f"{salt}:{l}".encode()).hexdigest() for l in m["answer_lines"]],
            "hint": m["hint"], "bug_class": m["bug_class"], "explanation": m["explanation"],
            "proof": f"{REPO}/tree/main/puzzles/{p.name}",
        })
    return out


def main():
    today = dt.date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else dt.datetime.now(dt.timezone.utc).date()
    puzzles = released(today)
    site = ROOT / "_site"
    shutil.rmtree(site, ignore_errors=True)
    site.mkdir()
    html = (ROOT / "site" / "index.html").read_text()
    data = json.dumps({"start": START.isoformat(), "puzzles": puzzles}, separators=(",", ":"))
    (site / "index.html").write_text(html.replace("/*__DATA__*/null", data.replace("</", "<\\/")))
    (site / ".nojekyll").write_text("")
    print(f"built {len(puzzles)} released puzzle(s) for {today}")


if __name__ == "__main__":
    main()
