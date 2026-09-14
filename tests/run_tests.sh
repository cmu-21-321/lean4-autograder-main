#!/usr/bin/env bash

# End-to-end test suite for the autograder.
#
# `lake build` only builds the `autograder` executable: it does not build the
# `comparator`/`lean4export` binaries that grading actually shells out to, and it
# never runs a grading pass. So a toolchain bump can leave `lake build` green
# while grading is broken. This script closes that gap by building everything the
# autograder needs at runtime and then grading three fixture submissions,
# comparing the verdicts against `tests/expected/`.
#
# Usage: tests/run_tests.sh        (from the repository root)
#
# Notes on `landrun`: when no `landrun` binary is available, `--local` mode falls
# back to Comparator's `scripts/fake-landrun.sh` dev shim, which provides no
# sandboxing. That is fine here -- the fixtures are trusted -- but it does mean
# this suite does not exercise the sandbox itself.

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
REPO="$PWD"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
info() { echo "==> $*"; }

# ---------------------------------------------------------------------------
# 0. The pinned dependencies must be built against the same toolchain we are.
# ---------------------------------------------------------------------------
info "Checking that dependencies are pinned to our toolchain"
toolchain="$(tr -d '[:space:]' < lean-toolchain)"
for dep in comparator lean4export; do
  dep_toolchain_file=".lake/packages/$dep/lean-toolchain"
  if [[ ! -f "$dep_toolchain_file" ]]; then
    fail "$dep is not checked out; run \`lake update\` first"
    continue
  fi
  dep_toolchain="$(tr -d '[:space:]' < "$dep_toolchain_file")"
  if [[ "$dep_toolchain" != "$toolchain" ]]; then
    fail "$dep is pinned to $dep_toolchain but this project uses $toolchain.
      Bump the \`require comparator ... @ \"<tag>\"\` line in lakefile.lean to the
      matching tag and re-run \`lake update comparator\`."
  fi
done

# ---------------------------------------------------------------------------
# 1. Build everything grading needs, not just the default target.
# ---------------------------------------------------------------------------
info "Building autograder, comparator and lean4export"
if ! lake build autograder comparator lean4export; then
  fail "lake build of the autograder and its runtime dependencies failed"
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Put the sheet where the autograder expects to find it.
#
# At grading time this package lives at `.lake/packages/autograder`, and
# `Main.lean` addresses the sheet and the generated `ComparatorGrading` scratch
# library through that prefix. When testing the autograder *inside its own
# repository* that path does not exist, so point it back at ourselves.
# ---------------------------------------------------------------------------
mkdir -p .lake/packages
if [[ ! -e .lake/packages/autograder ]]; then
  ln -s ../.. .lake/packages/autograder
fi
mkdir -p AutograderTests
cp tests/Sheet.lean AutograderTests/Solution.lean

# Extracts `name<TAB>status<TAB>points` from a `--local` grading report.
extract_results() {
  awk '
    /^[A-Za-z_][A-Za-z0-9_.!?'"'"']*:$/ { name = substr($0, 1, length($0) - 1); next }
    name != "" && /^  (passed|failed) \(/ {
      status = $1
      points = $2
      sub(/^\(/, "", points)
      print name "\t" status "\t" points
      name = ""
    }
  ' | LC_ALL=C sort
}

run_local_case() {
  local label="$1" submission="$2" expected="$3"
  info "Grading tests/$submission ($label)"
  local log="$REPO/.lake/test-$label.log"
  if ! lake exe autograder --local "tests/$submission" AutograderTests/Solution.lean > "$log" 2>&1; then
    fail "grading tests/$submission exited non-zero; full output in $log"
    tail -40 "$log" >&2
    return
  fi
  local actual
  actual="$(extract_results < "$log")"
  if ! diff -u "tests/expected/$expected" <(printf '%s\n' "$actual"); then
    fail "grading verdicts for tests/$submission do not match tests/expected/$expected (full output in $log)"
  fi
}

# ---------------------------------------------------------------------------
# 3. A fully correct submission must get full marks...
# ---------------------------------------------------------------------------
run_local_case good Good.lean good.txt

# ---------------------------------------------------------------------------
# 4. ...and a wrong one must be rejected, exercise by exercise.
# ---------------------------------------------------------------------------
run_local_case bad Bad.lean bad.txt

# ---------------------------------------------------------------------------
# 5. The `validTactics` text must reach the generated pin theorem verbatim.
#
# `syntaxSourceText` recovers it from the sheet's source by position rather than
# by pretty-printing, which does not reliably round-trip; this catches a
# regression in that recovery even when the resulting proof would fail anyway.
# ---------------------------------------------------------------------------
info "Checking that configured tactics are spliced into the pin theorems"
if ! grep -qF -- '| (simp [dbl2])' ComparatorGrading/Pin*.lean; then
  fail "the @[validTactics #[simp [dbl2]]] tactic was not spliced into any generated pin theorem"
fi
if ! grep -qF -- '| (rfl)' ComparatorGrading/Pin*.lean; then
  fail "the @[defaultTactics] fallbacks were not spliced into the generated pin theorems"
fi

# ---------------------------------------------------------------------------
# 6. `--test` mode: every `@[autograderTest]` expectation must be met.
# ---------------------------------------------------------------------------
info "Running --test mode over tests/Tests.lean"
test_log="$REPO/.lake/test-suite.log"
if ! lake exe autograder --test --local tests/Tests.lean AutograderTests/Solution.lean > "$test_log" 2>&1; then
  fail "--test mode exited non-zero; full output in $test_log"
else
  # Each sheet exercise reports `Passed <correct>/<total> test cases!`.
  totals="$(grep -aoE 'Passed [0-9]+/[0-9]+ test cases!' "$test_log")"
  if [[ -z "$totals" ]]; then
    fail "--test mode produced no test-case tallies; full output in $test_log"
  else
    graded=0
    while read -r line; do
      correct="${line#Passed }"; correct="${correct%%/*}"
      total="${line#*/}"; total="${total%% *}"
      graded=$((graded + total))
      if [[ "$correct" != "$total" ]]; then
        fail "--test mode: only $correct of $total candidates met their @[autograderTest] expectation (full output in $test_log)"
      fi
    done <<< "$totals"
    expected_candidates="$(grep -c '^@\[autograderTest' tests/Tests.lean)"
    if [[ "$graded" != "$expected_candidates" ]]; then
      fail "--test mode graded $graded candidates but tests/Tests.lean declares $expected_candidates"
    fi
  fi
fi

# ---------------------------------------------------------------------------
if [[ "$failures" -eq 0 ]]; then
  echo "All autograder tests passed."
else
  echo "$failures test(s) failed." >&2
fi
exit $(( failures > 0 ))
