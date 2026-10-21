#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Lint every interesting combination of the RVM / RVB / FAST_MUL switches.

The Zbc implementation is chosen by derived macros, so it is easy to break one
combination while fixing another.  This runs Verilator over all of them.
"""
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ARCH = ROOT / "src" / "includes" / "scr1_arch_description.svh"
SRC = ROOT / "src"


def find_verilator():
    """Verilator lives in an msys tree that is on PATH for bash but not for Win32."""
    found = shutil.which("verilator")
    if found:
        return found
    candidates = ["verilator.exe", "verilator"]
    roots = [pathlib.Path(r"C:\tools\msys64\usr\local\bin"),
             pathlib.Path(r"C:\msys64\usr\local\bin"),
             pathlib.Path(r"C:\Program Files\Git\usr\local\bin")]
    for root in roots:
        for cand in candidates:
            path = root / cand
            if path.exists():
                return str(path)
    raise SystemExit("verilator not found")


VERILATOR = find_verilator()

# exact lines in the custom configuration section
RVM_LINE = '`define SCR1_RVM_EXT                // enable standard extension "M" for integer hardware multiplier and divider\n'
RVB_LINE = '`define SCR1_RVB_EXT                // enable standard extension "B" (Zba + Zbb + Zbc + Zbs bit manipulation)\n'
FAST_LINE = '`define SCR1_FAST_MUL               // enable fast one-cycle multiplication, otherwise multiplication takes 32 cycles\n'

CONFIGS = [
    ("A. default custom: RVM+RVB+FAST_MUL -> iterative clmul, fast mul", False, False, False),
    ("B. RVB only (no M): combinational clmul in BALU", True, False, False),
    ("C. RVM+RVB, iterative MUL too (no FAST_MUL)", False, False, True),
    ("D. no RVB at all: stock SCR1 with M extension", False, True, False),
    ("E. neither M nor B", True, True, False),
]


def patch(disable_rvm, disable_rvb, disable_fast):
    text = ARCH.read_text()
    if disable_rvm:
        assert RVM_LINE in text, "RVM line not found - update this script"
        text = text.replace(RVM_LINE, "// " + RVM_LINE.rstrip() + "  [disabled by lint matrix]\n")
    if disable_rvb:
        assert RVB_LINE in text, "RVB line not found - update this script"
        text = text.replace(RVB_LINE, "// " + RVB_LINE.rstrip() + "  [disabled by lint matrix]\n")
    if disable_fast:
        assert FAST_LINE in text, "FAST_MUL line not found - update this script"
        text = text.replace(FAST_LINE, "// " + FAST_LINE.rstrip() + "  [disabled by lint matrix]\n")
    ARCH.write_text(text)


def main():
    backup = ARCH.read_text()
    failures = 0
    try:
        for name, d_rvm, d_rvb, d_fast in CONFIGS:
            patch(d_rvm, d_rvb, d_fast)
            err_total = 0
            detail = []
            for filelist, top in (("axi_top.files", "scr1_top_axi"),
                                  ("ahb_top.files", "scr1_top_ahb")):
                # Verilator is only reachable through the bash environment here,
                # hence the explicit shell invocation instead of a raw exec.
                cmd = ["bash", "-lc",
                       " ".join(["verilator", "--lint-only", "-Wall",
                                 "-I../src/includes", "-I.", "-f", filelist,
                                 "--top-module", top])]
                proc = subprocess.run(cmd, cwd=str(SRC), capture_output=True, text=True)
                errs = [l for l in proc.stderr.splitlines() if "%Error" in l]
                err_total += len(errs)
                detail.extend(errs[:3])
            ARCH.write_text(backup)
            status = "OK  " if err_total == 0 else "FAIL"
            if err_total:
                failures += 1
            print(f"[{status}] {name}  (errors={err_total})")
            for line in detail:
                print(f"           {line}")
    finally:
        ARCH.write_text(backup)
    print()
    print("ALL CONFIGS CLEAN" if failures == 0 else f"{failures} CONFIG(S) FAILED")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
