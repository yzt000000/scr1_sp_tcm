#!/bin/bash
# Full SCR1 regression (QuestaSim) for the ITCM/DTCM TCM change.
# Notes:
#  - root_dir is overridden with a Windows-style path because the native
#    Windows make cannot chdir to MSYS-style /c/... paths in recipes that
#    contain no shell metacharacters.
#  - Local (temporary) patches in sim/tests/**/Makefile adapt the flow to
#    the xpack GCC 10.2 toolchain (no zicsr/zifencei names, full libc link
#    order, -lnosys); they are reverted after the verification run.
cd "D:/python/scr1"
export PATH="/c/questasim64_2024.1/win64:/c/tools/shims:$PATH"
export CROSS_PREFIX="riscv64-unknown-elf-"
export RISCV_TESTS="D:/python/scr1/dependencies/riscv-tests"
export RISCV_COMPLIANCE_TESTS="D:/python/scr1/dependencies/riscv-compliance"
exec make run_modelsim CFG=MAX BUS=AXI root_dir="D:/python/scr1"
