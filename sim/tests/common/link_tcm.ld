/*
* Copyright by Syntacore LLC © 2016, 2017, 2021. See LICENSE for details
* @file       <link_tcm.ld>
* @brief      bare metal tests' linker script (split ITCM/DTCM)
*
* The TCM is implemented as two independent single-port memories, each with
* its own address window (classic MCU ITCM/DTCM):
*   - ITCM (0x00480000, 64K): instruction code and read-only data
*   - DTCM (0x00490000, 64K): mutable data, tls, bss and stack
* The load image stays in RAM and is copied to ITCM/DTCM by the startup
* code (see reloc.h) segment by segment.
*
* Note: an ALIGN() before the section colon is parsed as an explicit start
* address, which breaks the memory region assignment, so section alignment
* is done inside the sections instead.
*/

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY {
  RAM (rwx)  : ORIGIN = 0x0,        LENGTH = 64K
  ITCM (rwx) : ORIGIN = 0x00480000, LENGTH = 64K
  DTCM (rwx) : ORIGIN = 0x00490000, LENGTH = 64K
}

STACK_SIZE = 1024;

CL_SIZE = 32;

SECTIONS {

  /* code segment */
  .text.init ORIGIN(RAM) : {
    FILL(0);
    . = 0x100 - 12;
    SIM_EXIT = .;
    LONG(0x13);
    SIM_STOP = .;
    LONG(0x6F);
    LONG(-1);
    . = 0x100;
    *crt_tcm.o(.text .text.*)
    *(.text.init)
    . = ALIGN(CL_SIZE);
  } >RAM

  __reloc_start = .;

  /* instruction segment: code and read-only data go to ITCM */
  .text : {
    PROVIDE(__TEXT_START__ = .);
    *(.text .text.*)
    *(sc_test_section)
    . = ALIGN(CL_SIZE);
     PROVIDE(__TEXT_END__ = .);
  } >ITCM AT>RAM

  .rodata : {
    PROVIDE(__RODATA_START__ = .);
    *(.rodata) *(.rodata.*) *(.gnu.linkonce.r.*)
    . = ALIGN(CL_SIZE);
    LONG(0x13);
    . = ALIGN(CL_SIZE);
    PROVIDE(__RODATA_END__ = .);
  } >ITCM AT>RAM

  /* load addresses (in RAM) of the ITCM image, used by the startup code */
  __ITCM_IMAGE_START__ = LOADADDR(.text);
  __ITCM_IMAGE_END__   = LOADADDR(.rodata) + SIZEOF(.rodata);

  /* data segment: mutable data, tls, bss and stack go to DTCM */
  .data : {
    PROVIDE(__DATA_START__ = .);
    *(.data .data.*)
    . = ALIGN(CL_SIZE);
  } >DTCM AT>RAM


  .sdata : {
    __global_pointer$ = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    . = ALIGN(CL_SIZE);
    PROVIDE(__DATA_END__ = .);
  } >DTCM AT>RAM

  /* thread-local data segment */
  .tdata : {
    PROVIDE(_tls_data = .);
    PROVIDE(_tdata_begin = .);
    *(.tdata .tdata.*)
    PROVIDE(_tdata_end = .);
    . = ALIGN(CL_SIZE);
  } >DTCM AT>RAM

  /* load addresses (in RAM) of the DTCM image, used by the startup code.
     The whole data image (data+sdata+tdata) is covered. */
  __DTCM_IMAGE_START__ = LOADADDR(.data);
  __DTCM_IMAGE_END__   = LOADADDR(.tdata) + SIZEOF(.tdata);

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
    . = ALIGN(CL_SIZE);
  } >DTCM

  .bss : {
    *(.dynbss) *(.bss .bss.* .gnu.linkonce.b.*) *(COMMON)
    . = ALIGN(CL_SIZE);
    PROVIDE(__BSS_END__ = .);
  } >DTCM

  _end = .;
  PROVIDE(__end = .);
  PROVIDE(end = .);   /* heap start for libnosys _sbrk */

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
