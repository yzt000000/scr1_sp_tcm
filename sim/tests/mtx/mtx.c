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
extern int mtx_run_cfg(int a_base, int b_base, int c_base, int stride, int msk);

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

    // ---- Case 2: non-identity signed matrices, stride = 4 ----
    {
        static const int a2_init[16] = {
             1,  -2,   3,   0,
             4,   5,  -6,   1,
            -7,   8,   9,  -1,
             2,  -3,   4,   5
        };
        static const int b2_init[16] = {
             2,   0,  -1,   3,
             1,   4,   0,  -2,
            -3,   1,   5,   0,
             0,  -4,   2,   1
        };
        int a2[16], b2[16], c2[16];
        int exp2[16];
        int r, c_i, rr;

        for (i = 0; i < 16; i++) {
            a2[i] = a2_init[i];
            b2[i] = b2_init[i];
            c2[i] = 0;
        }
        for (r = 0; r < 4; r++) {
            for (c_i = 0; c_i < 4; c_i++) {
                int acc = 0;
                for (rr = 0; rr < 4; rr++) {
                    acc += a2[r * 4 + rr] * b2[rr * 4 + c_i];
                }
                exp2[r * 4 + c_i] = acc;
            }
        }

        status = mtx_run_cfg((int)a2, (int)b2, (int)c2, 4, 1);
        if (status != 0) {
            sc_printf("case2 mtx_run_cfg error\n");
            errs++;
        }
        for (i = 0; i < 16; i++) {
            if (c2[i] != exp2[i]) {
                sc_printf("case2 C mismatch\n");
                errs++;
                break;
            }
        }
    }

    // ---- Case 3: unsigned mode (msk = 0), stride = 4 ----
    {
        // Values chosen so the signed and unsigned products differ:
        // 0xFFFFFFFC as unsigned is 4, as signed it is -4
        static const unsigned int a3_init[16] = {
            0xFFFFFFFCu, 2, 0, 1,
            3, 0xFFFFFFFDu, 1, 0,
            0, 1, 0xFFFFFFFEu, 2,
            1, 0, 3, 0xFFFFFFFBu
        };
        static const unsigned int b3_init[16] = {
            2, 0, 1, 0xFFFFFFFCu,
            1, 3, 0, 2,
            0xFFFFFFFEu, 1, 2, 0,
            0, 0xFFFFFFFDu, 1, 1
        };
        unsigned int a3[16], b3[16], c3[16];
        unsigned int exp3[16];
        int r, c_i, rr;

        for (i = 0; i < 16; i++) {
            a3[i] = a3_init[i];
            b3[i] = b3_init[i];
            c3[i] = 0;
        }
        for (r = 0; r < 4; r++) {
            for (c_i = 0; c_i < 4; c_i++) {
                unsigned int acc = 0;
                for (rr = 0; rr < 4; rr++) {
                    acc += a3[r * 4 + rr] * b3[rr * 4 + c_i];
                }
                exp3[r * 4 + c_i] = acc;
            }
        }

        status = mtx_run_cfg((int)a3, (int)b3, (int)c3, 4, 0);
        if (status != 0) {
            sc_printf("case3 mtx_run_cfg error\n");
            errs++;
        }
        for (i = 0; i < 16; i++) {
            if (c3[i] != exp3[i]) {
                sc_printf("case3 C mismatch\n");
                errs++;
                break;
            }
        }
    }

    // ---- Case 4: stride = 8 (rows of B are 8 elements apart) ----
    {
        static const int a4_init[16] = {
            1, 2, 3, 4,
            5, 6, 7, 8,
            9, 10, 11, 12,
            13, 14, 15, 16
        };
        int a4[16], b4[32], c4[16];
        int exp4[16];
        int r, c_i, rr;

        for (i = 0; i < 16; i++) {
            a4[i] = a4_init[i];
            c4[i] = 0;
        }
        for (i = 0; i < 32; i++) {
            b4[i] = 0;
        }
        // B rows placed at offsets 0, 8, 16, 24 (stride = 8)
        b4[0] = 1;  b4[1] = 0;  b4[2] = 2;  b4[3] = 1;
        b4[8] = 0;  b4[9] = 1;  b4[10] = 1; b4[11] = 0;
        b4[16] = 3; b4[17] = 0; b4[18] = 1; b4[19] = 2;
        b4[24] = 1; b4[25] = 2; b4[26] = 0; b4[27] = 1;

        for (r = 0; r < 4; r++) {
            for (c_i = 0; c_i < 4; c_i++) {
                int acc = 0;
                for (rr = 0; rr < 4; rr++) {
                    acc += a4[r * 4 + rr] * b4[rr * 8 + c_i];
                }
                exp4[r * 4 + c_i] = acc;
            }
        }

        status = mtx_run_cfg((int)a4, (int)b4, (int)c4, 8, 1);
        if (status != 0) {
            sc_printf("case4 mtx_run_cfg error\n");
            errs++;
        }
        for (i = 0; i < 16; i++) {
            if (c4[i] != exp4[i]) {
                sc_printf("case4 C mismatch\n");
                errs++;
                break;
            }
        }
    }

    if (errs == 0) {
        sc_printf("MTX test: PASS\n");
    } else {
        sc_printf("MTX test: FAIL\n");
    }

    return errs;
}