#!/bin/bash
# Run INSIDE WSL: create riscv64/riscv32-unknown-elf-* symlinks -> riscv-none-elf-*
# (xpack 15.x renamed binaries to riscv-none-elf-*; SCR1 expects riscv64-unknown-elf-*)
set -e
BIN=~/opt/riscv-toolchain/bin
cd "$BIN"
for f in riscv-none-elf-*; do
  [ -f "$f" ] || [ -L "$f" ] || continue
  base=${f#riscv-none-elf-}
  ln -sf "$f" "riscv64-unknown-elf-$base"
  ln -sf "$f" "riscv32-unknown-elf-$base"
done
echo "symlinks created. sample:"
ls -l riscv64-unknown-elf-gcc riscv64-unknown-elf-objdump riscv64-unknown-elf-objcopy 2>&1