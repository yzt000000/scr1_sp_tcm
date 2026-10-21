#!/bin/bash
# Run only the two benchmarks (coremark + dhrystone21) on QuestaSim.
# Usage: run_bench.sh <repo_dir> [ITERATIONS]
#   <repo_dir> : absolute path of the SCR1 tree to simulate
#                (e.g. .../scr1        -> ITCM/DTCM single-port version
#                      .../scr1_base   -> pristine dual-port TCM baseline)
#   ITERATIONS : coremark iteration count (default 1)
set -o pipefail

repo="$1"
iter="${2:-1}"
if [ -z "$repo" ]; then
    echo "usage: $0 <repo_dir> [ITERATIONS]"
    exit 1
fi

cd "$repo" || exit 1

export PATH="/c/questasim64_2024.1/win64:/c/tools/shims:$PATH"
export CROSS_PREFIX="riscv64-unknown-elf-"
export RISCV_TESTS="$repo/dependencies/riscv-tests"
export RISCV_COMPLIANCE_TESTS="$repo/dependencies/riscv-compliance"

# TRACE=2 -> SCR1_TRACE_LOG_DIS, but it also makes bld_dir unique so that the
# benchmark runs never wipe (or depend on) the .hex files of the full regression.
exec make run_modelsim CFG=MAX BUS=AXI TCM=1 TRACE=2 \
    TARGETS="coremark dhrystone21" \
    ITERATIONS="$iter" \
    root_dir="$repo"
