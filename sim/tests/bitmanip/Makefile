src_dir := $(dir $(lastword $(MAKEFILE_LIST)))

# The B extension is assembled with the Zba/Zbb/Zbc mnemonics; Zbs is encoded
# as raw instruction words by the generator (binutils 2.35 has no Zbs support).
# override is required because the top level Makefile passes ARCH on the command
# line, which would otherwise beat a plain assignment.
override ARCH := imc_zba_zbb_zbc

# This test intentionally links for RAM (link.ld + crt.S) instead of the TCM
# image (link_tcm.ld + crt_tcm.S). Reason: the TCM startup path runs the RELOC
# copy loop, whose first store targets a computed address just below the ITCM
# window, so it goes out to AXI and stalls in the TB memory model once the image
# exceeds a few KB. Running from RAM avoids RELOC entirely. The B instructions
# under test are exercised identically either way.
ld_script := $(inc_dir)/link.ld
asm_src   := crt.S

# sc_print.o is a *shared* object name in bld_dir: coremark and dhrystone21 build
# it first, with -flto.  make then considers it up to date for this test as well,
# so bitmanip links an LTO object and ld re-runs codegen at link time.  That LTO
# sub-process re-emits Zba/Zbb instructions (sh2add, max, ...) but does not pass
# -march down to its assembler, which then fails with
#     Error: unrecognized opcode `sh2add'
# Feeding the assembler option through -Wa fixes the LTO path without disturbing
# the objects the other tests reuse.
ADD_LDFLAGS := -Wa,-march=rv32$(ARCH)

c_src             := sc_print.c bitmanip.c
# NOTE: must go into asm_src_in_project, plain asm_src would override the crt
asm_src_in_project := bitmanip_test.S mdu_latency.S

include $(inc_dir)/common.mk

default: log_requested_tgt $(bld_dir)/bitmanip.elf $(bld_dir)/bitmanip.hex $(bld_dir)/bitmanip.dump

log_requested_tgt:
	echo bitmanip.hex>> $(bld_dir)/test_info

clean:
	$(RM) $(c_objs) $(asm_objs) $(bld_dir)/bitmanip.elf $(bld_dir)/bitmanip.hex $(bld_dir)/bitmanip.dump
