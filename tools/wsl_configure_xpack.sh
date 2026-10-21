#!/bin/bash
# Run INSIDE WSL: configure xpack riscv toolchain after extraction.
# - create stable symlink ~/opt/riscv-toolchain -> xpack-riscv-none-elf-gcc-<ver>
# - add bin to ~/.bashrc PATH (idempotent)
# - smoke test gcc
set -e
XPACK_DIR=$(ls -d ~/opt/xpack-riscv-none-elf-gcc-*/ 2>/dev/null | head -1)
if [ -z "$XPACK_DIR" ]; then
    echo "ERROR: no xpack-riscv-none-elf-gcc-* directory found under ~/opt"
    exit 1
fi
XPACK_DIR="${XPACK_DIR%/}"
ln -sfn "$XPACK_DIR" ~/opt/riscv-toolchain
echo "symlink: ~/opt/riscv-toolchain -> $XPACK_DIR"

LINE='export PATH="$HOME/opt/riscv-toolchain/bin:$PATH"'
if ! grep -qF 'riscv-toolchain/bin' ~/.bashrc 2>/dev/null; then
    echo "$LINE" >> ~/.bashrc
    echo "added PATH line to ~/.bashrc"
else
    echo "PATH line already in ~/.bashrc"
fi

# xpack 15.x renamed binaries to riscv-none-elf-*; create riscv64/32-unknown-elf-* symlinks
cd ~/opt/riscv-toolchain/bin
for f in riscv-none-elf-*; do
  [ -f "$f" ] || [ -L "$f" ] || continue
  base=${f#riscv-none-elf-}
  ln -sf "$f" "riscv64-unknown-elf-$base"
  ln -sf "$f" "riscv32-unknown-elf-$base"
done
cd ~
echo "=== gcc version ==="
~/opt/riscv-toolchain/bin/riscv64-unknown-elf-gcc --version | head -1
echo "=== arch check ==="
~/opt/riscv-toolchain/bin/riscv64-unknown-elf-gcc -print-multi-lib 2>/dev/null | head -5