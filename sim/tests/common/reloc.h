#ifndef RELOC_H
#define RELOC_H

#if (TCM == 1)
// The TCM is split into ITCM (code/rodata) and DTCM (data/bss/stack), so the
// load image is copied segment by segment: the ITCM image (text+rodata) and
// the DTCM image (data+sdata+tdata), then bss is cleared.
// The loop bound is the DESTINATION end; the source image in RAM is packed
// contiguously and has exactly the same size as the destination range.
#define RELOC_PROC                      \
    /* copy ITCM image */               \
    la    a0, __ITCM_IMAGE_START__;     \
    la    a1, __TEXT_START__;           \
    la    a2, __RODATA_END__;           \
    beq   a0, a1, 11f;                  \
    j     12f;                          \
11: lw    a3, 0(a0);                    \
    sw    a3, 0(a1);                    \
    add   a0, a0, 4;                    \
    add   a1, a1, 4;                    \
12: bne   a1, a2, 11b;                  \
    /* copy DTCM image */               \
    la    a0, __DTCM_IMAGE_START__;     \
    la    a1, __DATA_START__;           \
    la    a2, _tdata_end;               \
    beq   a0, a1, 21f;                  \
    j     22f;                          \
21: lw    a3, 0(a0);                    \
    sw    a3, 0(a1);                    \
    add   a0, a0, 4;                    \
    add   a1, a1, 4;                    \
22: bne   a1, a2, 21b;                  \
    /* clear bss */                     \
    la    a2, __BSS_START__;            \
31: la    a1, __BSS_END__;              \
    j     4f;                           \
3:  sw    zero, 0(a2);                  \
    add   a2, a2, 4;                    \
4:  bne   a1, a2, 3b;                   \
    /* init stack */                    \
    la    sp, __C_STACK_TOP__;          \
    /* init hart0 TLS */                \
    la    a0, _tdata_begin;             \
    la    a2, _tbss_end;                \
    sub   a1, a2, a0;                   \
    la    a4, __STACK_START__;          \
    sub   tp, a4, a1;
#else  // #if TCM

#define RELOC_PROC

#endif  // #else #if TCM

#endif  //
