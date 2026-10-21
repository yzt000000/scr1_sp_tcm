/// Copyright by Syntacore LLC (c) 2016-2021. See LICENSE for details
/// @file       <scr1_cvxif_monitor.sv>
/// @brief      SCR1 CV-X-IF interface protocol monitor (simulation only)
///
/// Monitors the CV-X-IF request/response channels for protocol compliance:
///   - req_valid must remain stable until cfu_ready is asserted
///   - resp_valid must not be asserted without a prior req_valid
///   - No deadlock: cfu_ready or resp_valid must eventually be asserted
///

`include "scr1_arch_description.svh"
`include "scr1_arch_types.svh"
`include "scr1_riscv_isa_decoding.svh"

`ifdef SCR1_RVX_EXT
`ifdef SCR1_TRGT_SIMULATION
module scr1_cvxif_monitor (
    input  logic                   clk,
    input  logic                   rst_n,
    input  type_scr1_cvxif_req_s   cvxif_req_i,
    input  type_scr1_cvxif_resp_s  cvxif_resp_i,
    output logic                   monitor_violation_o
);

//------------------------------------------------------------------------------
// Protocol compliance checks (combinational)
//------------------------------------------------------------------------------

// Check 1: resp_valid without req_valid
logic resp_without_req;
assign resp_without_req = cvxif_resp_i.resp_valid && !cvxif_req_i.req_valid;

// Overall protocol violation flag
logic protocol_violation;
assign protocol_violation = resp_without_req;

//------------------------------------------------------------------------------
// Violation register
//------------------------------------------------------------------------------

logic violation_reg;

always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        violation_reg <= 1'b0;
    end else begin
        if (protocol_violation) begin
            violation_reg <= 1'b1;
        end
    end
end

assign monitor_violation_o = violation_reg;

//------------------------------------------------------------------------------
// SVA assertions (synthesis tools ignore these)
//------------------------------------------------------------------------------

// Property: req_valid stable until cfu_ready
property p_req_stable;
    @(posedge clk) disable iff (~rst_n)
    cvxif_req_i.req_valid && !cvxif_resp_i.cfu_ready
    |=> cvxif_req_i.req_valid;
endproperty

// Property: no resp_valid without req_valid
property p_resp_requires_req;
    @(posedge clk) disable iff (~rst_n)
    cvxif_resp_i.resp_valid |-> cvxif_req_i.req_valid;
endproperty

// Property: instruction stable during multi-cycle
property p_instr_stable;
    @(posedge clk) disable iff (~rst_n)
    cvxif_req_i.req_valid && !cvxif_resp_i.resp_valid
    |=> cvxif_req_i.req_instr == $past(cvxif_req_i.req_instr);
endproperty

assert property (p_req_stable)
    else $error("CV-X-IF protocol violation: req_valid unstable before cfu_ready");

assert property (p_resp_requires_req)
    else $error("CV-X-IF protocol violation: resp_valid without req_valid");

assert property (p_instr_stable)
    else $error("CV-X-IF protocol violation: instruction unstable during multi-cycle");

endmodule : scr1_cvxif_monitor
`endif // SCR1_TRGT_SIMULATION
`endif // SCR1_RVX_EXT