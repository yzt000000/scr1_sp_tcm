src_dir := $(dir $(lastword $(MAKEFILE_LIST)))

FLAGS = -O3 -funroll-loops -fpeel-loops -fgcse-sm -fgcse-las -flto
FLAGS_STR = "$(FLAGS)"

CFLAGS := $(FLAGS) $(EXT_CFLAGS) \
-static -std=gnu99 -fno-common -fno-builtin-printf \
-Wa,-march=rv32$(ARCH) -march=rv32$(ARCH) -mabi=$(ABI) \
-DFLAGS_STR=\"$(FLAGS_STR)\" \
-DSELF_TIMED=1 -DTIME=1
LDFLAGS := -nostartfiles -nostdlib -lc -lgcc -march=rv32$(ARCH) -mabi=$(ABI)
VPATH += $(src_dir) $(inc_dir)
incs += -I$(src_dir) -I$(inc_dir)


#ifdef TCM 
ifeq ($(TCM),TRUE)
ld_script := $(inc_dir)/link_tcm.ld
asm_src := crt_tcm.S
else
ld_script := $(inc_dir)/link.ld
asm_src := crt.S
endif

#ifdef TCM
ifeq ($(TCM),TRUE)
baseaddr :=480000
else
baseaddr :=0
endif

c_src := sc_print.c  dtcm_test.c

c_objs := $(addprefix $(bld_dir)/,$(patsubst %.c, %.o, $(c_src)))
asm_objs := $(addprefix $(bld_dir)/,$(patsubst %.S, %.o, $(asm_src)))

default: $(bld_dir)/dtcm_test.elf $(bld_dir)/dtcm_test.hex $(bld_dir)/dtcm_test.dump $(bld_dir)/dtcm_test.tcm

$(bld_dir)/%.o: %.S
	$(RISCV_GCC) $(CFLAGS) -D__ASSEMBLY__=1 -c $(incs) $< -o $@

$(bld_dir)/%.o: %.c
	$(RISCV_GCC) $(CFLAGS) -c $(incs) $< -o $@

$(bld_dir)/dtcm_test.elf: $(ld_script) $(c_objs) $(asm_objs)
	$(RISCV_GCC) -o $@ -T $^ $(LDFLAGS)

$(bld_dir)/dtcm_test.hex: $(bld_dir)/dtcm_test.elf
	$(RISCV_OBJCOPY) $^ $@

$(bld_dir)/dtcm_test.dump: $(bld_dir)/dtcm_test.elf
	$(RISCV_OBJDUMP) $^ > $@


$(bld_dir)/%.tcm: $(bld_dir)/%.hex
	perl ../../th.pl -f  $^  -o $@ -b $(baseaddr)



clean:
	$(RM) $(c_objs) $(asm_objs) $(bld_dir)/dtcm_test.elf $(bld_dir)/dtcm_test.hex $(bld_dir)/dtcm_test.dump $(bld_dir)/dtcm_test.tcm
