src_dir := $(dir $(lastword $(MAKEFILE_LIST)))

asm_src_in_project := tcm_cross_test.S

include $(inc_dir)/common.mk

default: log_requested_tgt $(bld_dir)/tcm_cross_test.elf $(bld_dir)/tcm_cross_test.hex $(bld_dir)/tcm_cross_test.dump

log_requested_tgt:
	echo tcm_cross_test.hex>> $(bld_dir)/test_info

clean:
	$(RM) $(asm_objs) $(bld_dir)/tcm_cross_test.elf $(bld_dir)/tcm_cross_test.hex $(bld_dir)/tcm_cross_test.dump