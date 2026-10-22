#!/bin/bash
# Full SCR1 regression (QuestaSim) for the ITCM/DTCM TCM change.
# Notes:
#  - The repository root is derived from this script's location, so the
#    script can be run from any checkout (no hardcoded machine path).
#  - root_dir is overridden with a Windows-style path because the native
#    Windows make cannot chdir to MSYS-style /c/... paths in recipes that
#    contain no shell metacharacters.
#  - Local (temporary) patches in sim/tests/**/Makefile adapt the flow to
#    the xpack GCC toolchain; they are reverted after the verification run.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R="$(cd "$SCRIPT_DIR/.." && pwd)"
R_WIN="$(cygpath -w "$R" 2>/dev/null || echo "$R")"
export PATH="/c/questasim64_2024.1/win64:/c/tools/shims:$PATH"
export CROSS_PREFIX="riscv64-unknown-elf-"
export RISCV_TESTS="$R_WIN/dependencies/riscv-tests"
export RISCV_COMPLIANCE_TESTS="$R_WIN/dependencies/riscv-compliance"
cd "$R_WIN"
exec make run_modelsim CFG=MAX BUS=AXI root_dir="$R_WIN"
