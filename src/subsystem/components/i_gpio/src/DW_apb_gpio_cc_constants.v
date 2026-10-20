/*
------------------------------------------------------------------------
--
//  ------------------------------------------------------------------------
//
//                    (C) COPYRIGHT 2013 - 2016 SYNOPSYS, INC.
//                            ALL RIGHTS RESERVED
//
//  This software and the associated documentation are confidential and
//  proprietary to Synopsys, Inc.  Your use or disclosure of this
//  software is subject to the terms and conditions of a written
//  license agreement between you, or your company, and Synopsys, Inc.
//
// The entire notice above must be reproduced on all authorized copies.
//
//  ------------------------------------------------------------------------

// 
// Release version :  2.12a
// File Version     :        $Revision: #20 $ 
// Revision: $Id: //dwh/DW_ocb/DW_apb_gpio/amba_dev/src/DW_apb_gpio_cc_constants.v#20 $ 
--
-- File :                       DW_apb_gpio_cc_constants.v
//
//
-- Date :                       $Date: 2016/08/26 $
-- Abstract     :               cC constants for DW_apb_gpio
--
------------------------------------------------------------------------
*/


// Name:         GPIO_ADD_ENCODED_PARAMS
// Default:      true
// Values:       false (0x0), true (0x1)
// 
// Adds the encoded parameters that provides the firmware an easy and quick way of identifying the DesignWare component 
// within an I/O memory map. Some critical design-time options determine how a driver must interact with the peripheral. There 
// is a minimal area overhead when you include these parameters. Additionally, this option allows a self-configurable single 
// driver to be developed for each component.
`define GPIO_ADD_ENCODED_PARAMS 1'h1


// Name:         APB_DATA_WIDTH
// Default:      32
// Values:       8 16 32
// 
// Specifies the width of APB Data Bus to which this component is attached.
`define APB_DATA_WIDTH 32


// Name:         GPIO_NUM_PORTS
// Default:      4
// Values:       1 2 3 4
// 
// Selects the number of ports supported.
`define GPIO_NUM_PORTS 1


// Name:         GPIO_ID
// Default:      Include
// Values:       Exclude (0x0), Include (0x1)
// 
// Includes/Excludes the DW_apb_gpio ID register. If set to Include, provides an ID code value (set with GPIO_ID_NUM) that 
// the system can read.
`define GPIO_ID 1'h1


// Name:         GPIO_ID_WIDTH
// Default:      32
// Values:       1, ..., 32
// Enabled:      GPIO_ID == 1
// 
// Specifies the GPIO ID register width. The width of the identification code that is configured in GPIO_ID_NUM.
`define GPIO_ID_WIDTH 32


`define POW_2_GPIO_ID_WIDTH 32'hffffffff


// Name:         GPIO_ID_NUM
// Default:      0x0
// Values:       0x0, ..., POW_2_GPIO_ID_WIDTH
// Enabled:      GPIO_ID == 1
// 
// Specifies the GPIO ID Value. The ID code value that the system reads back when the device identification is present.
`define GPIO_ID_NUM 32'h0

//Include/Exclude Revision ID register.
//Specifies if a GPIO Revision ID register is instantiated.

`define GPIO_REV_ID 0

//GPIO Revision ID Register Width.
//Stores the width of the GPIO Revision ID register.

`define GPIO_REV_ID_WIDTH 32

//GPIO Revision ID Value. 
//Stores the GPIO Revision ID value.

`define GPIO_REV_ID_NUM 32'h0


// Name:         GPIO_PWIDTH_A
// Default:      8
// Values:       1, ..., 32
// 
// This parameter configures the width of Port A.
`define GPIO_PWIDTH_A 8


// Name:         GPIO_HW_PORTA
// Default:      Exclude
// Values:       Exclude (0x0), Include (0x1)
// 
// Port A can be configured with this parameter to have external, auxiliary hardware signals controlling the data and the 
// direction of Port A rather than the software. If set to 0, the functionality for the hardware/software multiplexing is not 
// implemented.
`define GPIO_HW_PORTA 1'h0


// Name:         GPIO_PORTA_SINGLE_CTL
// Default:      true
// Values:       false (0x0), true (0x1)
// Enabled:      GPIO_HW_PORTA==1
// 
// Specifies the Port A hardware/software control. If set, all bits of Port A are either entirely under software control 
// (if Port A Auxiliary H/W is excluded) or entirely under hardware control (if Port A Auxiliary H/W is included). If this 
// parameter is not set, the "gpio_sw_porta" register determines which bits of the port are under hardware control and which are 
// under software control.
`define GPIO_PORTA_SINGLE_CTL 1'h1


// Name:         GPIO_DFLT_DIR_A
// Default:      Input
// Values:       Input (0), Output (1)
// 
// This parameter configures the default direction of Port A after power-on reset.
`define GPIO_DFLT_DIR_A 0


// Name:         GPIO_DFLT_SRC_A
// Default:      S/W
// Values:       S/W (0), H/W (1)
// Enabled:      GPIO_HW_PORTA == 1
// 
// This parameter sets the default mode of Port A after a Power-On-Reset to either software or hardware.
`define GPIO_DFLT_SRC_A 0


// Name:         GPIO_DEBOUNCE
// Default:      Exclude
// Values:       Exclude (0x0), Include (0x1)
// Enabled:      GPIO_PORTA_INTR == 1
// 
// Includes the Debounce logic and includes the capability of debouncing interrupts using an external slow clock.
`define GPIO_DEBOUNCE 1'h0


// Name:         GPIO_PORTA_INTR
// Default:      Include
// Values:       Exclude (0x0), Include (0x1)
// 
// If Port A is required to be used as an interrupt source, then set this parameter to 1.
`define GPIO_PORTA_INTR 1'h1



// Name:         GPIO_INT_POL
// Default:      Active Low
// Values:       Active Low (0), Active High (1)
// Enabled:      GPIO_PORTA_INTR == 1
// 
// Sets the polarity on the output of Port A. The single combined interrupt and the separate individual interrupts share a 
// common polarity.
`define GPIO_INT_POL 0


// Name:         GPIO_INTR_IO
// Default:      false
// Values:       false (0), true (1)
// Enabled:      GPIO_PORTA_INTR == 1
// 
// Specifies that Port A can be configured to generate multiple interrupt signals or a single combined interrupt flag. When 
// set to 1, the component generates a single combined interrupt flag.
`define GPIO_INTR_IO 0


// Name:         GPIO_PA_SYNC_EXT_DATA
// Default:      Exclude
// Values:       Exclude (0), Include (1)
// 
// This parameter controls the inclusion of metastability registers on the read back path when reading the external input 
// signal gpio_ext_porta from the gpio_ext_porta memory-mapped registers.
`define GPIO_PA_SYNC_EXT_DATA 0


`define POW_2_GPIO_PWIDTH_A 32'hff


// Name:         GPIO_SWPORTA_RESET
// Default:      0x0 ({multi} {GPIO_PWIDTH_A} {0b0} )
// Values:       0x0, ..., 0xff
// 
// Specifies the Power-on-Reset value of Port A Software Register gpio_swporta.
`define GPIO_SWPORTA_RESET 8'h0


// Name:         GPIO_PA_SYNC_INTERRUPTS
// Default:      Include
// Values:       Exclude (0), Include (1)
// 
// Synchronizes Port A interrupts. If set, metastability flip-flops for Port A interrupts are instantiated as part of the 
// component. Otherwise, metastability flip-flops are not instantiated, and it is assumed that interrupt synchronization is 
// taken care outside of the component.
`define GPIO_PA_SYNC_INTERRUPTS 1


// Name:         GPIO_INT_BOTH_EDGE
// Default:      Exclude
// Values:       Exclude (0), Include (1)
// Enabled:      GPIO_PORTA_INTR == 1
// 
// If Port A is required to generate interrupt on both rising and falling edges of the external input signal, then set this 
// parameter to 1.
`define GPIO_INT_BOTH_EDGE 0


// Name:         GPIO_PWIDTH_B
// Default:      8
// Values:       1, ..., 32
// Enabled:      GPIO_NUM_PORTS > 1
// 
// This parameter configures the width of Port B.
`define GPIO_PWIDTH_B 8


// Name:         GPIO_HW_PORTB
// Default:      Exclude
// Values:       Exclude (0x0), Include (0x1)
// Enabled:      GPIO_NUM_PORTS > 1
// 
// Indicates Port B Auxiliary H/W support. When set to 1, Port B has external, auxiliary hardware signals controlling the 
// data and the direction of Port B rather than the software. If set to 0, then the functionality for the hardware-software 
// multiplexing is not implemented.
`define GPIO_HW_PORTB 1'h0


// Name:         GPIO_PORTB_SINGLE_CTL
// Default:      true
// Values:       false (0x0), true (0x1)
// Enabled:      GPIO_HW_PORTB==1 && GPIO_NUM_PORTS>1
// 
// Indicates Port B Hardware/Software control. If set, all bits of Port B are either entirely under software control (if 
// Port B Auxiliary H/W is excluded) or entirely under hardware control (if Port B Auxiliary H/W is included). If this 
// parameter is not set, then the "gpio_sw_portb" register determines which bits of the port are under hardware control and which are 
// under software control.
`define GPIO_PORTB_SINGLE_CTL 1'h1


// Name:         GPIO_DFLT_DIR_B
// Default:      Input
// Values:       Input (0), Output (1)
// Enabled:      GPIO_NUM_PORTS > 1
// 
// This parameter sets the default direction of Port B after Power-on-Reset.
`define GPIO_DFLT_DIR_B 0


// Name:         GPIO_DFLT_SRC_B
// Default:      S/W
// Values:       S/W (0), H/W (1)
// Enabled:      GPIO_NUM_PORTS > 1 && GPIO_HW_PORTB == 1
// 
// Indicates default mode if the auxiliary H/W is supported on port B. The default source of the input data, the output 
// data, and the control of Port B are configurable. This parameter sets the reset value of the gpio_portb_ctl register.
`define GPIO_DFLT_SRC_B 0


// Name:         GPIO_PB_SYNC_EXT_DATA
// Default:      Exclude
// Values:       Exclude (0), Include (1)
// Enabled:      GPIO_NUM_PORTS > 1
// 
// This parameter controls the inclusion of metastability registers on the read back path when reading the external input 
// signal gpio_ext_portb from the gpio_ext_portb memory-mapped registers.
`define GPIO_PB_SYNC_EXT_DATA 0


`define POW_2_GPIO_PWIDTH_B 32'hff


// Name:         GPIO_SWPORTB_RESET
// Default:      0x0 ({multi} {GPIO_PWIDTH_B} {0b0} )
// Values:       0x0, ..., 0xff
// Enabled:      GPIO_NUM_PORTS > 1
// 
// Indicates the Power-on-Reset value of Port B Software Register.  This is the reset value of the gpio_swportb register.
`define GPIO_SWPORTB_RESET 8'h0


// Name:         GPIO_PWIDTH_C
// Default:      8
// Values:       1, ..., 32
// Enabled:      GPIO_NUM_PORTS > 2
// 
// This parameter sets the width of Port C.
`define GPIO_PWIDTH_C 8


// Name:         GPIO_HW_PORTC
// Default:      Exclude
// Values:       Exclude (0x0), Include (0x1)
// Enabled:      GPIO_NUM_PORTS > 2
// 
// Indicates the Port C Auxiliary H/W Support. When set to 1, Port C has external, auxiliary hardware signals controlling 
// the data and the direction of Port C, rather than the software. If set to 0, then the functionality for the 
// hardware-software multiplexing is not implemented.
`define GPIO_HW_PORTC 1'h0


// Name:         GPIO_PORTC_SINGLE_CTL
// Default:      true
// Values:       false (0x0), true (0x1)
// Enabled:      GPIO_HW_PORTC==1 && GPIO_NUM_PORTS > 2
// 
// Indicates Port C Hardware/Software Control. If set, all bits of Port C are either entirely under software control (if 
// Port C Auxiliary H/W is excluded) or entirely under hardware control (if Port C Auxiliary H/W is included). If this 
// parameter is not set, then the "gpio_sw_portc" register determines which bits of the port are under hardware control and which are 
// under software control.
`define GPIO_PORTC_SINGLE_CTL 1'h1


// Name:         GPIO_DFLT_DIR_C
// Default:      Input
// Values:       Input (0), Output (1)
// Enabled:      GPIO_NUM_PORTS > 2
// 
// This parameter sets the default direction of Port C after Power-on-Reset.
`define GPIO_DFLT_DIR_C 0


// Name:         GPIO_DFLT_SRC_C
// Default:      S/W
// Values:       S/W (0), H/W (1)
// Enabled:      GPIO_NUM_PORTS > 2 && GPIO_HW_PORTC == 1
// 
// Indicates default mode if auxiliary H/W supported on port C. The default source of the input data, the output data, and 
// the control of Port C are configurable. This parameter sets the reset value of the gpio_portc_ctl register. 
// Power On Reset to either S/W or H/W.
`define GPIO_DFLT_SRC_C 0


// Name:         GPIO_PC_SYNC_EXT_DATA
// Default:      Exclude
// Values:       Exclude (0), Include (1)
// Enabled:      GPIO_NUM_PORTS > 2
// 
// Indicates Port C Read Back Data Synchronization. This parameter controls inclusion of metastability registers on the 
// read back path when reading the external input signal gpio_ext_portc from the gpio_ext_portc memory-mapped registers.
`define GPIO_PC_SYNC_EXT_DATA 0


`define POW_2_GPIO_PWIDTH_C 32'hff


// Name:         GPIO_SWPORTC_RESET
// Default:      0x0 ({multi} {GPIO_PWIDTH_C} {0b0} )
// Values:       0x0, ..., 0xff
// Enabled:      GPIO_NUM_PORTS > 2
// 
// Indicates Power-on-Reset value of the Port C Software Register. This is the reset value of the gpio_swportc register.
`define GPIO_SWPORTC_RESET 8'h0


// Name:         GPIO_PWIDTH_D
// Default:      8
// Values:       1, ..., 32
// Enabled:      GPIO_NUM_PORTS > 3
// 
// This parameter configures the width of Port D.
`define GPIO_PWIDTH_D 8


// Name:         GPIO_HW_PORTD
// Default:      Exclude
// Values:       Exclude (0x0), Include (0x1)
// Enabled:      GPIO_NUM_PORTS > 3
// 
// Indicates Port D Auxiliary H/W Support. When set to 1, Port D has external, auxiliary hardware signals controlling the 
// data and the direction of Port D, rather than software. If set to 0, then the functionality for the hardware-software 
// multiplexing is not implemented.
`define GPIO_HW_PORTD 1'h0


// Name:         GPIO_PORTD_SINGLE_CTL
// Default:      true
// Values:       false (0x0), true (0x1)
// Enabled:      GPIO_HW_PORTD==1 && GPIO_NUM_PORTS > 3
// 
// Indicates Port D Hardware/Software Control. If set, all bits of Port D are either entirely under software control (if 
// Port D Auxiliary H/W is excluded) or entirely under hardware control (if Port C Auxiliary H/W is included). If this 
// parameter is not set, then the "gpio_sw_portd" register determines which bits of the port are under hardware control and which are 
// under software control.
`define GPIO_PORTD_SINGLE_CTL 1'h1


// Name:         GPIO_DFLT_DIR_D
// Default:      Input
// Values:       Input (0), Output (1)
// Enabled:      GPIO_NUM_PORTS > 3
// 
// This parameter sets the default direction of Port D after Power On Reset.
`define GPIO_DFLT_DIR_D 0


// Name:         GPIO_DFLT_SRC_D
// Default:      S/W
// Values:       S/W (0), H/W (1)
// Enabled:      GPIO_NUM_PORTS > 3 && GPIO_HW_PORTD == 1
// 
// Indicates the default mode if auxiliary H/W is supported on port D. The default source of the input data, the output 
// data, and the control of Port D are configurable. This parameter sets the reset value of the gpio_portd_ctl register.
`define GPIO_DFLT_SRC_D 0


// Name:         GPIO_PD_SYNC_EXT_DATA
// Default:      Exclude
// Values:       Exclude (0), Include (1)
// Enabled:      GPIO_NUM_PORTS > 3
// 
// Indicates the Port D Read Back Data Synchronization. This parameter controls the inclusion of metastability registers on 
// the read back path when reading the gpio_ext_portd external input signal from the gpio_ext_portd memory-mapped registers.
`define GPIO_PD_SYNC_EXT_DATA 0


`define POW_2_GPIO_PWIDTH_D 32'hff


// Name:         GPIO_SWPORTD_RESET
// Default:      0x0 ({multi} {GPIO_PWIDTH_D} {0b0} )
// Values:       0x0, ..., 0xff
// Enabled:      GPIO_NUM_PORTS > 3
// 
// Indicates Power-on-Reset value of Port D Software Register. This is the reset value of the gpio_swportd register.
`define GPIO_SWPORTD_RESET 8'h0


`define GPIO_RDATA_WIDTH 32


`define GPIO_ADDR_SLICE_RHS 2


`define GPIO_ADDR_SLICE_LHS 6


`define MAX_APB_DATA_WIDTH 32


`define GPIO_LS_SYNC_WIDTH 1


`define GPIO_CTL_WIDTH_A 1


`define GPIO_CTL_WIDTH_B 1


`define GPIO_CTL_WIDTH_C 1


`define GPIO_CTL_WIDTH_D 1


`define GPIO_INDIVIDUAL 0


`define GPIO_COMBINED 1


//Each corekit has a version number.
//This is relected in the ascii version number which needs to get translated.
// 0 => 48 -> 30
// 1 => 49 -> 31
// 2 => 50 -> 32
// A => 65 -> 41
// B => 66 -> 42
// C => 67 -> 43
//
//Current Version is 2.12* => 32_30_32_2A
//

`define GPIO_VERSION_ID 32'h3231322a

//Set this parameter to true (1)
//if you want the gpio_ext_portX registers
//to read back the internal gpio_swportX_drN
//registers when the port is configured as an
//output (X= A,B,C or D) (N=0..31)
//With this parameter set to false (0),
//the gpio_ext_portX registers will always reflect
//the states of the corresponding component I/O ports.
//Setting this parameter to true (1) means that the
//gpio_ext_portX registers have the same functionality
//as in version 2.01A and earlier coreKits.

`define GPIO_PORTX_READBACK_MUX 0


`define GPIO_ENCODED_APB_WIDTH 2'h2


`define GPIO_ENCODED_PWIDTH_A 5'h7


`define GPIO_ENCODED_PWIDTH_B 5'h7


`define GPIO_ENCODED_PWIDTH_C 5'h7


`define GPIO_ENCODED_PWIDTH_D 5'h7


`define GPIO_ENCODED_ID_WIDTH 5'h1f


`define GPIO_ENCODED_NUM_PORTS 2'h0

//Catch gpio_porta_ctl reset value 

`define GPIO_DFLT_SRC_RESET_A 32'h0

//Catch gpio_portb_ctl reset value 

`define GPIO_DFLT_SRC_RESET_B 32'h0

//Catch gpio_portc_ctl reset value 

`define GPIO_DFLT_SRC_RESET_C 32'h0

//Catch gpio_portd_ctl reset value 

`define GPIO_DFLT_SRC_RESET_D 32'h0

//Catch gpio_configid_reg2 reset

`define GPIO_CID_REG2 32'h39ce7

//Catch gpio_configid_reg2 reset value

`define GPIO_CID_RESET_REG2 32'h39ce7

//Move SymbolicNames to logic value

`define GPIO_L_ID 1'h1

`define GPIO_L_HW_PORTA 1'h0

`define GPIO_L_HW_PORTB 1'h0

`define GPIO_L_HW_PORTC 1'h0

`define GPIO_L_HW_PORTD 1'h0

`define GPIO_L_PORTA_INTR 1'h1

`define GPIO_L_DEBOUNCE 1'h0

`define PORTD_SINGLE_CTL 1'h1

`define PORTC_SINGLE_CTL 1'h1

`define PORTB_SINGLE_CTL 1'h1

`define PORTA_SINGLE_CTL 1'h1

`define PORTA_INT_BOTHEDGE 1'h0

//Catch gpio_configid_reg1 reset

`define GPIO_CID_REG1 32'h1fd0f2

//Catch gpio_configid_reg1 reset value

`define GPIO_CID_RESET_REG1 32'h1fd0f2



// `define GPIO_ENCRYPT



`define GPIO_SWPORTA_CTL_REG_SIZE 1


`define GPIO_SWPORTB_CTL_REG_SIZE 1


`define GPIO_SWPORTC_CTL_REG_SIZE 1


`define GPIO_SWPORTD_CTL_REG_SIZE 1

