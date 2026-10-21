src_dir := $(dir $(lastword $(MAKEFILE_LIST)))

# CV-X-IF custom extension test.
# Uses .insn pseudo-instruction to encode custom-0 instructions.
# .insn is a GAS pseudo-op that encodes arbitrary instructions without
# requiring the custom extension to be declared in -march.
override ARCH := imc

ld_script := $(inc_dir)/link.ld
asm_src   := crt.S

ADD_LDFLAGS := -Wa,-march=rv32$(ARCH)

c_src             := sc_print.c cvxif.c
asm_src_in_project := cvxif_test.S

include $(inc_dir)/common.mk

default: log_requested_tgt $(bld_dir)/cvxif.elf $(bld_dir)/cvxif.hex $(bld_dir)/cvxif.dump

log_requested_tgt:
	echo cvxif.hex>> $(bld_dir)/test_info

clean:
	$(RM) $(c_objs) $(asm_objs) $(bld_dir)/cvxif.elf $(bld_dir)/cvxif.hex $(bld_dir)/cvxif.dump