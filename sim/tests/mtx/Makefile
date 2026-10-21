src_dir := $(dir $(lastword $(MAKEFILE_LIST)))

# Matrix Multiply extension test.
# Uses .insn pseudo-instruction to encode custom-1 instructions.
override ARCH := imc

ld_script := $(inc_dir)/link_tcm.ld
asm_src   := crt_tcm.S

ADD_LDFLAGS := -Wa,-march=rv32$(ARCH)

c_src             := sc_print.c mtx.c
asm_src_in_project := mtx_test.S

include $(inc_dir)/common.mk

default: log_requested_tgt $(bld_dir)/mtx.elf $(bld_dir)/mtx.hex $(bld_dir)/mtx.dump

log_requested_tgt:
	echo mtx.hex>> $(bld_dir)/test_info

clean:
	$(RM) $(c_objs) $(asm_objs) $(bld_dir)/mtx.elf $(bld_dir)/mtx.hex $(bld_dir)/mtx.dump