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
    unsigned int i;
    unsigned int limit;
    limit = 5000;

    for (i=0; i <limit; i=i+4) {
        WRITE_REG(BASE_ADRS +i, i);
    }


    printf("finish wirte test\n");

    for (i=0; i <limit; i=i+4) {
        READ_REG(BASE_ADRS +i, a);
        if (a != i) { 
            //printf(" mismatch \n");
            //printf("%d != %d  \n",a,i);
        }else{ 
            //printf("%d\n",a);
        }
    }

    printf("finish test\n");

  //din = a;


  //printf ("gpio_data is :");
 // printf ("%x\n",din);

}
