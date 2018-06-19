/*****************************************************************************
 *
 ***************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sc_print.h"
#include "csr.h"

# define printf sc_printf

//#include "timeit.c"

#define BASE_ADRS     (0x00000000)
#define BASE_END_ADRS (0x0000ffff) 
#define REG_ADRS      (0x00010000)
#define REG_END_ADRS  (0x00010fff) 

#define GPIO_BASH_ADRS (0x00011000)
#define UART_BASH_ADRS (0x00010000)

#define DTCM_BASE_ADRS     (0x00490000)
#define DTCM_BASE_END_ADRS (0x0049ffff) 

#define ITCM_BASE_ADRS     (0x00480000)
#define ITCM_BASE_END_ADRS (0x0048ffff) 

#define WRITE_REG(addr,ch)  *(volatile unsigned int *) (addr) = ch
#define READ_REG(addr,ch)  ch = *(volatile unsigned int *) (addr) 

typedef unsigned char byte;


int main (argc, argv)
int	argc;
char	*argv[];
  /* main program, corresponds to procedures        */
  /* Main and Proc_0 in the Ada version             */
{
    unsigned int a;
    unsigned int b;
    unsigned int i;
    unsigned int limit;
    unsigned int start;

    limit = 65536-2048;
    //start = 3000*4;
    start = 0x8000; 
    //limit = start + 8000 ;

  // for (i=0; i <100; i=i+4) {
  //     WRITE_REG(BASE_ADRS +i, i);
  // }

  // for (i=0; i <100; i=i+4) {
  //     READ_REG(BASE_ADRS +i, a);
  //     if (a != i) { 
  //         printf(" mismatch \n");
  //         printf("%d != %d  \n",a,i);
  //     }else{ 
  //         printf("%d\n",a);
  //     }
  // }

 //for (i=start; i <limit; i=i+4) {
 //    WRITE_REG(ITCM_BASE_ADRS +i, 0xffffffff);
 //}
 //
for (i=start; i <limit; i=i+4) {
    WRITE_REG(DTCM_BASE_ADRS + i, 0xffffffff -i );
    WRITE_REG(ITCM_BASE_ADRS + i, 0xffffffff -i );
    READ_REG (DTCM_BASE_ADRS + i, a         );
    READ_REG (ITCM_BASE_ADRS + i, b         );
    if ((i % 1000) == 4) {
        printf ("--: %8x \n",i);
        printf ("--: %8x %8x\n",a,b);
    }
//    WRITE_REG(ITCM_BASE_ADRS +i, a);
    // printf ("finish write test\n");
}

//for (i=start; i <limit; i=i+4) {
//    READ_REG (ITCM_BASE_ADRS +i, b);
//}
//
//for (i=start; i <limit; i=i+4) {
//READ_REG (ITCM_BASE_ADRS +i , b         );
//printf ("%d\n",b);
//}



//   WRITE_REG(DTCM_BASE_ADRS +i, 0xffffffff);
//   READ_REG (DTCM_BASE_ADRS +i, b         );
////for (i=start; i <limit; i=i+4) {
  //    READ_REG(ITCM_BASE_ADRS +i, a);
  //   //if (a != i-start) { 
  //   //    //printf(" mismatch \n");
  //   //    printf(" %d != %d  \n",a,i);
  //   //    //printf("%d\n",a);
  //   //}else{ 
  //   //    printf("%d\n",a);
  //   //}
  //   //printf("%8x\n",a);
  //}
  //
//for (i =0; i< 16384; i++) {
//    printf("%d\n",i);
//}
//   
   // printf ("finish test\n");
   // printf ("hello world !!!!!!!!!!!\n");

    return 0;
  //din = a;


  //printf ("gpio_data is :");
 // printf ("%x\n",din);

}
