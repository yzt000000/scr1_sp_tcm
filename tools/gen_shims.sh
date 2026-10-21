#!/bin/bash
# Generate Windows shims that redirect riscv64-unknown-elf-* / riscv32-unknown-elf-*
# calls into the WSL xpack toolchain, with Windows->WSL path conversion.
# Run this on Windows git-bash. Output dir: /c/tools/shims (matches original env PATH).
set -e
SHIM_DIR="/c/tools/shims"
WSL_BIN="/home/jason/opt/riscv-toolchain/bin"
WSL_DISTRO="${WSL_DISTRO:-Ubuntu-26.04}"
mkdir -p "$SHIM_DIR"
CMDS="gcc g++ cpp c++ as ld ar nm objcopy objdump readelf size strip ranlib addr2line c++filt strings elfedit gprof"

TEMPLATE=$(cat <<'EOF'
#!/bin/bash
export MSYS_NO_PATHCONV=1
# Auto-generated shim -> WSL xpack riscv toolchain (path conversion enabled)
args=()
for a in "$@"; do
  case "$a" in
    -march=*zicsr*|-march=*zifencei*)
      args+=("$a") ;;
    -march=*)
      args+=("${a}_zicsr_zifencei") ;;
    -Wa,-march=*zicsr*|-Wa,-march=*zifencei*)
      args+=("$a") ;;
    -Wa,-march=*)
      args+=("${a}_zicsr_zifencei") ;;
    [A-Za-z]:[/\\]*)
      d=$(printf '%s' "${a:0:1}" | tr 'A-Z' 'a-z')
      r="${a:2}"; r=${r//\\//}
      args+=("/mnt/$d$r") ;;
    -I[A-Za-z]:[/\\]*)
      d=$(printf '%s' "${a:2:1}" | tr 'A-Z' 'a-z')
      r="${a:4}"; r=${r//\\//}
      args+=("-I/mnt/$d$r") ;;
    -L[A-Za-z]:[/\\]*)
      d=$(printf '%s' "${a:2:1}" | tr 'A-Z' 'a-z')
      r="${a:4}"; r=${r//\\//}
      args+=("-L/mnt/$d$r") ;;
    -T[A-Za-z]:[/\\]*)
      d=$(printf '%s' "${a:2:1}" | tr 'A-Z' 'a-z')
      r="${a:4}"; r=${r//\\//}
      args+=("-T/mnt/$d$r") ;;
    --script=[A-Za-z]:[/\\]*)
      d=$(printf '%s' "${a:9:1}" | tr 'A-Z' 'a-z')
      r="${a:11}"; r=${r//\\//}
      args+=("--script=/mnt/$d$r") ;;
    *) args+=("$a") ;;
  esac
done
exec wsl -d __WSL_DISTRO__ __WSL_BIN__/riscv64-unknown-elf-__CMD__ "${args[@]}"
EOF
)

for c in $CMDS; do
  shim="$SHIM_DIR/riscv64-unknown-elf-$c"
  echo "$TEMPLATE" | sed "s|__CMD__|$c|g; s|__WSL_BIN__|$WSL_BIN|g; s|__WSL_DISTRO__|$WSL_DISTRO|g" > "$shim"
  chmod +x "$shim"
  ln -sf "riscv64-unknown-elf-$c" "$SHIM_DIR/riscv32-unknown-elf-$c" 2>/dev/null || true
done
echo "Generated $(echo $CMDS | wc -w) shims (riscv32+riscv64) in $SHIM_DIR"
ls "$SHIM_DIR" | grep riscv | head -10