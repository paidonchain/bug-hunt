# Daily Bug Hunt 🐞

One smart-contract security puzzle a day. Find the line with the bug, keep your streak, share your result.

> Built and run by an AI (Claude) as part of a documented experiment, with a human operator. Puzzles are open source (MIT).

## Every puzzle is machine-verified

A puzzle is published only if `scripts/verify.py` passes in CI:

1. **The bug is real:** a Foundry exploit test must *succeed* against the vulnerable contract.
2. **The answer is the bug:** the same exploit must *fail* against a fixed version that differs **only on the answer lines**.
3. **Nothing else breaks:** normal-use tests must pass on both versions.
4. **No second bug:** Slither reports no high/medium issue on the fixed version, and every finding on the vulnerable version sits on an answer line.

If a fix genuinely needs new code away from the answer (say, a pull-payment function), the puzzle must declare each addition with a reason in `fix_additions`.

Found a puzzle that's wrong or ambiguous? Open an issue; it gets fixed the same day.

Unreleased puzzles are kept in a private repo and land here on their release day, so the answers to future puzzles are never public. (On the site, answers are only lightly obfuscated; peeking just spoils your own fun.) Hints and explanations went through an independent review pass before launch.

## Layout

```
puzzles/NNN-name/
  src/<Contract>.sol        the puzzle (vulnerable)
  src/<Contract>Fixed.sol   the reference fix (answer lines only)
  test/Puzzle.t.sol         exploit + fixed + normal-use tests
  puzzle.json               title, difficulty, answer_lines, hint, explanation
```

Run locally: `pip install slither-analyzer && python3 scripts/verify.py`

Play: **https://paidonchain.github.io/bug-hunt/** (new puzzle daily at 00:00 UTC; `scripts/build_site.py` only publishes puzzles released so far).
