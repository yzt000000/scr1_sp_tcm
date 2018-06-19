/*
* Copyright by Syntacore LLC © 2016, 2017. See LICENSE for details
* @file       <link.ld>
* @brief      bare metal tests' linker script
*/

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY {
  RAM (rwx) : ORIGIN = 0x0, LENGTH = 64K
  ITCM (rwx) : ORIGIN = 0x00480000, LENGTH = 64K
  DTCM (rwx) : ORIGIN = 0x00490000, LENGTH = 64K
}

STACK_SIZE = 1024;

CL_SIZE = 32;

SECTIONS {

  /* code segment */
  .text.init ORIGIN(ITCM) : { 
    FILL(0);
    . = 0x100 - 12;
    SIM_EXIT = .;
    LONG(0x13);
    SIM_STOP = .;
    LONG(0x6F);
    LONG(-1);
    . = 0x100;
    *crt_tcm.o(.text .text.*)
  } >ITCM 

  __reloc_start = .;

  .text : {
    PROVIDE(__TEXT_START__ = .);
    *(.text .text.*)
    *(sc_test_section)
    . = ALIGN(CL_SIZE);
     PROVIDE(__TEXT_END__ = .);
  } >ITCM  

  .rodata : {
    _gp = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
    . = ALIGN(16);
  } >DTCM 

  /* data segment */
  .data : {
    PROVIDE(__DATA_START__ = .);
    *(.data .data.*)
    . = ALIGN(CL_SIZE);
  } >DTCM 

  .sdata : {
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    . = ALIGN(CL_SIZE);
    PROVIDE(__DATA_END__ = .);
  } >DTCM 

  /* thread-local data segment */
  .tdata : {
    PROVIDE(_tls_data = .);
    PROVIDE(_tdata_begin = .);
    *(.tdata .tdata.*)
    PROVIDE(_tdata_end = .);
    . = ALIGN(CL_SIZE);
  } >DTCM 

  .tbss : {
    PROVIDE(_tbss_begin = .);
    *(.tbss .tbss.*)
    . = ALIGN(CL_SIZE);
    PROVIDE(_tbss_end = .);
  } >DTCM 

  /* bss segment */
  .sbss : {
    PROVIDE(__BSS_START__ = .);
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  } >DTCM 

  .bss : {
    *(.bss .bss.*)
    . = ALIGN(CL_SIZE);
    PROVIDE(__BSS_END__ = .);
  } >DTCM 

  _end = .;
  PROVIDE(__end = .);

  /* End of uninitalized data segement */

  .stack ORIGIN(DTCM) + LENGTH(DTCM) - STACK_SIZE : {
    PROVIDE(__STACK_START__ = .);
    . += STACK_SIZE;
    PROVIDE(__C_STACK_TOP__ = .);
    PROVIDE(__STACK_END__ = .);
  } >DTCM

  /DISCARD/ : {
    *(.eh_frame .eh_frame.*)
  }
}
