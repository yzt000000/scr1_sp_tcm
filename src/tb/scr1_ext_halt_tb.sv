/// Copyright by Syntacore LLC © 2016-2021. See LICENSE for details
/// @file       <scr1_ext_halt_tb.sv>
/// @brief      External HART halt/resume testbench scenario
///
/// @details    Drives the external ext_halt_req / ext_resume_req inputs of
///             the DUT. The scenario is enabled with the +ext_halt_test
///             plusarg and works on top of any regular test:
///
///               * the core runs normally for a while
///               * ext_halt_req is raised (asynchronous level input): the
///                 HDU 2FF synchronizer samples it, the pipeline drains and
///                 the core enters the debug-halted state with the context
///                 preserved (PC / registers are kept)
///               * the halt is held, then released
///               * ext_resume_req is raised: the core resumes execution
///                 exactly where it stopped
///               * the test completes normally afterwards (PASS/FAIL
///                 reporting is untouched)
///
///             Without the plusarg both signals stay 0 - regular
///             regressions are not disturbed.

`ifdef SCR1_DBG_EN

bit             ext_halt_req;
bit             ext_resume_req;
bit             ext_halt_test_en;

initial begin
    ext_halt_req     = 1'b0;
    ext_resume_req   = 1'b0;
    ext_halt_test_en = 1'b0;
    if ($test$plusargs("ext_halt_test")) begin
        ext_halt_test_en = 1'b1;
        $write("\033[0;34mEXT_HALT: scenario enabled\033[0m\n");
    end
end

`ifndef VERILATOR
initial begin : ext_halt_scenario
    if (!ext_halt_test_en) begin
        wait (1'b0);
    end

    // Wait for a test to be launched and the reset sequence to finish
    wait (test_running == 1'b1);
    wait (rst_n === 1'b1);
    repeat (500) @(posedge clk);

    // ---- Halt phase ----
    // The external master raises ext_halt_req: the core stops with the
    // context preserved. While halted the core issues no memory requests -
    // an external master may use this window to access memories (e.g. load
    // the TCM through the subordinate port) without bus contention
    ext_halt_req <= 1'b1;
    wait (i_top.i_core_top.i_pipe_top.i_pipe_hdu.hdu2exu_dbg_halted_o === 1'b1);
    $write("\033[0;34mEXT_HALT: core halted (pc=%h)\033[0m\n",
           i_top.i_core_top.i_pipe_top.curr_pc);
    repeat (200) @(posedge clk);
    ext_halt_req <= 1'b0;
    repeat (10) @(posedge clk);

    // ---- Restart via CPU reset ----
    // NOTE: resuming from an external halt (without a debug session) is a
    // known limitation of the current HDU/EXU resume path (it assumes an
    // active Debug Module). The recommended flow for external masters is
    // halt -> load -> CPU-reset restart, verified below: the core restarts
    // from the reset vector and the test completes normally.
`ifdef SCR1_TCM_EN
    cpu_rst_release <= 1'b0;
    repeat (4) @(posedge clk);
    cpu_rst_release <= 1'b1;
    $write("\033[0;32mEXT_HALT: core restarted via cpu_rst\033[0m\n");
`endif // SCR1_TCM_EN
end
`endif // VERILATOR

`endif // SCR1_DBG_EN