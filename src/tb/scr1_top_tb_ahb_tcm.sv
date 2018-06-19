/// Copyright by Syntacore LLC © 2016-2018. See LICENSE for details
/// @file       <scr1_top_tb_ahb.sv>
/// @brief      SCR1 top testbench AHB
///

`include "scr1_arch_description.svh"
`include "scr1_ahb.svh"
`ifdef SCR1_IPIC_EN
`include "scr1_ipic.svh"
`endif // SCR1_IPIC_EN

module scr1_top_tb_ahb ();

//-------------------------------------------------------------------------------
// Local parameters
//-------------------------------------------------------------------------------
localparam                          SCR1_MEM_POWER_SIZE = 24;
`ifdef NORMAL_BOOTUP
localparam logic [`SCR1_XLEN-1:0]   SCR1_EXIT_ADDR      = 32'h000000F8;
`else
localparam logic [`SCR1_XLEN-1:0]   SCR1_EXIT_ADDR      = 32'h004800F8;
`endif
//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
logic                                   rst_n;
logic                                   clk         = 1'b0;
logic                                   rtc_clk     = 1'b0;
`ifdef SCR1_IPIC_EN
logic [SCR1_IRQ_LINES_NUM-1:0]          irq_lines;
`else // SCR1_IPIC_EN
logic                                   ext_irq     = 1'b0;
`endif // SCR1_IPIC_EN
logic                                   soft_irq    = 1'b0;
logic [31:0]                            fuse_mhartid;
integer                                 imem_req_ack_stall;
integer                                 dmem_req_ack_stall;

logic                                   test_mode = 1'b0;
`ifdef SCR1_DBGC_EN
logic                                   trst_n;
logic                                   tck;
logic                                   tms;
logic                                   tdi;
logic                                   tdo;
logic                                   tdo_en;
`endif // SCR1_DBGC_EN

// Instruction Memory Interface
logic   [3:0]                           imem_hprot;
logic   [2:0]                           imem_hburst;
logic   [2:0]                           imem_hsize;
logic   [1:0]                           imem_htrans;
logic                                   imem_hmastlock;
logic   [SCR1_AHB_WIDTH-1:0]            imem_haddr;
logic                                   imem_hready;
logic   [SCR1_AHB_WIDTH-1:0]            imem_hrdata;
logic                                   imem_hresp;

// Data Memory Interface
logic   [3:0]                           dmem_hprot;
logic   [2:0]                           dmem_hburst;
logic   [2:0]                           dmem_hsize;
logic   [1:0]                           dmem_htrans;
logic                                   dmem_hmastlock;
logic   [SCR1_AHB_WIDTH-1:0]            dmem_haddr;
logic                                   dmem_hwrite;
logic   [SCR1_AHB_WIDTH-1:0]            dmem_hwdata;
logic                                   dmem_hready;
logic   [SCR1_AHB_WIDTH-1:0]            dmem_hrdata;
logic                                   dmem_hresp;

int unsigned                            f_results;
string                                  s_results;
int unsigned                            f_info;
string                                  s_info;

int unsigned                            imem_req_f;
int unsigned                            dmem_req_f;


int unsigned                            ft_info;
string                                  tcm_info;

int unsigned                            fit_info;
string                                  itcm_info;

int unsigned                            fdt_info;
string                                  dtcm_info;

int unsigned                            tests_passed;
int unsigned                            tests_total;


always #5   clk     = ~clk;         // 100 MHz
always #500 rtc_clk = ~rtc_clk;     // 1 MHz

task reset();
    rst_n       = 0;
    #1 rst_n    = 1;
endtask

`ifdef SCR1_DBGC_EN
initial begin
    trst_n  = 1'b0;
    tck     = 1'b0;
    tdi     = 1'b0;
    #900ns trst_n   = 1'b1;
    #500ns tms      = 1'b1;
    #800ns tms      = 1'b0;
    #500ns trst_n   = 1'b0;
    #100ns tms      = 1'b1;
end
`endif // SCR1_DBGC_EN

//-------------------------------------------------------------------------------
// Run tests
//-------------------------------------------------------------------------------
//  initial begin
//    $vcdplusfile("test.vpd") ;
//    $vcdpluson(0,scr1_top_tb_ahb);
//  end
//  


initial begin
    $value$plusargs("imem_pattern=%h", imem_req_ack_stall);
    $value$plusargs("dmem_pattern=%h", dmem_req_ack_stall);
    $value$plusargs("test_info=%s", s_info);
    $value$plusargs("tcm_info=%s", tcm_info);
    $value$plusargs("itcm_info=%s", itcm_info);
    $value$plusargs("dtcm_info=%s", dtcm_info);
    $value$plusargs("test_results=%s", s_results);

    fuse_mhartid        = 0;
    rst_n               = 1;

    f_info      = $fopen(s_info, "r");
    f_results   = $fopen(s_results, "a");
    ft_info     = $fopen(tcm_info,"r");
    fit_info     = $fopen(itcm_info,"r");
    fdt_info     = $fopen(dtcm_info,"r");
    imem_req_f   = $fopen("imem_req.txt","w");
    dmem_req_f   = $fopen("dmem_req.txt","w");
  
    forever begin
        if ($feof(f_info)) break;
        $fscanf(f_info, "%s\n", i_memory_tb.stuff_file);
        if ($feof(ft_info)) break;
        //$fscanf(ft_info, "%s\n", i_top.i_tcm.scr1_itcm.stuff_file);
        if ($feof(fit_info)) break;
        $fscanf(fit_info, "%s\n", i_top.i_tcm.scr1_itcm.stuff_file);
        if ($feof(fdt_info)) break;
        $fscanf(fdt_info, "%s\n", i_top.i_tcm.scr1_dtcm.stuff_file);

        i_top.i_core_top.i_pipe_top.i_tracelog.test_name = i_memory_tb.stuff_file;
        $write("\033[0;34m---Test: %s\033[0m\n", i_memory_tb.stuff_file);
        reset();
        forever begin
            @(posedge clk)
            if (i_top.i_core_top.i_pipe_top.curr_pc == SCR1_EXIT_ADDR) begin
                bit test_pass;
                test_pass = (i_top.i_core_top.i_pipe_top.i_pipe_mprf.mprf_int[10] == 0);
                tests_total     += 1;
                tests_passed    += test_pass;
                $fwrite(f_results, "%s\t\t%s\n", i_memory_tb.stuff_file, (test_pass ? "PASS" : "__FAIL"));
                if (test_pass) $write("\033[0;32mTest passed\033[0m\n");
                else $write("\033[0;31mTest failed\033[0m\n");
                break;
            end
            $fwrite (imem_req_f, "%h ,%h ,%h ,%h ,%h\n",i_top.i_tcm.imem_req, i_top.i_tcm.imem_cmd, i_top.i_tcm.imem_addr, i_top.i_tcm.imem_rdata, i_top.i_tcm.imem_rdata);
            $fwrite (dmem_req_f, "%h ,%h ,%h ,%h ,%h\n",i_top.i_tcm.dmem_req, i_top.i_tcm.dmem_cmd, i_top.i_tcm.dmem_addr, i_top.i_tcm.dmem_wdata, i_top.i_tcm.dmem_rdata);

        end
    end
    $display("\n#--------------------------------------");
    $display("# Summary: %0d/%0d tests passed", tests_passed, tests_total);
    $display("#--------------------------------------\n");
    $fclose(f_info);
    $fclose(f_results);
    $finish();
end

//-------------------------------------------------------------------------------
// Core instance
//-------------------------------------------------------------------------------
scr1_top_ahb i_top (
    // Control
    .rst_n              (rst_n          ),
    .test_mode          (test_mode      ),
    .clk                (clk            ),
    .rtc_clk            (rtc_clk        ),
    .rst_n_out          (               ),
    .fuse_mhartid       (fuse_mhartid   ),
`ifdef SCR1_IPIC_EN
    .irq_lines          (irq_lines      ),
`else // SCR1_IPIC_EN
    .ext_irq            (ext_irq        ),
`endif // SCR1_IPIC_EN
    .soft_irq           (soft_irq       ),
`ifdef SCR1_DBGC_EN
    .trst_n             (trst_n         ),
    .tck                (tck            ),
    .tms                (tms            ),
    .tdi                (tdi            ),
    .tdo                (tdo            ),
    .tdo_en             (tdo_en         ),
`endif // SCR1_DBGC_EN

    // Instruction Memory Interface
    .imem_hprot         (imem_hprot     ),
    .imem_hburst        (imem_hburst    ),
    .imem_hsize         (imem_hsize     ),
    .imem_htrans        (imem_htrans    ),
    .imem_hmastlock     (imem_hmastlock ),
    .imem_haddr         (imem_haddr     ),
    .imem_hready        (imem_hready    ),
    .imem_hrdata        (imem_hrdata    ),
    .imem_hresp         (imem_hresp     ),

    // Data Memory Interface
    .dmem_hprot         (dmem_hprot     ),
    .dmem_hburst        (dmem_hburst    ),
    .dmem_hsize         (dmem_hsize     ),
    .dmem_htrans        (dmem_htrans    ),
    .dmem_hmastlock     (dmem_hmastlock ),
    .dmem_haddr         (dmem_haddr     ),
    .dmem_hwrite        (dmem_hwrite    ),
    .dmem_hwdata        (dmem_hwdata    ),
    .dmem_hready        (dmem_hready    ),
    .dmem_hrdata        (dmem_hrdata    ),
    .dmem_hresp         (dmem_hresp     )
);

//-------------------------------------------------------------------------------
// Memory instance
//-------------------------------------------------------------------------------
scr1_memory_tb_ahb #(
    .SCR1_MEM_POWER_SIZE    (SCR1_MEM_POWER_SIZE)
) i_memory_tb (
    // Control
    .rst_n                  (rst_n              ),
    .clk                    (clk                ),
`ifdef SCR1_IPIC_EN
    .irq_lines              (irq_lines          ),
`endif // SCR1_IPIC_EN
    .imem_req_ack_stall_in  (imem_req_ack_stall ),
    .dmem_req_ack_stall_in  (dmem_req_ack_stall ),

    // Instruction Memory Interface
    // .imem_hprot             (imem_hprot         ),
    // .imem_hburst            (imem_hburst        ),
    .imem_hsize             (imem_hsize         ),
    .imem_htrans            (imem_htrans        ),
    .imem_haddr             (imem_haddr         ),
    .imem_hready            (imem_hready        ),
    .imem_hrdata            (imem_hrdata        ),
    .imem_hresp             (imem_hresp         ),

    // Data Memory Interface
    // .dmem_hprot             (dmem_hprot         ),
    // .dmem_hburst            (dmem_hburst        ),
    .dmem_hsize             (dmem_hsize         ),
    .dmem_htrans            (dmem_htrans        ),
    .dmem_haddr             (dmem_haddr         ),
    .dmem_hwrite            (dmem_hwrite        ),
    .dmem_hwdata            (dmem_hwdata        ),
    .dmem_hready            (dmem_hready        ),
    .dmem_hrdata            (dmem_hrdata        ),
    .dmem_hresp             (dmem_hresp         )
);

endmodule : scr1_top_tb_ahb
