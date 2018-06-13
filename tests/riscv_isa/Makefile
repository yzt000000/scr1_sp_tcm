ARCH := imfc

include rv32_tests.inc

src_dir := $(CURDIR)
obj_dir   := $(bld_dir)/riscv_objs
test_list := $(patsubst %.S, %, $(notdir $(rv32_isa_tests)))
objs      := $(addprefix $(obj_dir)/,$(test_list:%=%.o))
test_elf  := $(addprefix $(bld_dir)/,$(test_list:%=%.elf))
test_hex  := $(addprefix $(bld_dir)/,$(test_list:%=%.hex))
test_dump := $(addprefix $(bld_dir)/,$(test_list:%=%.dump))
test_tcm  := $(addprefix $(bld_dir)/,$(test_list:%=%.tcm))

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


src_dir := $(dir $(lastword $(MAKEFILE_LIST)))

FLAGS = -O3 -funroll-loops -fpeel-loops -fgcse-sm -fgcse-las -flto
FLAGS_STR = "$(FLAGS)"

CFLAGS := $(FLAGS) $(EXT_CFLAGS) \
-I$(inc_dir) -I$(src_dir) -DASM \
-static -std=gnu99 -fno-common -fno-builtin-printf \
-Wa,-march=rv32$(ARCH) -march=rv32$(ARCH) -mabi=$(ABI) \
-DFLAGS_STR=\"$(FLAGS_STR)\" \
-DSELF_TIMED=1 -DTIME=1


#LDFLAGS := -static -fvisibility=hidden -nostdlib -nostartfiles -T$(ld_script) -march=rv32$(ARCH) -mabi=ilp32f
LDFLAGS := -nostartfiles -nostdlib -lc -lgcc -march=rv32$(ARCH) -mabi=ilp32f

VPATH += $(src_dir) $(bld_dir) $(obj_dir) $(RISCV_TESTS)

default: check_riscv_tests $(test_tcm) $(test_elf) $(test_hex) $(test_dump) 

define compile_template
$(obj_dir)/$$(basename $(notdir $(SRC))).o: $$(SRC) | $(obj_dir) $(asm_objs) $(ld_script)
	$(RISCV_GCC) -c $$< $(CFLAGS) -o $$@
 endef

$(foreach SRC,$(rv32_isa_tests), $(eval $(compile_template)))

$(obj_dir) :
	mkdir -p $(obj_dir)

$(bld_dir)/%.elf: $(obj_dir)/%.o | $(obj_dir) $(ld_script)
	$(RISCV_GCC) $^ $(LDFLAGS) -o $@

$(bld_dir)/%.hex: $(bld_dir)/%.elf
	$(RISCV_OBJCOPY) $^ $@

$(bld_dir)/%.dump: $(bld_dir)/%.elf
	$(RISCV_OBJDUMP) $^ > $@

$(bld_dir)/%.tcm: $(bld_dir)/%.hex
	perl ../../th.pl -f  $^  -o $@ -b $(baseaddr)

clean:
	$(RM) $(test_elf) $(test_hex) $(test_dump) $(objs) $(test_tcm)
	$(RM) -R $(obj_dir)


.PHONY: check_riscv_tests

riscv_tests_dir    := $(if $(RISCV_TESTS), $(RISCV_TESTS), ./undefined)
riscv_tests_commit := a9433c4daa287fbe101025f2a079261a10149225
## commit hash readed from local copy of https://github.com/riscv/riscv-tests
tmp_commit = $(shell cd $(riscv_tests_dir) 2>/dev/null && git log -1 | grep "commit" | cut -f2 -d ' ')
is_commit_good = $(if $(subst $(riscv_tests_commit),,$(tmp_commit)),false,true)

# Color
RED=\033[0;31m
NC=\033[0m

check_riscv_tests : $(riscv_tests_dir)
	@if [ ! -d $(riscv_tests_dir) ]; then \
		echo -e "$(RED)==========================================================================" &&\
		echo "   Error! Environment variable RISCV_TESTS='$(riscv_tests_dir)' " &&\
		echo "      directory not exist!" && \
		echo "==========================================================================$(NC)" ; \
	fi
ifneq (,$(is_repo_changed))
	@echo -e "$(RED)=========================================================================="
	@echo "   Error! Repo '$(riscv_tests_dir)' "
	@echo "     must be unchanged!"
	@echo -e "==========================================================================$(NC)"
	exit 1
endif
ifneq ($(is_commit_good),true)
	@echo -e "$(RED)=========================================================================="
	@echo "   Error! riscv-tests must point to commit $(riscv_tests_commit)"
	@echo -e "==========================================================================$(NC)"
	exit 1
endif

$(riscv_tests_dir) :.
ifndef RISCV_TESTS
	@echo -e "$(RED)=========================================================================="
	@echo "    Error! Environment variable RISCV_TESTS not set!"
	@echo "    You must set the environment variable RISCV_TESTS"
	@echo "    The variable should point to the local copy of the"
	@echo "      repository https://github.com/riscv/riscv-tests"
	@echo "      with the commit $(riscv_tests_commit)"
	@echo -e "==========================================================================$(NC)"
	exit 1
endif
