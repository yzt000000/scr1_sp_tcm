/// Copyright by Syntacore LLC © 2016-2020. See LICENSE for details
/// @file       <scr1_top_axi.sv>
/// @brief      SCR1 AXI top
///

`include "scr1_arch_description.svh"
`include "scr1_memif.svh"
`include "scr1_ahb.svh"
`ifdef SCR1_IPIC_EN
`include "scr1_ipic.svh"
`endif // SCR1_IPIC_EN
`ifdef SCR1_RVX_EXT
`include "scr1_arch_types.svh"
`include "scr1_riscv_isa_decoding.svh"
`endif // SCR1_RVX_EXT

`ifdef SCR1_TCM_EN
 `define SCR1_IMEM_ROUTER_EN
`endif // SCR1_TCM_EN

module scr1_top_axi (
    // Control
    input   logic                                   pwrup_rst_n,            // Power-Up Reset
    input   logic                                   rst_n,                  // Regular Reset signal
    input   logic                                   cpu_rst_n,              // CPU Reset (Core Reset)
    input   logic                                   test_mode,              // Test mode
    input   logic                                   test_rst_n,             // Test mode's reset
    input   logic                                   clk,                    // System clock
    input   logic                                   rtc_clk,                // Real-time clock
`ifdef SCR1_DBG_EN
    output  logic                                   sys_rst_n_o,            // External System Reset output
                                                                            //   (for the processor cluster's components or
                                                                            //    external SOC (could be useful in small
                                                                            //    SCR-core-centric SOCs))
    output  logic                                   sys_rdc_qlfy_o,         // System-to-External SOC Reset Domain Crossing Qualifier

    // External HART control (asynchronous, synchronized inside the HDU):
    // ext halt requests the core to be halted with the context preserved,
    // ext resume requests the halted core to continue execution - e.g. an
    // external bus master can halt the core, load a program into the TCM
    // through the TCM AHB subordinate port and then resume the core
    input   logic                                   ext_halt_req,           // External halt request (async, level)
    input   logic                                   ext_resume_req,         // External resume request (async, level)
`endif // SCR1_DBG_EN

    // Fuses
    input   logic [`SCR1_XLEN-1:0]                  fuse_mhartid,           // Hart ID
`ifdef SCR1_DBG_EN
    input   logic [31:0]                            fuse_idcode,            // TAPC IDCODE
`endif // SCR1_DBG_EN

    // IRQ
`ifdef SCR1_IPIC_EN
    input   logic [SCR1_IRQ_LINES_NUM-1:0]          irq_lines,              // IRQ lines to IPIC
`else // SCR1_IPIC_EN
    input   logic                                   ext_irq,                // External IRQ input
`endif // SCR1_IPIC_EN
    input   logic                                   soft_irq,               // Software IRQ input

`ifdef SCR1_DBG_EN
    // -- JTAG I/F
    input   logic                                   trst_n,
    input   logic                                   tck,
    input   logic                                   tms,
    input   logic                                   tdi,
    output  logic                                   tdo,
    output  logic                                   tdo_en,
`endif // SCR1_DBG_EN

    // Instruction Memory Interface
    output  logic [3:0]                             io_axi_imem_awid,
    output  logic [31:0]                            io_axi_imem_awaddr,
    output  logic [7:0]                             io_axi_imem_awlen,
    output  logic [2:0]                             io_axi_imem_awsize,
    output  logic [1:0]                             io_axi_imem_awburst,
    output  logic                                   io_axi_imem_awlock,
    output  logic [3:0]                             io_axi_imem_awcache,
    output  logic [2:0]                             io_axi_imem_awprot,
    output  logic [3:0]                             io_axi_imem_awregion,
    output  logic [3:0]                             io_axi_imem_awuser,
    output  logic [3:0]                             io_axi_imem_awqos,
    output  logic                                   io_axi_imem_awvalid,
    input   logic                                   io_axi_imem_awready,
    output  logic [31:0]                            io_axi_imem_wdata,
    output  logic [3:0]                             io_axi_imem_wstrb,
    output  logic                                   io_axi_imem_wlast,
    output  logic [3:0]                             io_axi_imem_wuser,
    output  logic                                   io_axi_imem_wvalid,
    input   logic                                   io_axi_imem_wready,
    input   logic [3:0]                             io_axi_imem_bid,
    input   logic [1:0]                             io_axi_imem_bresp,
    input   logic                                   io_axi_imem_bvalid,
    input   logic [3:0]                             io_axi_imem_buser,
    output  logic                                   io_axi_imem_bready,
    output  logic [3:0]                             io_axi_imem_arid,
    output  logic [31:0]                            io_axi_imem_araddr,
    output  logic [7:0]                             io_axi_imem_arlen,
    output  logic [2:0]                             io_axi_imem_arsize,
    output  logic [1:0]                             io_axi_imem_arburst,
    output  logic                                   io_axi_imem_arlock,
    output  logic [3:0]                             io_axi_imem_arcache,
    output  logic [2:0]                             io_axi_imem_arprot,
    output  logic [3:0]                             io_axi_imem_arregion,
    output  logic [3:0]                             io_axi_imem_aruser,
    output  logic [3:0]                             io_axi_imem_arqos,
    output  logic                                   io_axi_imem_arvalid,
    input   logic                                   io_axi_imem_arready,
    input   logic [3:0]                             io_axi_imem_rid,
    input   logic [31:0]                            io_axi_imem_rdata,
    input   logic [1:0]                             io_axi_imem_rresp,
    input   logic                                   io_axi_imem_rlast,
    input   logic [3:0]                             io_axi_imem_ruser,
    input   logic                                   io_axi_imem_rvalid,
    output  logic                                   io_axi_imem_rready,

    // Data Memory Interface
    output  logic [3:0]                             io_axi_dmem_awid,
    output  logic [31:0]                            io_axi_dmem_awaddr,
    output  logic [7:0]                             io_axi_dmem_awlen,
    output  logic [2:0]                             io_axi_dmem_awsize,
    output  logic [1:0]                             io_axi_dmem_awburst,
    output  logic                                   io_axi_dmem_awlock,
    output  logic [3:0]                             io_axi_dmem_awcache,
    output  logic [2:0]                             io_axi_dmem_awprot,
    output  logic [3:0]                             io_axi_dmem_awregion,
    output  logic [3:0]                             io_axi_dmem_awuser,
    output  logic [3:0]                             io_axi_dmem_awqos,
    output  logic                                   io_axi_dmem_awvalid,
    input   logic                                   io_axi_dmem_awready,
    output  logic [31:0]                            io_axi_dmem_wdata,
    output  logic [3:0]                             io_axi_dmem_wstrb,
    output  logic                                   io_axi_dmem_wlast,
    output  logic [3:0]                             io_axi_dmem_wuser,
    output  logic                                   io_axi_dmem_wvalid,
    input   logic                                   io_axi_dmem_wready,
    input   logic [3:0]                             io_axi_dmem_bid,
    input   logic [1:0]                             io_axi_dmem_bresp,
    input   logic                                   io_axi_dmem_bvalid,
    input   logic [3:0]                             io_axi_dmem_buser,
    output  logic                                   io_axi_dmem_bready,
    output  logic [3:0]                             io_axi_dmem_arid,
    output  logic [31:0]                            io_axi_dmem_araddr,
    output  logic [7:0]                             io_axi_dmem_arlen,
    output  logic [2:0]                             io_axi_dmem_arsize,
    output  logic [1:0]                             io_axi_dmem_arburst,
    output  logic                                   io_axi_dmem_arlock,
    output  logic [3:0]                             io_axi_dmem_arcache,
    output  logic [2:0]                             io_axi_dmem_arprot,
    output  logic [3:0]                             io_axi_dmem_arregion,
    output  logic [3:0]                             io_axi_dmem_aruser,
    output  logic [3:0]                             io_axi_dmem_arqos,
    output  logic                                   io_axi_dmem_arvalid,
    input   logic                                   io_axi_dmem_arready,
    input   logic [3:0]                             io_axi_dmem_rid,
    input   logic [31:0]                            io_axi_dmem_rdata,
    input   logic [1:0]                             io_axi_dmem_rresp,
    input   logic                                   io_axi_dmem_rlast,
    input   logic [3:0]                             io_axi_dmem_ruser,
    input   logic                                   io_axi_dmem_rvalid,
    output  logic                                   io_axi_dmem_rready

`ifdef SCR1_TCM_EN
    ,
    // TCM AHB Subordinate port: external masters load/read the ITCM/DTCM
    // through this interface (real TCM address map: 0x0048_xxxx / 0x0049_xxxx)
    input   logic [3:0]                             tcm_sbr_hprot,
    input   logic [2:0]                             tcm_sbr_hburst,
    input   logic [2:0]                             tcm_sbr_hsize,
    input   logic [1:0]                             tcm_sbr_htrans,
    input   logic                                   tcm_sbr_hmastlock,
    input   logic [SCR1_AHB_WIDTH-1:0]              tcm_sbr_haddr,
    input   logic                                   tcm_sbr_hwrite,
    input   logic [SCR1_AHB_WIDTH-1:0]              tcm_sbr_hwdata,
    input   logic                                   tcm_sbr_hreadyin,
    output  logic                                   tcm_sbr_hreadyout,
    output  logic [SCR1_AHB_WIDTH-1:0]              tcm_sbr_hrdata,
    output  logic                                   tcm_sbr_hresp
`endif // SCR1_TCM_EN
);

//-------------------------------------------------------------------------------
// Local parameters
//-------------------------------------------------------------------------------
localparam int unsigned SCR1_CLUSTER_TOP_RST_SYNC_STAGES_NUM            = 2;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
// Reset logic
logic                                               pwrup_rst_n_sync;
logic                                               rst_n_sync;
logic                                               cpu_rst_n_sync;
logic                                               core_rst_n_local;
logic                                               axi_rst_n;
`ifdef SCR1_DBG_EN
logic                                               tapc_trst_n;
`endif // SCR1_DBG_EN

// Instruction memory interface from core to router
logic                                               core_imem_req_ack;
logic                                               core_imem_req;
type_scr1_mem_cmd_e                                 core_imem_cmd;
logic [`SCR1_IMEM_AWIDTH-1:0]                       core_imem_addr;
logic [`SCR1_IMEM_DWIDTH-1:0]                       core_imem_rdata;
type_scr1_mem_resp_e                                core_imem_resp;

// Data memory interface from core to router
logic                                               core_dmem_req_ack;
logic                                               core_dmem_req;
type_scr1_mem_cmd_e                                 core_dmem_cmd;
type_scr1_mem_width_e                               core_dmem_width;
logic [`SCR1_DMEM_AWIDTH-1:0]                       core_dmem_addr;
logic [`SCR1_DMEM_DWIDTH-1:0]                       core_dmem_wdata;
logic [`SCR1_DMEM_DWIDTH-1:0]                       core_dmem_rdata;
type_scr1_mem_resp_e                                core_dmem_resp;

// Data memory interface to dmem_router (from arbiter or direct from core)
logic                                               router_dmem_req_ack;
logic                                               router_dmem_req;
type_scr1_mem_cmd_e                                 router_dmem_cmd;
type_scr1_mem_width_e                               router_dmem_width;
logic [`SCR1_DMEM_AWIDTH-1:0]                       router_dmem_addr;
logic [`SCR1_DMEM_DWIDTH-1:0]                       router_dmem_wdata;
logic [`SCR1_DMEM_DWIDTH-1:0]                       router_dmem_rdata;
type_scr1_mem_resp_e                                router_dmem_resp;

`ifdef SCR1_MTX_EXT
// CFU DMEM master interface
type_scr1_cfu_dmem_req_s                              cfu_dmem_req_w;
type_scr1_cfu_dmem_resp_s                             cfu_dmem_resp_w;
`endif // SCR1_MTX_EXT

// Instruction memory interface from router to AXI bridge
logic                                               axi_imem_req_ack;
logic                                               axi_imem_req;
type_scr1_mem_cmd_e                                 axi_imem_cmd;
logic [`SCR1_IMEM_AWIDTH-1:0]                       axi_imem_addr;
logic [`SCR1_IMEM_DWIDTH-1:0]                       axi_imem_rdata;
type_scr1_mem_resp_e                                axi_imem_resp;

// Data memory interface from router to AXI bridge
logic                                               axi_dmem_req_ack;
logic                                               axi_dmem_req;
type_scr1_mem_cmd_e                                 axi_dmem_cmd;
type_scr1_mem_width_e                               axi_dmem_width;
logic [`SCR1_DMEM_AWIDTH-1:0]                       axi_dmem_addr;
logic [`SCR1_DMEM_DWIDTH-1:0]                       axi_dmem_wdata;
logic [`SCR1_DMEM_DWIDTH-1:0]                       axi_dmem_rdata;
type_scr1_mem_resp_e                                axi_dmem_resp;

`ifdef SCR1_TCM_EN
// Instruction memory interface from router to TCM
logic                                               tcm_imem_req_ack;
logic                                               tcm_imem_req;
type_scr1_mem_cmd_e                                 tcm_imem_cmd;
logic [`SCR1_IMEM_AWIDTH-1:0]                       tcm_imem_addr;
logic [`SCR1_IMEM_DWIDTH-1:0]                       tcm_imem_rdata;
type_scr1_mem_resp_e                                tcm_imem_resp;

// Data memory interface from router to TCM
logic                                               tcm_dmem_req_ack;
logic                                               tcm_dmem_req;
type_scr1_mem_cmd_e                                 tcm_dmem_cmd;
type_scr1_mem_width_e                               tcm_dmem_width;
logic [`SCR1_DMEM_AWIDTH-1:0]                       tcm_dmem_addr;
logic [`SCR1_DMEM_DWIDTH-1:0]                       tcm_dmem_wdata;
logic [`SCR1_DMEM_DWIDTH-1:0]                       tcm_dmem_rdata;
type_scr1_mem_resp_e                                tcm_dmem_resp;

// TCM slave memif interface from the AHB subordinate bridge
logic                                               tcm_sbr_req_ack;
logic                                               tcm_sbr_req;
type_scr1_mem_cmd_e                                 tcm_sbr_cmd;
type_scr1_mem_width_e                               tcm_sbr_width;
logic [`SCR1_DMEM_AWIDTH-1:0]                       tcm_sbr_addr;
logic [`SCR1_DMEM_DWIDTH-1:0]                       tcm_sbr_wdata;
logic [`SCR1_DMEM_DWIDTH-1:0]                       tcm_sbr_rdata;
type_scr1_mem_resp_e                                tcm_sbr_resp;
`endif // SCR1_TCM_EN

// Data memory interface from router to memory-mapped timer
logic                                               timer_dmem_req_ack;
logic                                               timer_dmem_req;
type_scr1_mem_cmd_e                                 timer_dmem_cmd;
type_scr1_mem_width_e                               timer_dmem_width;
logic [`SCR1_DMEM_AWIDTH-1:0]                       timer_dmem_addr;
logic [`SCR1_DMEM_DWIDTH-1:0]                       timer_dmem_wdata;
logic [`SCR1_DMEM_DWIDTH-1:0]                       timer_dmem_rdata;
type_scr1_mem_resp_e                                timer_dmem_resp;

// Misc
logic                                               timer_irq;
logic [63:0]                                        timer_val;

`ifdef SCR1_RVX_EXT
// CV-X-IF interface signals (Core <-> CFU)
type_scr1_cvxif_req_s                               core2cfu_req;
type_scr1_cvxif_resp_s                              cfu2core_resp;
`endif // SCR1_RVX_EXT
logic                                               axi_reinit;
logic                                               axi_imem_idle;
logic                                               axi_dmem_idle;

//-------------------------------------------------------------------------------
// Reset logic
//-------------------------------------------------------------------------------
// Power-Up Reset synchronizer
scr1_reset_sync_cell #(
    .STAGES_AMOUNT       (SCR1_CLUSTER_TOP_RST_SYNC_STAGES_NUM)
) i_pwrup_rstn_reset_sync (
    .rst_n          (pwrup_rst_n     ),
    .clk            (clk             ),
    .test_rst_n     (test_rst_n      ),
    .test_mode      (test_mode       ),
    .rst_n_in       (1'b1            ),
    .rst_n_out      (pwrup_rst_n_sync)
);

// Regular Reset synchronizer
scr1_reset_sync_cell #(
    .STAGES_AMOUNT       (SCR1_CLUSTER_TOP_RST_SYNC_STAGES_NUM)
) i_rstn_reset_sync (
    .rst_n          (pwrup_rst_n     ),
    .clk            (clk             ),
    .test_rst_n     (test_rst_n      ),
    .test_mode      (test_mode       ),
    .rst_n_in       (rst_n           ),
    .rst_n_out      (rst_n_sync      )
);

// CPU Reset synchronizer
scr1_reset_sync_cell #(
    .STAGES_AMOUNT       (SCR1_CLUSTER_TOP_RST_SYNC_STAGES_NUM)
) i_cpu_rstn_reset_sync (
    .rst_n          (pwrup_rst_n     ),
    .clk            (clk             ),
    .test_rst_n     (test_rst_n      ),
    .test_mode      (test_mode       ),
    .rst_n_in       (cpu_rst_n       ),
    .rst_n_out      (cpu_rst_n_sync  )
);

`ifdef SCR1_DBG_EN
// TAPC Reset
scr1_reset_and2_cell i_tapc_rstn_and2_cell (
    .rst_n_in       ({trst_n, pwrup_rst_n}),
    .test_rst_n     (test_rst_n      ),
    .test_mode      (test_mode       ),
    .rst_n_out      (tapc_trst_n     )
);
`endif // SCR1_DBG_EN

`ifdef SCR1_DBG_EN
assign axi_rst_n = sys_rst_n_o;
`else // SCR1_DBG_EN
assign axi_rst_n = rst_n_sync;
`endif // SCR1_DBG_EN

//-------------------------------------------------------------------------------
// SCR1 core instance
//-------------------------------------------------------------------------------
scr1_core_top i_core_top (
    // Common
    .pwrup_rst_n                (pwrup_rst_n_sync ),
    .rst_n                      (rst_n_sync       ),
    .cpu_rst_n                  (cpu_rst_n_sync   ),
    .test_mode                  (test_mode        ),
    .test_rst_n                 (test_rst_n       ),
    .clk                        (clk              ),
    .core_rst_n_o               (core_rst_n_local ),
    .core_rdc_qlfy_o            (                 ),
`ifdef SCR1_DBG_EN
    .sys_rst_n_o                (sys_rst_n_o      ),
    .sys_rdc_qlfy_o             (sys_rdc_qlfy_o   ),
    .ext_halt_req_i             (ext_halt_req     ),
    .ext_resume_req_i           (ext_resume_req   ),
`endif // SCR1_DBG_EN

    // Fuses
    .core_fuse_mhartid_i        (fuse_mhartid     ),
`ifdef SCR1_DBG_EN
    .tapc_fuse_idcode_i         (fuse_idcode      ),
`endif // SCR1_DBG_EN

    // IRQ
`ifdef SCR1_IPIC_EN
    .core_irq_lines_i           (irq_lines        ),
`else // SCR1_IPIC_EN
    .core_irq_ext_i             (ext_irq          ),
`endif // SCR1_IPIC_EN
    .core_irq_soft_i            (soft_irq         ),
    .core_irq_mtimer_i          (timer_irq        ),

    // Memory-mapped external timer
    .core_mtimer_val_i          (timer_val        ),

`ifdef SCR1_DBG_EN
    // Debug interface
    .tapc_trst_n                (tapc_trst_n      ),
    .tapc_tck                   (tck              ),
    .tapc_tms                   (tms              ),
    .tapc_tdi                   (tdi              ),
    .tapc_tdo                   (tdo              ),
    .tapc_tdo_en                (tdo_en           ),
`endif // SCR1_DBG_EN

    // Instruction memory interface
    .imem2core_req_ack_i        (core_imem_req_ack),
    .core2imem_req_o            (core_imem_req    ),
    .core2imem_cmd_o            (core_imem_cmd    ),
    .core2imem_addr_o           (core_imem_addr   ),
    .imem2core_rdata_i          (core_imem_rdata  ),
    .imem2core_resp_i           (core_imem_resp   ),

    // Data memory interface
    .dmem2core_req_ack_i        (core_dmem_req_ack),
    .core2dmem_req_o            (core_dmem_req    ),
    .core2dmem_cmd_o            (core_dmem_cmd    ),
    .core2dmem_width_o          (core_dmem_width  ),
    .core2dmem_addr_o           (core_dmem_addr   ),
    .core2dmem_wdata_o          (core_dmem_wdata  ),
    .dmem2core_rdata_i          (core_dmem_rdata  ),
    .dmem2core_resp_i           (core_dmem_resp   )
`ifdef SCR1_RVX_EXT
    ,
    .cfu2core_resp_i            (cfu2core_resp    ),
    .core2cfu_req_o             (core2cfu_req     )
`endif // SCR1_RVX_EXT
);

`ifdef SCR1_RVX_EXT
`ifdef SCR1_MTX_EXT
//-------------------------------------------------------------------------------
// CV-X-IF CFU with Matrix Multiply extension + DMEM arbiter
//-------------------------------------------------------------------------------
scr1_pipe_cfu_mtx #(
    .MAX_LATENCY                (256)
) i_cfu (
    .clk                        (clk              ),
    .rst_n                      (core_rst_n_local ),
    .cvxif_req_i                (core2cfu_req     ),
    .cvxif_resp_o               (cfu2core_resp    ),
    .cfu_dmem_req_o             (cfu_dmem_req_w   ),
    .cfu_dmem_resp_i            (cfu_dmem_resp_w  )
);

scr1_dmem_arbiter i_dmem_arbiter (
    .clk            (clk                    ),
    .rst_n          (core_rst_n_local       ),
    .m0_req         (core_dmem_req          ),
    .m0_cmd         (core_dmem_cmd          ),
    .m0_width       (core_dmem_width        ),
    .m0_addr        (core_dmem_addr         ),
    .m0_wdata       (core_dmem_wdata        ),
    .m0_req_ack     (core_dmem_req_ack      ),
    .m0_rdata       (core_dmem_rdata        ),
    .m0_resp        (core_dmem_resp         ),
    .m1_req         (cfu_dmem_req_w.req     ),
    .m1_cmd         (cfu_dmem_req_w.cmd     ),
    .m1_width       (cfu_dmem_req_w.width   ),
    .m1_addr        (cfu_dmem_req_w.addr    ),
    .m1_wdata       (cfu_dmem_req_w.wdata   ),
    .m1_req_ack     (cfu_dmem_resp_w.req_ack),
    .m1_rdata       (cfu_dmem_resp_w.rdata  ),
    .m1_resp        (cfu_dmem_resp_w.resp   ),
    .out_req        (router_dmem_req        ),
    .out_cmd        (router_dmem_cmd        ),
    .out_width      (router_dmem_width      ),
    .out_addr       (router_dmem_addr       ),
    .out_wdata      (router_dmem_wdata      ),
    .out_req_ack    (router_dmem_req_ack    ),
    .out_rdata      (router_dmem_rdata      ),
    .out_resp       (router_dmem_resp       )
);
`else // SCR1_MTX_EXT
//-------------------------------------------------------------------------------
// CV-X-IF Custom Function Unit (reference implementation, custom-0 ALU only)
//-------------------------------------------------------------------------------
scr1_pipe_cfu #(
    .MAX_LATENCY                (1)
) i_cfu (
    .clk                        (clk              ),
    .rst_n                      (core_rst_n_local ),
    .cvxif_req_i                (core2cfu_req     ),
    .cvxif_resp_o               (cfu2core_resp    )
);
`endif // SCR1_MTX_EXT
`endif // SCR1_RVX_EXT

`ifndef SCR1_MTX_EXT
// Direct connect core dmem to router dmem when MTX extension is disabled
assign router_dmem_req     = core_dmem_req;
assign router_dmem_cmd     = core_dmem_cmd;
assign router_dmem_width   = core_dmem_width;
assign router_dmem_addr    = core_dmem_addr;
assign router_dmem_wdata   = core_dmem_wdata;
assign core_dmem_req_ack   = router_dmem_req_ack;
assign core_dmem_rdata     = router_dmem_rdata;
assign core_dmem_resp      = router_dmem_resp;
`endif // SCR1_MTX_EXT


`ifdef SCR1_TCM_EN
//-----------------------------------------------------------------------------
// TCM AHB subordinate bridge
//-----------------------------------------------------------------------------
// The bridge and the TCM share the system reset domain (rst_n_sync): an
// external master may load the TCM while the CPU is still held in reset -
// the TCM banks answer normally because no core requests are pending then
// (reset-time loading is naturally prioritized).
scr1_tcm_ahb_sbr i_tcm_ahb_sbr (
    .clk            (clk                ),
    .rst_n          (rst_n_sync         ),

    .hprot          (tcm_sbr_hprot      ),
    .hburst         (tcm_sbr_hburst     ),
    .hsize          (tcm_sbr_hsize      ),
    .htrans         (tcm_sbr_htrans     ),
    .hmastlock      (tcm_sbr_hmastlock  ),
    .haddr          (tcm_sbr_haddr      ),
    .hwrite         (tcm_sbr_hwrite     ),
    .hwdata         (tcm_sbr_hwdata     ),
    .hreadyin       (tcm_sbr_hreadyin   ),
    .hreadyout      (tcm_sbr_hreadyout  ),
    .hrdata         (tcm_sbr_hrdata     ),
    .hresp          (tcm_sbr_hresp      ),

    .sbr_req        (tcm_sbr_req        ),
    .sbr_cmd        (tcm_sbr_cmd        ),
    .sbr_width      (tcm_sbr_width      ),
    .sbr_addr       (tcm_sbr_addr       ),
    .sbr_wdata      (tcm_sbr_wdata      ),
    .sbr_req_ack    (tcm_sbr_req_ack    ),
    .sbr_rdata      (tcm_sbr_rdata      ),
    .sbr_resp       (tcm_sbr_resp       )
);

//-------------------------------------------------------------------------------
// TCM instance
//-------------------------------------------------------------------------------
// TCM reset is taken from the system reset as well: the subordinate bridge
// must get responses while the CPU is held in reset (reset-time loading),
// and the core issues no TCM requests during its own reset anyway
scr1_tcm #(
    .SCR1_ITCM_SIZE (`SCR1_DMEM_AWIDTH'(~SCR1_ITCM_ADDR_MASK + 1'b1)),
    .SCR1_DTCM_SIZE (`SCR1_DMEM_AWIDTH'(~SCR1_DTCM_ADDR_MASK + 1'b1))
) i_tcm (
    .clk            (clk             ),
    .rst_n          (rst_n_sync      ),

    // Instruction interface to TCM
    .imem_req_ack   (tcm_imem_req_ack),
    .imem_req       (tcm_imem_req    ),
    .imem_cmd       (tcm_imem_cmd    ),
    .imem_addr      (tcm_imem_addr   ),
    .imem_rdata     (tcm_imem_rdata  ),
    .imem_resp      (tcm_imem_resp   ),

    // Data interface to TCM
    .dmem_req_ack   (tcm_dmem_req_ack),
    .dmem_req       (tcm_dmem_req    ),
    .dmem_cmd       (tcm_dmem_cmd    ),
    .dmem_width     (tcm_dmem_width  ),
    .dmem_addr      (tcm_dmem_addr   ),
    .dmem_wdata     (tcm_dmem_wdata  ),
    .dmem_rdata     (tcm_dmem_rdata  ),
    .dmem_resp      (tcm_dmem_resp   ),

    // External subordinate interface from the AHB bridge
    .sbr_req_ack    (tcm_sbr_req_ack ),
    .sbr_req        (tcm_sbr_req     ),
    .sbr_cmd        (tcm_sbr_cmd     ),
    .sbr_width      (tcm_sbr_width   ),
    .sbr_addr       (tcm_sbr_addr    ),
    .sbr_wdata      (tcm_sbr_wdata   ),
    .sbr_rdata      (tcm_sbr_rdata   ),
    .sbr_resp       (tcm_sbr_resp    )
);
`endif // SCR1_TCM_EN


//-------------------------------------------------------------------------------
// Memory-mapped timer instance
//-------------------------------------------------------------------------------
scr1_timer i_timer (
    // Common
    .rst_n          (core_rst_n_local  ),
    .clk            (clk               ),
    .rtc_clk        (rtc_clk           ),

    // Memory interface
    .dmem_req       (timer_dmem_req    ),
    .dmem_cmd       (timer_dmem_cmd    ),
    .dmem_width     (timer_dmem_width  ),
    .dmem_addr      (timer_dmem_addr   ),
    .dmem_wdata     (timer_dmem_wdata  ),
    .dmem_req_ack   (timer_dmem_req_ack),
    .dmem_rdata     (timer_dmem_rdata  ),
    .dmem_resp      (timer_dmem_resp   ),

    // Timer interface
    .timer_val      (timer_val         ),
    .timer_irq      (timer_irq         )
);


`ifdef SCR1_IMEM_ROUTER_EN
//-------------------------------------------------------------------------------
// Instruction memory router
//-------------------------------------------------------------------------------
scr1_imem_router #(
    .SCR1_ADDR_MASK     (SCR1_TCM_ADDR_MASK),
    .SCR1_ADDR_PATTERN  (SCR1_TCM_ADDR_PATTERN)
) i_imem_router (
    .rst_n          (core_rst_n_local ),
    .clk            (clk              ),

    // Interface to core
    .imem_req_ack   (core_imem_req_ack),
    .imem_req       (core_imem_req    ),
    .imem_cmd       (core_imem_cmd    ),
    .imem_addr      (core_imem_addr   ),
    .imem_rdata     (core_imem_rdata  ),
    .imem_resp      (core_imem_resp   ),

    // Interface to AXI bridge
    .port0_req_ack  (axi_imem_req_ack ),
    .port0_req      (axi_imem_req     ),
    .port0_cmd      (axi_imem_cmd     ),
    .port0_addr     (axi_imem_addr    ),
    .port0_rdata    (axi_imem_rdata   ),
    .port0_resp     (axi_imem_resp    ),

    // Interface to TCM
    .port1_req_ack  (tcm_imem_req_ack ),
    .port1_req      (tcm_imem_req     ),
    .port1_cmd      (tcm_imem_cmd     ),
    .port1_addr     (tcm_imem_addr    ),
    .port1_rdata    (tcm_imem_rdata   ),
    .port1_resp     (tcm_imem_resp    )
);

`else // SCR1_IMEM_ROUTER_EN

assign axi_imem_req         = core_imem_req;
assign axi_imem_cmd         = core_imem_cmd;
assign axi_imem_addr        = core_imem_addr;
assign core_imem_req_ack    = axi_imem_req_ack;
assign core_imem_resp       = axi_imem_resp;
assign core_imem_rdata      = axi_imem_rdata;

`endif // SCR1_IMEM_ROUTER_EN


//-------------------------------------------------------------------------------
// Data memory router
//-------------------------------------------------------------------------------
scr1_dmem_router #(

`ifdef SCR1_TCM_EN
    .SCR1_PORT1_ADDR_MASK       (SCR1_TCM_ADDR_MASK),
    .SCR1_PORT1_ADDR_PATTERN    (SCR1_TCM_ADDR_PATTERN),
`else // SCR1_TCM_EN
    .SCR1_PORT1_ADDR_MASK       (32'h00000000),
    .SCR1_PORT1_ADDR_PATTERN    (32'hFFFFFFFF),
`endif // SCR1_TCM_EN

    .SCR1_PORT2_ADDR_MASK       (SCR1_TIMER_ADDR_MASK),
    .SCR1_PORT2_ADDR_PATTERN    (SCR1_TIMER_ADDR_PATTERN)

) i_dmem_router (
    .rst_n          (core_rst_n_local    ),
    .clk            (clk                 ),

    // Interface to core
    .dmem_req_ack   (router_dmem_req_ack   ),
    .dmem_req       (router_dmem_req       ),
    .dmem_cmd       (router_dmem_cmd       ),
    .dmem_width     (router_dmem_width     ),
    .dmem_addr      (router_dmem_addr      ),
    .dmem_wdata     (router_dmem_wdata     ),
    .dmem_rdata     (router_dmem_rdata     ),
    .dmem_resp      (router_dmem_resp      ),

`ifdef SCR1_TCM_EN
    // Interface to TCM
    .port1_req_ack  (tcm_dmem_req_ack    ),
    .port1_req      (tcm_dmem_req        ),
    .port1_cmd      (tcm_dmem_cmd        ),
    .port1_width    (tcm_dmem_width      ),
    .port1_addr     (tcm_dmem_addr       ),
    .port1_wdata    (tcm_dmem_wdata      ),
    .port1_rdata    (tcm_dmem_rdata      ),
    .port1_resp     (tcm_dmem_resp       ),
`else // SCR1_TCM_EN
    .port1_req_ack  (1'b0                ),
    .port1_req      (                    ),
    .port1_cmd      (                    ),
    .port1_width    (                    ),
    .port1_addr     (                    ),
    .port1_wdata    (                    ),
    .port1_rdata    ('0                  ),
    .port1_resp     (SCR1_MEM_RESP_RDY_ER),
`endif // SCR1_TCM_EN

    // Interface to memory-mapped timer
    .port2_req_ack  (timer_dmem_req_ack  ),
    .port2_req      (timer_dmem_req      ),
    .port2_cmd      (timer_dmem_cmd      ),
    .port2_width    (timer_dmem_width    ),
    .port2_addr     (timer_dmem_addr     ),
    .port2_wdata    (timer_dmem_wdata    ),
    .port2_rdata    (timer_dmem_rdata    ),
    .port2_resp     (timer_dmem_resp     ),

    // Interface to AXI bridge
    .port0_req_ack  (axi_dmem_req_ack    ),
    .port0_req      (axi_dmem_req        ),
    .port0_cmd      (axi_dmem_cmd        ),
    .port0_width    (axi_dmem_width      ),
    .port0_addr     (axi_dmem_addr       ),
    .port0_wdata    (axi_dmem_wdata      ),
    .port0_rdata    (axi_dmem_rdata      ),
    .port0_resp     (axi_dmem_resp       )
);


//-------------------------------------------------------------------------------
// Instruction memory AXI bridge
//-------------------------------------------------------------------------------
scr1_mem_axi #(
`ifdef SCR1_IMEM_AXI_REQ_BP
    .SCR1_AXI_REQ_BP    (1),
`else // SCR1_IMEM_AXI_REQ_BP
    .SCR1_AXI_REQ_BP    (0),
`endif // SCR1_IMEM_AXI_REQ_BP
`ifdef SCR1_IMEM_AXI_RESP_BP
    .SCR1_AXI_RESP_BP   (1)
`else // SCR1_IMEM_AXI_RESP_BP
    .SCR1_AXI_RESP_BP   (0)
`endif // SCR1_IMEM_AXI_RESP_BP
) i_imem_axi (
    .clk            (clk                    ),
    .rst_n          (axi_rst_n              ),
    .axi_reinit     (axi_reinit             ),

    // Interface to core
    .core_idle      (axi_imem_idle          ),
    .core_req_ack   (axi_imem_req_ack       ),
    .core_req       (axi_imem_req           ),
    .core_cmd       (axi_imem_cmd           ),
    .core_width     (SCR1_MEM_WIDTH_WORD    ),
    .core_addr      (axi_imem_addr          ),
    .core_wdata     ('0                     ),
    .core_rdata     (axi_imem_rdata         ),
    .core_resp      (axi_imem_resp          ),

    // AXI I/O
    .awid           (io_axi_imem_awid       ),
    .awaddr         (io_axi_imem_awaddr     ),
    .awlen          (io_axi_imem_awlen      ),
    .awsize         (io_axi_imem_awsize     ),
    .awburst        (io_axi_imem_awburst    ),
    .awlock         (io_axi_imem_awlock     ),
    .awcache        (io_axi_imem_awcache    ),
    .awprot         (io_axi_imem_awprot     ),
    .awregion       (io_axi_imem_awregion   ),
    .awuser         (io_axi_imem_awuser     ),
    .awqos          (io_axi_imem_awqos      ),
    .awvalid        (io_axi_imem_awvalid    ),
    .awready        (io_axi_imem_awready    ),
    .wdata          (io_axi_imem_wdata      ),
    .wstrb          (io_axi_imem_wstrb      ),
    .wlast          (io_axi_imem_wlast      ),
    .wuser          (io_axi_imem_wuser      ),
    .wvalid         (io_axi_imem_wvalid     ),
    .wready         (io_axi_imem_wready     ),
    .bid            (io_axi_imem_bid        ),
    .bresp          (io_axi_imem_bresp      ),
    .bvalid         (io_axi_imem_bvalid     ),
    .buser          (io_axi_imem_buser      ),
    .bready         (io_axi_imem_bready     ),
    .arid           (io_axi_imem_arid       ),
    .araddr         (io_axi_imem_araddr     ),
    .arlen          (io_axi_imem_arlen      ),
    .arsize         (io_axi_imem_arsize     ),
    .arburst        (io_axi_imem_arburst    ),
    .arlock         (io_axi_imem_arlock     ),
    .arcache        (io_axi_imem_arcache    ),
    .arprot         (io_axi_imem_arprot     ),
    .arregion       (io_axi_imem_arregion   ),
    .aruser         (io_axi_imem_aruser     ),
    .arqos          (io_axi_imem_arqos      ),
    .arvalid        (io_axi_imem_arvalid    ),
    .arready        (io_axi_imem_arready    ),
    .rid            (io_axi_imem_rid        ),
    .rdata          (io_axi_imem_rdata      ),
    .rresp          (io_axi_imem_rresp      ),
    .rlast          (io_axi_imem_rlast      ),
    .ruser          (io_axi_imem_ruser      ),
    .rvalid         (io_axi_imem_rvalid     ),
    .rready         (io_axi_imem_rready     )
);


//-------------------------------------------------------------------------------
// Data memory AXI bridge
//-------------------------------------------------------------------------------
scr1_mem_axi #(
`ifdef SCR1_DMEM_AXI_REQ_BP
    .SCR1_AXI_REQ_BP    (1),
`else // SCR1_DMEM_AXI_REQ_BP
    .SCR1_AXI_REQ_BP    (0),
`endif // SCR1_DMEM_AXI_REQ_BP
`ifdef SCR1_DMEM_AXI_RESP_BP
    .SCR1_AXI_RESP_BP   (1)
`else // SCR1_DMEM_AXI_RESP_BP
    .SCR1_AXI_RESP_BP   (0)
`endif // SCR1_DMEM_AXI_RESP_BP
) i_dmem_axi (
    .clk            (clk                    ),
    .rst_n          (axi_rst_n              ),
    .axi_reinit     (axi_reinit             ),

    // Interface to core
    .core_idle      (axi_dmem_idle          ),
    .core_req_ack   (axi_dmem_req_ack       ),
    .core_req       (axi_dmem_req           ),
    .core_cmd       (axi_dmem_cmd           ),
    .core_width     (axi_dmem_width         ),
    .core_addr      (axi_dmem_addr          ),
    .core_wdata     (axi_dmem_wdata         ),
    .core_rdata     (axi_dmem_rdata         ),
    .core_resp      (axi_dmem_resp          ),

    // AXI I/O
    .awid           (io_axi_dmem_awid       ),
    .awaddr         (io_axi_dmem_awaddr     ),
    .awlen          (io_axi_dmem_awlen      ),
    .awsize         (io_axi_dmem_awsize     ),
    .awburst        (io_axi_dmem_awburst    ),
    .awlock         (io_axi_dmem_awlock     ),
    .awcache        (io_axi_dmem_awcache    ),
    .awprot         (io_axi_dmem_awprot     ),
    .awregion       (io_axi_dmem_awregion   ),
    .awuser         (io_axi_dmem_awuser     ),
    .awqos          (io_axi_dmem_awqos      ),
    .awvalid        (io_axi_dmem_awvalid    ),
    .awready        (io_axi_dmem_awready    ),
    .wdata          (io_axi_dmem_wdata      ),
    .wstrb          (io_axi_dmem_wstrb      ),
    .wlast          (io_axi_dmem_wlast      ),
    .wuser          (io_axi_dmem_wuser      ),
    .wvalid         (io_axi_dmem_wvalid     ),
    .wready         (io_axi_dmem_wready     ),
    .bid            (io_axi_dmem_bid        ),
    .bresp          (io_axi_dmem_bresp      ),
    .bvalid         (io_axi_dmem_bvalid     ),
    .buser          (io_axi_dmem_buser      ),
    .bready         (io_axi_dmem_bready     ),
    .arid           (io_axi_dmem_arid       ),
    .araddr         (io_axi_dmem_araddr     ),
    .arlen          (io_axi_dmem_arlen      ),
    .arsize         (io_axi_dmem_arsize     ),
    .arburst        (io_axi_dmem_arburst    ),
    .arlock         (io_axi_dmem_arlock     ),
    .arcache        (io_axi_dmem_arcache    ),
    .arprot         (io_axi_dmem_arprot     ),
    .arregion       (io_axi_dmem_arregion   ),
    .aruser         (io_axi_dmem_aruser     ),
    .arqos          (io_axi_dmem_arqos      ),
    .arvalid        (io_axi_dmem_arvalid    ),
    .arready        (io_axi_dmem_arready    ),
    .rid            (io_axi_dmem_rid        ),
    .rdata          (io_axi_dmem_rdata      ),
    .rresp          (io_axi_dmem_rresp      ),
    .rlast          (io_axi_dmem_rlast      ),
    .ruser          (io_axi_dmem_ruser      ),
    .rvalid         (io_axi_dmem_rvalid     ),
    .rready         (io_axi_dmem_rready     )
);

//-------------------------------------------------------------------------------
// AXI reinit logic
//-------------------------------------------------------------------------------
always_ff @(negedge core_rst_n_local, posedge clk) begin
    if (~core_rst_n_local)                      axi_reinit <= 1'b1;
    else if (axi_imem_idle & axi_dmem_idle)     axi_reinit <= 1'b0;
end

endmodule : scr1_top_axi
