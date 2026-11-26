#!/usr/bin/env python3
"""Verify every Bug Hunt puzzle before it can be published.

A puzzle passes only if ALL checks pass:
  1. Metadata: puzzle.json has the required fields and answer lines exist.
  2. Diff: the fixed contract differs from the vulnerable one ONLY on the answer
     lines (plus the contract name), so the answer is exactly what fixes the bug.
  3. Tests: `forge test` for the puzzle passes. Each puzzle's test suite must prove
     that the exploit WORKS on the vulnerable version, FAILS on the fixed version,
     and that normal behaviour works on BOTH.
  4. Slither: the fixed version has no high/medium findings, and every high/medium
     finding on the vulnerable version sits on an answer line (no second bug).

Usage: python3 scripts/verify.py [puzzle_dir ...]   (default: all puzzles)
Env: SOLC=/path/to/solc to use a local compiler binary.
"""
import difflib, json, os, re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REQUIRED = ["id", "title", "difficulty", "file", "fixed", "answer_lines", "bug_class", "hint", "explanation"]
SOLC = os.environ.get("SOLC")


def fail(p, msg):
    print(f"  FAIL [{p.name}] {msg}")
    return False


def strip_name(lines):
    # The contract name legitimately differs (Vault vs VaultFixed), and doc-comment
    # header lines (///) may differ (the fixed file says it is the reference fix).
    out = []
    for l in lines:
        l = re.sub(r"^(\s*contract\s+)\w+", r"\1X", l)
        out.append("///" if l.lstrip().startswith("///") else l)
    return out


def check_meta(p, meta):
    missing = [k for k in REQUIRED if k not in meta]
    if missing:
        return fail(p, f"puzzle.json missing {missing}")
    src = (p / meta["file"]).read_text().splitlines()
    if not meta["answer_lines"] or any(not 1 <= n <= len(src) for n in meta["answer_lines"]):
        return fail(p, "answer_lines out of range")
    if any(not src[n - 1].strip() for n in meta["answer_lines"]):
        return fail(p, "an answer line is blank")
    return True


def check_diff(p, meta):
    a = strip_name((p / meta["file"]).read_text().splitlines())
    b = strip_name((p / meta["fixed"]).read_text().splitlines())
    ans = set(meta["answer_lines"])
    # Declared, justified additions (e.g. a new state variable or a pull-payment function the
    # fix needs) may be inserted after the listed vulnerable lines. Each needs a reason.
    extra = {}
    for add in meta.get("fix_additions", []):
        if not add.get("reason"):
            return fail(p, "every fix_additions entry needs a reason")
        extra[add["after_line"]] = add["reason"]
    sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
    touched = False
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        touched = True
        if tag in ("replace", "delete"):
            bad = [n for n in range(i1 + 1, i2 + 1) if n not in ans]
            if bad:
                return fail(p, f"fixed version changes non-answer lines {bad}")
        else:  # pure insertion between vulnerable lines i1 and i1+1
            if not ({i1, i1 + 1} & ans) and i1 not in extra:
                return fail(p, f"fixed version inserts code away from the answer (after line {i1})")
    if not touched:
        return fail(p, "fixed version is identical to the vulnerable one")
    return True


def check_tests(p):
    cmd = ["forge", "test", "--match-path", f"puzzles/{p.name}/test/*"]
    if SOLC:
        cmd += ["--use", SOLC]
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    out = r.stdout + r.stderr
    if r.returncode != 0 or "0 failed" not in out:
        print(out[-2000:])
        return fail(p, "forge tests failed")
    names = re.findall(r"\[PASS\] (\w+)", out)
    need = ["exploitWorksOnVulnerable", "exploitFailsOnFixed"]
    if not all(any(n in x for x in names) for n in need) or not any("normal" in x.lower() for x in names):
        return fail(p, "test suite must include exploitWorksOnVulnerable, exploitFailsOnFixed and normal-use tests")
    return True


def slither(path):
    cmd = ["slither", str(path), "--compile-force-framework", "solc", "--json", "-", "--exclude-informational", "--exclude-low", "--exclude-optimization"]
    if SOLC:
        cmd += ["--solc", SOLC]
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    data = json.loads(r.stdout or "{}")
    if not data.get("success"):
        raise RuntimeError(data.get("error") or r.stderr[-1000:])
    found = []
    for d in data.get("results", {}).get("detectors", []):
        lines = set()
        for el in d.get("elements", []):
            sm = el.get("source_mapping", {})
            if Path(sm.get("filename_absolute", "")).resolve() == Path(path).resolve():
                lines.update(sm.get("lines", []))
        found.append((d["check"], d["impact"], lines))
    return found


def check_slither(p, meta):
    try:
        fixed = slither(p / meta["fixed"])
        vuln = slither(p / meta["file"])
    except Exception as e:
        return fail(p, f"slither error: {e}")
    if fixed:
        return fail(p, f"fixed version still has findings: {[(c, i) for c, i, _ in fixed]}")
    ans = set(meta["answer_lines"])
    for check, impact, lines in vuln:
        if not (lines & ans):
            return fail(p, f"possible second bug: {check} ({impact}) on lines {sorted(lines)}")
    return True


def main():
    dirs = [Path(d) for d in sys.argv[1:]] or sorted((ROOT / "puzzles").glob("[0-9][0-9][0-9]-*"))
    ok_all = True
    for p in dirs:
        p = p.resolve()
        meta = json.loads((p / "puzzle.json").read_text())
        ok = check_meta(p, meta) and check_diff(p, meta) and check_tests(p) and check_slither(p, meta)
        print(f"{'PASS' if ok else 'FAIL'} {p.name}: {meta.get('title')}")
        ok_all &= ok
    sys.exit(0 if ok_all else 1)


if __name__ == "__main__":
    main()
