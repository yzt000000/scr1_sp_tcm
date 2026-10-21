/// @file       <mtx.c>
/// @brief      Matrix Multiply extension test - host part
///
/// Uses LINKER-ALLOCATED global arrays (not hardcoded addresses!) for the
/// matrices: a hardcoded base like 0x00490000 can collide with .data
/// objects the linker places there (e.g. __emutls descriptors), corrupting
/// them and crashing later sc_printf TLS lookups.
///
/// NOTE: sc_printf with %d is avoided - the %d path uses the emutls-backed
/// putchar buffer and is fragile on this bare-metal crt.

#include "sc_print.h"
#include "riscv_csr_encoding.h"

static int a_arr[16];
static int b_arr[16];
static int c_arr[16];

static const int b_init[16] = {
    1,  2,  3,  4,
    5,  6,  7,  8,
    9,  10, 11, 12,
    13, 14, 15, 16
};

static const int c_expect[16] = {
    1,  2,  3,  4,
    5,  6,  7,  8,
    9,  10, 11, 12,
    13, 14, 15, 16
};

extern int mtx_run(int a_base, int b_base, int c_base);

int main(void)
{
    int errs, status, i;

    sc_printf("=== Matrix Multiply Extension Test ===\n");

    for (i = 0; i < 16; i++) {
        a_arr[i] = 0;
        b_arr[i] = b_init[i];
        c_arr[i] = 0;
    }
    a_arr[0]  = 1; a_arr[5]  = 1; a_arr[10] = 1; a_arr[15] = 1;

    status = mtx_run((int)a_arr, (int)b_arr, (int)c_arr);
    if (status != 0) {
        sc_printf("mtx_run returned error\n");
        return 1;
    }

    errs = 0;
    for (i = 0; i < 16; i++) {
        if (c_arr[i] != c_expect[i]) {
            sc_printf("C mismatch\n");
            errs++;
        }
    }

    if (errs == 0) {
        sc_printf("MTX test: PASS\n");
    } else {
        sc_printf("MTX test: FAIL\n");
    }

    return errs;
}