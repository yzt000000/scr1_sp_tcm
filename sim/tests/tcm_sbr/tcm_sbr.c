#include "sc_print.h"
#include <stdint.h>

#define DTCM_MAGIC    (*(volatile uint32_t *)0x00498000)
#define DTCM_ACK      (*(volatile uint32_t *)0x00498004)
#define DTCM_MAILBOX  (*(volatile uint32_t *)0x00498008)
#define DTCM_LOADED   (*(volatile uint32_t *)0x00498010)
#define ITCM_DATA     (*(volatile uint32_t *)0x0048F000)
#define ITCM_LOADED   (*(volatile uint32_t *)0x0048F004)

int main(void)
{
    uint32_t v;
    int i;

    v = DTCM_MAGIC;
    if (v != 0xDEADBEEFu) {
        sc_printf("TCM_SBR FAIL: DTCM magic = %x\n", v);
        return 1;
    }

    v = ITCM_DATA;
    if (v != 0x5A5AA5A5u) {
        sc_printf("TCM_SBR FAIL: ITCM data = %x\n", v);
        return 2;
    }

    v = DTCM_LOADED;
    if (v == 0x11223344u) {
        v = ITCM_LOADED;
        if (v != 0x56781234u) {
            sc_printf("TCM_SBR FAIL: loaded ITCM word = %x\n", v);
            return 3;
        }
    } else if (v != 0u) {
        sc_printf("TCM_SBR FAIL: DTCM loaded word = %x\n", v);
        return 4;
    }

    DTCM_ACK = 0x12345678u;

    v = 0;
    for (i = 0; i < 10000000; i++) {
        v = DTCM_MAILBOX;
        if (v == 0xCAFEBABEu) {
            break;
        }
    }
    if (v != 0xCAFEBABEu) {
        sc_printf("TCM_SBR FAIL: mailbox timeout (%x)\n", v);
        return 5;
    }

    sc_printf("TCM_SBR PASS\n");
    return 0;
}