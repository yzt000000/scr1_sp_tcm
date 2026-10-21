#!/bin/bash
# Lint helper for SCR1 with verilator.
# Usage: lint.sh [axi|ahb] [extra verilator args...]
set -e
R="D:/python/scr1"
V=$(command -v verilator 2>/dev/null) || { echo "ERROR: verilator not found in PATH (install verilator or set VERILATOR_ROOT)"; exit 1; }
BUS="${1:-axi}"; shift || true
if [ "$BUS" = "ahb" ]; then
    TOPFILES="ahb_top.files"; TBFILES="ahb_tb.files"; TOPMOD="scr1_top_ahb"
else
    TOPFILES="axi_top.files"; TBFILES="axi_tb.files"; TOPMOD="scr1_top_axi"
fi
FILES=$({ cat "$R/src/core.files"; echo; cat "$R/src/$TOPFILES"; echo; cat "$R/src/$TBFILES"; } | tr -d '\r' | sed '/^$/d' | sed "s|^|$R/src/|" | tr '\n' ' ')
exec "$V" --lint-only -sv --top-module "$TOPMOD" \
    -Wno-WIDTHEXPAND -Wno-WIDTH -Wno-ASCRANGE -Wno-CASEINCOMPLETE -Wno-UNOPTFLAT \
    -Wno-MULTIDRIVEN -Wno-UNSIGNED \
    +incdir+"$R/src/includes" +incdir+"$R/src/tb" \
    +define+SCR1_TRGT_SIMULATION +define+SCR1_CFG_RV32IMC_MAX \
    "$@" $FILES
