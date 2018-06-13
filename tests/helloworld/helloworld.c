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

#define BASH_ADRS (0x00001000)
#define W_ADRS *(volatile unsigned int *) (BASH_ADRS + 0)
#define R_ADRS *(volatile unsigned int *) (BASH_ADRS + 0)

#define WRITE_REG(addr,ch)  *(volatile unsigned int *) (addr) = ch
#define READ_REG(addr,ch)  ch = *(volatile unsigned int *) (addr) 



int main (argc, argv)
int	argc;
char	*argv[];
  /* main program, corresponds to procedures        */
  /* Main and Proc_0 in the Ada version             */
{

    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");
    printf("Hello World!" "\n");

    return 0;

 



}
