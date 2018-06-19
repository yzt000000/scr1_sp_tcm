#------------------------------------------------------------------------------
# Makefile for SCR1
#------------------------------------------------------------------------------

# Parameters
ifeq ($(RVE),1)
export ARCH += e
else
export ARCH += i
endif

ifeq ($(RVM),1)
export ARCH := $(ARCH)m
endif

export ABI  ?= ilp32
# Testbench memory delay patterns (FFFFFFFF - no delay, 00000000 - random delay, 00000001 - max delay)
imem_pattern ?= FFFFFFFF
dmem_pattern ?= FFFFFFFF

VCS_OPTS ?=
MODELSIM_OPTS ?=
NCSIM_OPTS ?=

# Paths
export root_dir := $(shell pwd)
export inc_dir := $(root_dir)/tests/common
export bld_dir := $(root_dir)/build

test_results := $(bld_dir)/test_results.txt
test_info := $(bld_dir)/test_info
tcm_info  := $(bld_dir)/tcm_info
itcm_info  := $(bld_dir)/itcm_info
dtcm_info  := $(bld_dir)/dtcm_info

ifndef TB
	TB=sram
endif

# Environment
export CROSS_PREFIX ?= riscv64-unknown-elf-
export RISCV_GCC ?= $(CROSS_PREFIX)gcc
export RISCV_OBJDUMP ?= $(CROSS_PREFIX)objdump -D
export RISCV_OBJCOPY ?= $(CROSS_PREFIX)objcopy -O verilog
export RISCV_READELF ?= $(CROSS_PREFIX)readelf -s

ifeq ($(BUS),AHB)
export top_module := scr1_top_tb_ahb
ifeq ($(TB),tcm)
export rtl_files  := rtl_ahb_tcm.files
else
export rtl_files  := rtl_ahb.files
endif
endif

ifeq ($(BUS),AXI)
export rtl_files  := rtl_axi.files
export top_module := scr1_top_tb_axi
endif

ifeq ($(RVE),1)
EXT_CFLAGS := -D__RVE_EXT
endif



ifeq ($(RVE),1)
else

ifeq ($(IPIC),1)
TARGETS += vectored_isr_sample
endif

ifeq ($(RVM),1)
TARGETS += riscv_isa
endif

endif
TARGETS += dhrystone21

ifndef TS
	TS = test1
endif

ifndef FSDB
	FSDB =$(TS)
endif

ifeq ($(TB),tcm)
SVH := ./src/includes/scr1_arch_description_tcm.svh
TCM_EN	= TCM=TRUE 
else
SVH := ./src/includes/scr1_arch_description_nb.svh
TCM_EN	= TCM=FALSE 
endif

# Targets
.PHONY: tests run_modelsim run_vcs run_ncsim

default: run_modelsim


tests: $(TS)

$(test_info): clean_hex clean_tcm tests
	cd $(bld_dir); \
	rm test_info; \
	rm tcm_info; \
	rm itcm_info; \
	rm dtcm_info; \
	ls -tr *.hex > $@
$(tcm_info): 
	cd $(bld_dir); \
	cp test_info tcm_info; \
	sed -i 's/hex/tcm/' tcm_info ;

$(itcm_info): 
	cd $(bld_dir); \
	cp test_info itcm_info; \
	sed -i 's/hex/itcm/' itcm_info ;

$(dtcm_info): 
	cd $(bld_dir); \
	cp test_info dtcm_info; \
	sed -i 's/hex/dtcm/' dtcm_info ;




build_define : build_dump
	echo $(SVH)
	cp $(SVH) ./src/includes/scr1_arch_description.svh

build_dump:
	echo $(FSDB)
	echo 'fsdbDumpvars 0 "scr1_top_tb_ahb" +fsdbfile+../fsdb/$(FSDB).fsdb ' > src/dump.ucli
	echo 'run' >> src/dump.ucli

#ls -tr *.tcm > $@


	
#$(MAKE) -C $(root_dir)/tests/test1/test1  $(TCM_EN) 

test1: | $(bld_dir)
	$(MAKE) -C $(root_dir)/tests/test1/test1  EXT_CFLAGS="$(EXT_CFLAGS)"  $(TCM_EN)

helloworld: | $(bld_dir)
	$(MAKE) -C $(root_dir)/tests/helloworld  EXT_CFLAGS="$(EXT_CFLAGS)"  $(TCM_EN)

coremark: | $(bld_dir)
	$(MAKE) -C $(root_dir)/tests/coremark  EXT_CFLAGS="$(EXT_CFLAGS)"  $(TCM_EN)

sram_test: | $(bld_dir)
	$(MAKE) -C $(root_dir)/tests/sram_test  EXT_CFLAGS="$(EXT_CFLAGS)"  $(TCM_EN)

dtcm_test: | $(bld_dir)
	$(MAKE) -C $(root_dir)/tests/dtcm_test  EXT_CFLAGS="$(EXT_CFLAGS)"  $(TCM_EN)

itcm_test: | $(bld_dir)
	$(MAKE) -C $(root_dir)/tests/itcm_test  EXT_CFLAGS="$(EXT_CFLAGS)"  $(TCM_EN)

demo_iasm: | $(bld_dir)
	$(MAKE) -C $(root_dir)/tests/demo_iasm  EXT_CFLAGS="$(EXT_CFLAGS)"  $(TCM_EN)

vectored_isr_sample: | $(bld_dir)
	$(MAKE) -C $(root_dir)/tests/vectored_isr_sample

dhrystone21: | $(bld_dir)
	$(MAKE) -C $(root_dir)/tests/benchmarks/dhrystone21 EXT_CFLAGS="$(EXT_CFLAGS)"  $(TCM_EN)

riscv_isa: | $(bld_dir)
	$(MAKE) -C $(root_dir)/tests/riscv_isa EXT_CFLAGS="$(EXT_CFLAGS)" $(TCM_EN)
	echo "end of compile c"

clean_hex: | $(bld_dir)
	$(RM) $(bld_dir)/*.hex

clean_tcm: | $(bld_dir)
	$(RM) $(bld_dir)/*.tcm
	$(RM) tcm_info

$(bld_dir):
	mkdir -p $(bld_dir)

run_vcs: build_define $(test_info) $(tcm_info) $(itcm_info) $(dtcm_info) 
	$(MAKE) -C $(root_dir)/src build_vcs;
	printf "" > $(test_results);
	cd $(bld_dir); \
	$(bld_dir)/simv +fsdb+all=on +fsdb+mda=on -ucli -i ../src/dump.ucli \
	+test_info=$(test_info) \
	+tcm_info=$(tcm_info) \
	+itcm_info=$(itcm_info) \
	+dtcm_info=$(dtcm_info) \
	+test_results=$(test_results) \
	+imem_pattern=$(imem_pattern) \
	+dmem_pattern=$(dmem_pattern) \
	$(VCS_OPTS)

run_modelsim: $(test_info)
	$(MAKE) -C $(root_dir)/src build_modelsim; \
	printf "" > $(test_results); \
	cd $(bld_dir); \
	vsim -c -do "run -all" +nowarn3691 \
	+test_info=$(test_info) \
	+test_results=$(test_results) \
	+imem_pattern=$(imem_pattern) \
	+dmem_pattern=$(dmem_pattern) \
	work.$(top_module) \
	$(MODELSIM_OPTS)

run_ncsim: $(test_info)
	$(MAKE) -C $(root_dir)/src build_ncsim;
	printf "" > $(test_results);
	cd $(bld_dir); \
	irun \
	-R \
	-64bit \
	+test_info=$(test_info) \
	+test_results=$(test_results) \
	+imem_pattern=$(imem_pattern) \
	+dmem_pattern=$(dmem_pattern) \
	$(NCSIM_OPTS)
run_verdi:
	$(MAKE) -C $(root_dir)/src run_verdi; 


clean: clean_tcm
	$(MAKE) -C $(root_dir)/tests/benchmarks/dhrystone21 clean
	$(MAKE) -C $(root_dir)/tests/riscv_isa clean
	$(MAKE) -C $(root_dir)/tests/test1/test1 clean
	$(RM) $(test_info)
	$(RM) $(tcm_info)
	$(RM) $(bld_dir)/*.o
	$(RM) $(bld_dir)/*.log
	$(RM) -rf $(bld_dir)/simv* 
	$(RM) -rf $(bld_dir)/csrc

clean_all: clean
	$(RM)  -rf $(bld_dir)/*
