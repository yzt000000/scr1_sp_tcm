#!/bin/bash
# Build and run the scr1_tcm ITCM/DTCM directed testbench with Verilator.
set -e
R="D:/python/scr1"
export PATH="/c/tools/msys64/usr/bin:/c/tools/mingw/mingw64/bin:/c/tools/msys64/mingw64/bin:$PATH"
cd "$R"
rm -rf build/tb_obj
verilator --binary --timing -sv --top-module tb_scr1_tcm \
    -Wno-WIDTH -Wno-WIDTHEXPAND -Wno-UNOPTFLAT -Wno-CASEINCOMPLETE \
    -Wno-UNSIGNED -Wno-MULTIDRIVEN -Wno-DECLFILENAME -Wno-VARHIDDEN \
    +incdir+"$R/src/includes" \
    "$R/src/top/scr1_tcm.sv" \
    "$R/src/top/scr1_sp_memory.sv" \
    "$R/tools/tb/tb_scr1_tcm.sv" \
    -Mdir build/tb_obj 2>&1 | tail -25
echo "=== BUILD DONE, RUNNING ==="
./build/tb_obj/Vtb_scr1_tcm
