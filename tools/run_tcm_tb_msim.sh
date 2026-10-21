#!/bin/bash
# Build and run the scr1_tcm ITCM/DTCM directed testbench with QuestaSim.
set -e
R="D:/python/scr1"
V="/c/questasim64_2024.1/win64"
export PATH="$V:$PATH"
cd "$R"
rm -rf build/tb_work
mkdir -p build/tb_work
cd build/tb_work
vlib work > /dev/null
vmap work work > /dev/null
vlog -work work -sv -O1 -mfcu +nowarnSVCHK \
    +incdir+"$R/src/includes" \
    +define+SCR1_TRGT_SIMULATION \
    "$R/src/top/scr1_sp_memory.sv" \
    "$R/src/top/scr1_itcm.sv" \
    "$R/src/top/scr1_dtcm.sv" \
    "$R/src/top/scr1_tcm.sv" \
    "$R/tools/tb/tb_scr1_tcm.sv" 2>&1 | grep -E "Error|Warning.*tb_scr1" || true
echo "=== COMPILE DONE, RUNNING ==="
vsim -c -do "run -all" work.tb_scr1_tcm 2>&1 | tail -30
