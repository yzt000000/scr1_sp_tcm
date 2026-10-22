src_dir := $(dir $(lastword $(MAKEFILE_LIST)))

c_src := sc_print.c tcm_sbr.c

include $(inc_dir)/common.mk

default: log_requested_tgt $(bld_dir)/tcm_sbr.elf $(bld_dir)/tcm_sbr.hex $(bld_dir)/tcm_sbr.dump

log_requested_tgt:
	echo tcm_sbr.hex>> $(bld_dir)/test_info

clean:
	$(RM) $(c_objs) $(asm_objs) $(bld_dir)/tcm_sbr.elf $(bld_dir)/tcm_sbr.hex $(bld_dir)/tcm_sbr.dump