/// @file       <bitmanip.c>
/// @brief      Host part of the bit manipulation extension test
///
/// Calls the generated assembly self-check (bm_run) and additionally verifies
/// that the B bit is reported in the MISA CSR. Returns the number of detected
/// mismatches; the testbench treats a0 == 0 as PASS.
///
/// The latency probes in mdu_latency.S are printed too. They are informational
/// only and never contribute to the returned error count.

#include "sc_print.h"
#include "riscv_csr_encoding.h"

extern int bm_run(void);

#define LAT_ITER 1000UL

extern unsigned long latency_base  (void);
extern unsigned long latency_andn  (void);
extern unsigned long latency_mul   (void);
extern unsigned long latency_mulh  (void);
extern unsigned long latency_div   (void);
extern unsigned long latency_clmul (void);
extern unsigned long latency_clmulh(void);
extern unsigned long latency_clmulr(void);

static unsigned long lat_base;

static void report_latency(const char *name, unsigned long raw)
{
    long delta = (long)raw - (long)lat_base;

    // chain overhead cancels out, so:  raw = ITER * latency + const
    // -> latency = 1 + delta/ITER.  Report both raw numbers so nothing is lost.
    sc_printf("LATENCY %-8s raw=%lu delta=%ld  cycles/op=1+%ld.%03ld\n",
              name, raw, delta,
              delta / (long)LAT_ITER,
              ((delta % (long)LAT_ITER) * 1000L) / (long)LAT_ITER);
}

int main(void)
{
    int             errs;
    unsigned long   misa;

    errs = bm_run();

    misa = read_csr(misa);
    sc_printf("MISA = 0x%08lx\n", misa & 0xFFFFFFFFUL);

    lat_base = latency_base();
    sc_printf("LATENCY base(ADD) raw=%lu\n", lat_base);
    report_latency("andn",    latency_andn  ());
    report_latency("mul",     latency_mul   ());
    report_latency("mulh",    latency_mulh  ());
    report_latency("div",     latency_div   ());
    report_latency("clmul",   latency_clmul ());
    report_latency("clmulh",  latency_clmulh());
    report_latency("clmulr",  latency_clmulr());

    if ((misa & 0x2UL) == 0UL) {
        sc_printf("ERROR: MISA.B is not set\n");
        ++errs;
    }

    if (errs != 0) {
        sc_printf("BITMANIP TEST FAILED: %d mismatches\n", errs);
    } else {
        sc_printf("BITMANIP TEST PASSED\n");
    }

    return errs;
}
