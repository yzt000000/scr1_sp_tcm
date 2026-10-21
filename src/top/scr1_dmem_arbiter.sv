/// Copyright by Syntacore LLC © 2016-2021. See LICENSE for details
/// @file       <scr1_dmem_arbiter.sv>
/// @brief      DMEM Arbiter - round-robin with transaction lock
///
/// @details    Merges two dmem master interfaces (LSU = m0, CFU = m1) into a
///             single master interface to scr1_dmem_router.
///
///             Arbitration (borrowed from the proven scr1_dmem_arb design):
///               - a grant is taken when the bus is idle, round-robin so
///                 neither side starves;
///               - once a request is on the bus the grant is LOCKED until the
///                 response comes back - neither master may have its
///                 transaction moved out from under it;
///               - the response is routed ONLY to the granted master.
///
///             grant and locked live in ONE always_ff on purpose. Splitting
///             them lets the grant move in the very cycle a transaction is
///             accepted (the grant logic still sees the old, unlocked value),
///             and the response of that transaction is then routed to the
///             other master.

`include "scr1_arch_description.svh"
`include "scr1_memif.svh"

`ifdef SCR1_MTX_EXT
module scr1_dmem_arbiter (
    input   logic                           clk,
    input   logic                           rst_n,

    // Master 0: LSU
    input   logic                           m0_req,
    input   type_scr1_mem_cmd_e             m0_cmd,
    input   type_scr1_mem_width_e           m0_width,
    input   logic [`SCR1_DMEM_AWIDTH-1:0]   m0_addr,
    input   logic [`SCR1_DMEM_DWIDTH-1:0]   m0_wdata,
    output  logic                           m0_req_ack,
    output  logic [`SCR1_DMEM_DWIDTH-1:0]   m0_rdata,
    output  type_scr1_mem_resp_e            m0_resp,

    // Master 1: CFU
    input   logic                           m1_req,
    input   type_scr1_mem_cmd_e             m1_cmd,
    input   type_scr1_mem_width_e           m1_width,
    input   logic [`SCR1_DMEM_AWIDTH-1:0]   m1_addr,
    input   logic [`SCR1_DMEM_DWIDTH-1:0]   m1_wdata,
    output  logic                           m1_req_ack,
    output  logic [`SCR1_DMEM_DWIDTH-1:0]   m1_rdata,
    output  type_scr1_mem_resp_e            m1_resp,

    // Output to dmem_router
    output  logic                           out_req,
    output  type_scr1_mem_cmd_e             out_cmd,
    output  type_scr1_mem_width_e           out_width,
    output  logic [`SCR1_DMEM_AWIDTH-1:0]   out_addr,
    output  logic [`SCR1_DMEM_DWIDTH-1:0]   out_wdata,
    input   logic                           out_req_ack,
    input   logic [`SCR1_DMEM_DWIDTH-1:0]   out_rdata,
    input   type_scr1_mem_resp_e            out_resp
);

//------------------------------------------------------------------------------
// Grant and lock (single process to avoid cross-process race)
//------------------------------------------------------------------------------
logic grant;     // 0: m0 (LSU), 1: m1 (CFU)
logic locked;   // a transaction is on the bus, awaiting response

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        grant  <= 1'b0;
        locked <= 1'b0;
    end else if (locked) begin
        // Hold the grant until the answer arrives
        if (out_resp != SCR1_MEM_RESP_NOTRDY)
            locked <= 1'b0;
    end else if (out_req) begin
        // A request is being presented by the granted master.
        // Lock only if the slave actually took it.
        if (out_req_ack && (out_resp == SCR1_MEM_RESP_NOTRDY))
            locked <= 1'b1;
    end else begin
        // Bus idle: round-robin so neither side starves
        if (m0_req & m1_req)
            grant <= ~grant;
        else if (m0_req)
            grant <= 1'b0;
        else if (m1_req)
            grant <= 1'b1;
    end
end

//------------------------------------------------------------------------------
// Request multiplexing
//------------------------------------------------------------------------------
assign out_req   = grant ? m1_req   : m0_req;
assign out_cmd   = grant ? m1_cmd   : m0_cmd;
assign out_width = grant ? m1_width : m0_width;
assign out_addr  = grant ? m1_addr  : m0_addr;
assign out_wdata = grant ? m1_wdata : m0_wdata;

assign m0_req_ack = ~grant & out_req_ack;
assign m1_req_ack =  grant & out_req_ack;

//------------------------------------------------------------------------------
// Response routing - only to the master that owns the transaction
//------------------------------------------------------------------------------
assign m0_rdata = out_rdata;
assign m1_rdata = out_rdata;
assign m0_resp  = grant ? SCR1_MEM_RESP_NOTRDY : out_resp;
assign m1_resp  = grant ? out_resp : SCR1_MEM_RESP_NOTRDY;


endmodule : scr1_dmem_arbiter
`endif // SCR1_MTX_EXT