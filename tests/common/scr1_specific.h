#ifndef __SCR1__SPECIFIC
#define __SCR1__SPECIFIC

#define mcounten        0x7E0

// Memory-mapped registers
#define mtime_ctrl      0x00500000
#define mtime_div       0x00500004
#define mtime           0x00500008
#define mtimeh          0x0050000C
#define mtimecmp        0x00500010
#define mtimecmph       0x00500014

#define SCR1_MTIME_CTRL_EN          0
#define SCR1_MTIME_CTRL_CLKSRC      1

#define SCR1_MTIME_CTRL_WR_MASK     0x3
#define SCR1_MTIME_DIV_WR_MASK      0x3FF

#endif // _SCR1__SPECIFIC
