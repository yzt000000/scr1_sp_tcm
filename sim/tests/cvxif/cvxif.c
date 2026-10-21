/// @file       <cvxif.c>
/// @brief      Host part of the CV-X-IF custom extension test
///
/// Calls the assembly self-check (cvxif_run) and verifies that the X bit
/// is reported in the MISA CSR. Returns the number of detected mismatches;
/// the testbench treats a0 == 0 as PASS.

#include "sc_print.h"
#include "riscv_csr_encoding.h"

extern int cvxif_run(void);

int main(void)
{
    int             errs;
    unsigned long   misa;

    sc_printf("=== CV-X-IF Custom Extension Test ===\n");

    errs = cvxif_run();

    misa = read_csr(misa);
    sc_printf("MISA = 0x%08lx\n", misa & 0xFFFFFFFFUL);

    if (misa & 0x00800000UL) {
        sc_printf("MISA.X (bit 23) = 1 - custom extension reported\n");
    } else {
        sc_printf("MISA.X (bit 23) = 0 - custom extension NOT reported\n");
        errs++;
    }

    if (errs == 0) {
        sc_printf("CV-X-IF test: PASS\n");
    } else {
        sc_printf("CV-X-IF test: FAIL (%d errors)\n", errs);
    }

    return errs;
}