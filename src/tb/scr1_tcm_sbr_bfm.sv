/// Copyright by Syntacore LLC © 2016-2021. See LICENSE for details
/// @file       <scr1_tcm_sbr_bfm.sv>
/// @brief      TCM AHB subordinate port - external master BFM
///
/// @details    Behavioral external master model attached to the TCM AHB
///             subordinate (slave) port of the DUT. It is include'd directly
///             into the testbench module (both AHB and AXI top testbenches).
///
///             Features:
///               * Optional image loading with +tcm_sbr_load=<file.hex>
///                 The file uses $readmemh format (@ADDR + byte tokens) with
///                 REAL TCM addresses (0x0048_xxxx -> ITCM, 0x0049_xxxx ->
///                 DTCM). The CPU reset is held while the image is written
///                 through the subordinate port, then released - this covers
///                 the reset-time program loading scenario.
///               * Optional mailbox scenario with +tcm_sbr_test (implied by
///                 +tcm_sbr_load): the BFM prewrites a magic word into DTCM,
///                 the core reads/verifies it and writes an ACK word, then the
///                 BFM writes a mailbox word at runtime while the core is
///                 polling it (covers arbitration between a running core and
///                 the external master).
///               * Read-back checks verify the subordinate read path after
///                 loading and after the core ACK.
///
///             With neither plusarg given the BFM stays completely idle -
///             regular regression tests are not disturbed.
///
///             BFM errors poison the mailbox so that the core-side test
///             fails as well, keeping the standard PASS/FAIL reporting.

`ifdef SCR1_TCM_EN

// DTCM mailbox block: placed in the middle of the DTCM window, far away from
// the .data/.bss image at the bottom and from the stack at the top, so even
// larger tests are not disturbed while the scenario is enabled
localparam logic [31:0]    SCR1_SBR_DTCM_MAGIC_ADDR   = 32'h0049_8000;
localparam logic [31:0]    SCR1_SBR_DTCM_MAGIC_DATA   = 32'hDEAD_BEEF;
localparam logic [31:0]    SCR1_SBR_DTCM_ACK_ADDR     = 32'h0049_8004;
localparam logic [31:0]    SCR1_SBR_DTCM_ACK_DATA     = 32'h1234_5678;
localparam logic [31:0]    SCR1_SBR_DTCM_MAILBOX_ADDR = 32'h0049_8008;
localparam logic [31:0]    SCR1_SBR_DTCM_MAILBOX_DATA = 32'hCAFE_BABE;
localparam logic [31:0]    SCR1_SBR_DTCM_MAILBOX_ERR  = 32'hBAD0_BAD0;
localparam logic [31:0]    SCR1_SBR_DTCM_LOADED_ADDR  = 32'h0049_8010;
localparam logic [31:0]    SCR1_SBR_ITCM_DATA_ADDR    = 32'h0048_F000;
localparam logic [31:0]    SCR1_SBR_ITCM_DATA_VALUE   = 32'h5A5A_A5A5;

string                      tcm_sbr_load_file;
bit                         tcm_sbr_load_en;
bit                         tcm_sbr_test_en;
bit                         cpu_rst_release;
int unsigned                tcm_sbr_errors;
logic                       cpu_rst_n;

// TCM AHB subordinate port signals (driven by the BFM)
logic [3:0]                 tcm_sbr_hprot;
logic [2:0]                 tcm_sbr_hburst;
logic [2:0]                 tcm_sbr_hsize;
logic [1:0]                 tcm_sbr_htrans;
logic                       tcm_sbr_hmastlock;
logic [SCR1_AHB_WIDTH-1:0]  tcm_sbr_haddr;
logic                       tcm_sbr_hwrite;
logic [SCR1_AHB_WIDTH-1:0]  tcm_sbr_hwdata;
logic                       tcm_sbr_hreadyin;
logic                       tcm_sbr_hreadyout;
logic [SCR1_AHB_WIDTH-1:0]  tcm_sbr_hrdata;
logic                       tcm_sbr_hresp;

// Image storage (sparse, real TCM addresses)
bit [7:0]                   tcm_sbr_img [bit [31:0]];


// The CPU reset is held until the BFM finishes reset-time loading
assign cpu_rst_n = rst_n & cpu_rst_release;


task automatic tcm_sbr_ahb_wr (
    input logic [31:0]          addr,
    input logic [31:0]          data
);
    @(posedge clk);
    tcm_sbr_haddr  <= addr;
    tcm_sbr_hwrite <= 1'b1;
    tcm_sbr_hsize  <= SCR1_HSIZE_32B;
    tcm_sbr_htrans <= SCR1_HTRANS_NONSEQ;
    tcm_sbr_hburst <= SCR1_HBURST_SINGLE;
    // Drive the write data already in the address phase: it becomes valid
    // in the data phase (one cycle later) - a cycle earlier than strictly
    // required, which is legal and keeps the data stable through any wait
    // states the slave may insert
    tcm_sbr_hwdata <= data;
    @(posedge clk);
    // The address phase has been taken (HREADYOUT was 1): drop HTRANS now -
    // a compliant master does not keep NONSEQ after the address phase, the
    // completion cycle must carry IDLE (or the next transfer), never a
    // stale NONSEQ that the pipelined slave would sample as a new beat
    tcm_sbr_htrans <= SCR1_HTRANS_IDLE;
    while (tcm_sbr_hreadyout !== 1'b1) @(posedge clk);
    if (tcm_sbr_hresp !== 1'b0) begin
        $write("\033[0;31mTCM_SBR ERROR: write @ %h got ERROR response\033[0m\n", addr);
        tcm_sbr_errors++;
    end
    tcm_sbr_hwrite <= 1'b0;
    tcm_sbr_haddr  <= '0;
    tcm_sbr_hwdata <= '0;
endtask : tcm_sbr_ahb_wr

task automatic tcm_sbr_ahb_rd (
    input  logic [31:0]         addr,
    output logic [31:0]         data
);
    @(posedge clk);
    tcm_sbr_haddr  <= addr;
    tcm_sbr_hwrite <= 1'b0;
    tcm_sbr_hsize  <= SCR1_HSIZE_32B;
    tcm_sbr_htrans <= SCR1_HTRANS_NONSEQ;
    tcm_sbr_hburst <= SCR1_HBURST_SINGLE;
    @(posedge clk);
    // See tcm_sbr_ahb_wr: drop HTRANS right after the address phase
    tcm_sbr_htrans <= SCR1_HTRANS_IDLE;
    while (tcm_sbr_hreadyout !== 1'b1) @(posedge clk);
    // Sample in the middle of the completion cycle: right after a clock
    // edge the combinational HRDATA may not have re-evaluated yet
    @(negedge clk);
    data = tcm_sbr_hrdata;
    if (tcm_sbr_hresp !== 1'b0) begin
        $write("\033[0;31mTCM_SBR ERROR: read @ %h got ERROR response\033[0m\n", addr);
        tcm_sbr_errors++;
    end
    tcm_sbr_haddr  <= '0;
endtask : tcm_sbr_ahb_rd

// INCR burst write: len beats of 32-bit words, SEQ-pipelined. Exercises the
// burst path of the bridge (HTRANS = SEQ beats must all land in the RAM, at
// 2 clocks per beat in the steady state).
task automatic tcm_sbr_ahb_burst_wr (
    input logic [31:0]          addr,
    input int unsigned          len,
    input bit [31:0]            data [16]
);
    @(posedge clk);
    tcm_sbr_haddr  <= addr;
    tcm_sbr_hwrite <= 1'b1;
    tcm_sbr_hsize  <= SCR1_HSIZE_32B;
    tcm_sbr_htrans <= SCR1_HTRANS_NONSEQ;
    tcm_sbr_hburst <= SCR1_HBURST_INCR;
    for (int unsigned i = 0; i < len; i++) begin
        @(posedge clk);
        tcm_sbr_hwdata <= data[i];
        if (i < len-1) begin
            tcm_sbr_haddr  <= addr + ((i+1) * 4);
            tcm_sbr_htrans <= SCR1_HTRANS_SEQ;
        end else begin
            tcm_sbr_htrans <= SCR1_HTRANS_IDLE;
        end
        while (tcm_sbr_hreadyout !== 1'b1) @(posedge clk);
        if (tcm_sbr_hresp !== 1'b0) begin
            $write("\033[0;31mTCM_SBR ERROR: burst write beat %0d @ %h got ERROR\033[0m\n",
                   i, addr + (i * 4));
            tcm_sbr_errors++;
        end
    end
    tcm_sbr_hwrite <= 1'b0;
    tcm_sbr_haddr  <= '0;
    tcm_sbr_hwdata <= '0;
endtask : tcm_sbr_ahb_burst_wr

// INCR burst read: returns len words collected on the completion cycles
task automatic tcm_sbr_ahb_burst_rd (
    input  logic [31:0]         addr,
    input  int unsigned         len,
    output bit [31:0]           data [16]
);
    @(posedge clk);
    tcm_sbr_haddr  <= addr;
    tcm_sbr_hwrite <= 1'b0;
    tcm_sbr_hsize  <= SCR1_HSIZE_32B;
    tcm_sbr_htrans <= SCR1_HTRANS_NONSEQ;
    tcm_sbr_hburst <= SCR1_HBURST_INCR;
    for (int unsigned i = 0; i < len; i++) begin
        @(posedge clk);
        if (i < len-1) begin
            tcm_sbr_haddr  <= addr + ((i+1) * 4);
            tcm_sbr_htrans <= SCR1_HTRANS_SEQ;
        end else begin
            tcm_sbr_htrans <= SCR1_HTRANS_IDLE;
        end
        // Beat completion is polled mid-cycle (negedge); HRDATA of the
        // completion cycle is stable there
        @(negedge clk);
        while (tcm_sbr_hreadyout !== 1'b1) @(negedge clk);
        data[i] = tcm_sbr_hrdata;
        if (tcm_sbr_hresp !== 1'b0) begin
            $write("\033[0;31mTCM_SBR ERROR: burst read beat %0d @ %h got ERROR\033[0m\n",
                   i, addr + (i * 4));
            tcm_sbr_errors++;
        end
    end
    tcm_sbr_haddr  <= '0;
endtask : tcm_sbr_ahb_burst_rd

// Misaligned-transfer check: HSIZE = word with HADDR[1:0] != 0 must be
// answered with a two-cycle ERROR (an AHB requirement violated by the
// master), never with silently rotated data
task automatic tcm_sbr_misaligned_test (
    input logic [31:0]          addr
);
    @(posedge clk);
    tcm_sbr_haddr  <= addr;
    tcm_sbr_hwrite <= 1'b0;
    tcm_sbr_hsize  <= SCR1_HSIZE_32B;
    tcm_sbr_htrans <= SCR1_HTRANS_NONSEQ;
    tcm_sbr_hburst <= SCR1_HBURST_SINGLE;
    @(posedge clk);
    tcm_sbr_htrans <= SCR1_HTRANS_IDLE;
    // ERR1 (HREADYOUT=0, HRESP=1) then ERR2 (HREADYOUT=1, HRESP=1),
    // polled mid-cycle (negedge)
    @(negedge clk);
    while (!(tcm_sbr_hreadyout === 1'b1 && tcm_sbr_hresp === 1'b1)) begin
        @(negedge clk);
    end
    $write("\033[0;34mTCM_SBR: misaligned read @ %h correctly answered with ERROR\033[0m\n", addr);
    tcm_sbr_haddr  <= '0;
endtask : tcm_sbr_misaligned_test

task automatic tcm_sbr_check (
    input string                what,
    input logic [31:0]          addr,
    input logic [31:0]          exp
);
    logic [31:0] data;
    tcm_sbr_ahb_rd(addr, data);
    if (data !== exp) begin
        $write("\033[0;31mTCM_SBR ERROR: %s read-back @ %h: got %h, expected %h\033[0m\n",
               what, addr, data, exp);
        tcm_sbr_errors++;
    end
endtask : tcm_sbr_check

// Parse a $readmemh-style hex file (@ADDR + byte tokens) into the sparse
// image array
task automatic tcm_sbr_parse_file (
    input string                fname
);
    int     fd;
    string  line;
    string  tok;
    int     byte_cnt;
    logic [31:0] cur_addr;
    logic [31:0] byte_val;
    fd = $fopen(fname, "r");
    if (fd == 0) begin
        $write("\033[0;31mTCM_SBR ERROR: cannot open image file %s\033[0m\n", fname);
        tcm_sbr_errors++;
        return;
    end
    cur_addr = '0;
    while ($fgets(line, fd)) begin
        // strip trailing newline / CR
        while (line.len() > 0 && (line[line.len()-1] == "\n"
               || line[line.len()-1] == "\r")) begin
            line = line.substr(0, line.len()-2);
        end
        if (line.len() == 0) continue;
        if (line.len() > 1 && line[0] == "@") begin
            cur_addr = line.substr(1, line.len()-1).atohex();
        end else begin
            byte_cnt = 0;
            tok = "";
            for (int i = 0; i <= line.len(); i++) begin
                if (i == line.len() || line[i] == " " || line[i] == "\t") begin
                    if (tok.len() > 0) begin
                        byte_val = tok.atohex();
                        tcm_sbr_img[cur_addr] = byte_val[7:0];
                        cur_addr++;
                        byte_cnt++;
                        tok = "";
                    end
                end else begin
                    tok = {tok, line[i]};
                end
            end
        end
    end
    $fclose(fd);
endtask : tcm_sbr_parse_file

task automatic tcm_sbr_load_image ();
    // Write the parsed image as 32-bit words; a word is written when at least
    // one of its bytes is present in the image
    logic [31:0] word;
    bit          any;
    for (logic [31:0] a = 32'h0048_0000; a < 32'h004A_0000; a += 4) begin
        any  = tcm_sbr_img.exists(a)   | tcm_sbr_img.exists(a+1)
             | tcm_sbr_img.exists(a+2) | tcm_sbr_img.exists(a+3);
        if (any) begin
            word = '0;
            if (tcm_sbr_img.exists(a))   word[7:0]   = tcm_sbr_img[a];
            if (tcm_sbr_img.exists(a+1)) word[15:8]  = tcm_sbr_img[a+1];
            if (tcm_sbr_img.exists(a+2)) word[23:16] = tcm_sbr_img[a+2];
            if (tcm_sbr_img.exists(a+3)) word[31:24] = tcm_sbr_img[a+3];
            tcm_sbr_ahb_wr(a, word);
        end
    end
endtask : tcm_sbr_load_image

initial begin
    tcm_sbr_hprot     = '0;
    tcm_sbr_hburst    = SCR1_HBURST_SINGLE;
    tcm_sbr_hsize     = SCR1_HSIZE_32B;
    tcm_sbr_htrans    = SCR1_HTRANS_IDLE;
    tcm_sbr_hmastlock = 1'b0;
    tcm_sbr_haddr     = '0;
    tcm_sbr_hwrite    = 1'b0;
    tcm_sbr_hwdata    = '0;
    tcm_sbr_hreadyin  = 1'b1;
    tcm_sbr_errors    = 0;
    tcm_sbr_load_en   = 0;
    tcm_sbr_test_en   = 0;
    cpu_rst_release   = 1'b1;

    if ($test$plusargs("tcm_sbr_test")) begin
        tcm_sbr_test_en = 1;
    end
    if ($value$plusargs("tcm_sbr_load=%s", tcm_sbr_load_file)) begin
        tcm_sbr_load_en = 1;
        tcm_sbr_test_en = 1;
        cpu_rst_release = 1'b0;
    end
end

// Reset-time loading + runtime mailbox scenario
initial begin : tcm_sbr_scenario
    string what;
    logic [31:0] data;
    bit          ack_seen;

    // Wait until the scenario is enabled: either by plusarg (initial block
    // above) or by the auto-detection block watching for the tcm_sbr test
    if (!tcm_sbr_test_en) begin
        forever begin
            @(posedge clk);
            if (tcm_sbr_test_en) break;
        end
    end

    // Synchronize with the test launch reset sequence
    wait (rst_n === 1'b0);
    wait (rst_n === 1'b1);
    repeat (10) @(posedge clk);

    if (tcm_sbr_load_en) begin
        $write("\033[0;34mTCM_SBR: loading image %s through the subordinate port (CPU held in reset)\033[0m\n",
               tcm_sbr_load_file);
    end

    // Reset-time DTCM/ITCM writes (cover the slave write path). The whole
    // mailbox block is initialized so the core never reads uninitialized
    // (X) memory - in load mode the image is written afterwards and
    // overwrites the loaded word with its own value
    tcm_sbr_ahb_wr(SCR1_SBR_DTCM_MAGIC_ADDR,   SCR1_SBR_DTCM_MAGIC_DATA);
    tcm_sbr_ahb_wr(SCR1_SBR_DTCM_MAILBOX_ADDR, 32'h0);
    tcm_sbr_ahb_wr(SCR1_SBR_DTCM_ACK_ADDR,     32'h0);
    tcm_sbr_ahb_wr(SCR1_SBR_DTCM_LOADED_ADDR,  32'h0);
    tcm_sbr_ahb_wr(SCR1_SBR_ITCM_DATA_ADDR,    SCR1_SBR_ITCM_DATA_VALUE);

    if (tcm_sbr_load_en) begin
        tcm_sbr_parse_file(tcm_sbr_load_file);
        tcm_sbr_load_image();
        tcm_sbr_check("image load", SCR1_SBR_DTCM_LOADED_ADDR, 32'h1122_3344);
        $write("\033[0;34mTCM_SBR: image loaded\033[0m\n");
    end

    // Slave read-back check of the reset-time writes
    tcm_sbr_check("reset write", SCR1_SBR_DTCM_MAGIC_ADDR,   SCR1_SBR_DTCM_MAGIC_DATA);
    tcm_sbr_check("reset write", SCR1_SBR_ITCM_DATA_ADDR,    SCR1_SBR_ITCM_DATA_VALUE);

    // ---- Burst coverage (SEQ beats must all land in the RAM) ----
    begin : burst_coverage
        bit [31:0] wdat [16];
        bit [31:0] rdat [16];
        // DTCM burst block, far from the mailbox and the core data
        logic [31:0] baddr;
        int unsigned blen;
        for (int unsigned j = 0; j < 16; j++) rdat[j] = '0;
        baddr = 32'h0049_8100;
        blen  = 16;
        for (int unsigned i = 0; i < blen; i++) begin
            wdat[i] = 32'hB000_0000 + i * 32'h0101_0101;
        end
        tcm_sbr_ahb_burst_wr(baddr, blen, wdat);
        tcm_sbr_ahb_burst_rd(baddr, blen, rdat);
        for (int unsigned i = 0; i < blen; i++) begin
            if (rdat[i] !== wdat[i]) begin
                $write("\033[0;31mTCM_SBR ERROR: burst beat %0d: got %h, expected %h\033[0m\n",
                       i, rdat[i], wdat[i]);
                tcm_sbr_errors++;
            end
        end
        if (tcm_sbr_errors == 0) begin
            $write("\033[0;34mTCM_SBR: %0d-beat INCR burst write+readback OK\033[0m\n", blen);
        end
    end

    // ---- Misaligned-transfer coverage (must answer ERROR) ----
    tcm_sbr_misaligned_test(32'h0049_8002);

    // Release the CPU: the core starts running from RAM/ITCM
    cpu_rst_release = 1'b1;
    $write("\033[0;34mTCM_SBR: CPU reset released\033[0m\n");

    // Wait for the core ACK word (the core verified the magic value and is
    // now polling the mailbox)
    ack_seen = 1'b0;
    for (int unsigned i = 0; i < 100000; i++) begin
        tcm_sbr_ahb_rd(SCR1_SBR_DTCM_ACK_ADDR, data);
        if (data == SCR1_SBR_DTCM_ACK_DATA) begin
            ack_seen = 1'b1;
            break;
        end
        repeat (100) @(posedge clk);
    end
    if (!ack_seen) begin
        $write("\033[0;31mTCM_SBR ERROR: core ACK timeout\033[0m\n");
        tcm_sbr_errors++;
    end else begin
        $write("\033[0;34mTCM_SBR: core ACK seen, writing runtime mailbox\033[0m\n");
    end

    // Core is running and polling - write the mailbox at runtime (covers TCM
    // arbitration with an active core)
    if (tcm_sbr_errors == 0) begin
        tcm_sbr_ahb_wr(SCR1_SBR_DTCM_MAILBOX_ADDR, SCR1_SBR_DTCM_MAILBOX_DATA);
    end else begin
        tcm_sbr_ahb_wr(SCR1_SBR_DTCM_MAILBOX_ADDR, SCR1_SBR_DTCM_MAILBOX_ERR);
    end

    tcm_sbr_check("core ACK", SCR1_SBR_DTCM_ACK_ADDR, SCR1_SBR_DTCM_ACK_DATA);

    if (tcm_sbr_errors != 0) begin
        $write("\033[0;31mTCM_SBR: %0d BFM error(s) detected\033[0m\n", tcm_sbr_errors);
    end else begin
        $write("\033[0;32mTCM_SBR: BFM scenario completed without errors\033[0m\n");
    end
end

// Auto-enable the scenario when the tcm_sbr test is launched by the regular
// regression flow (no plusargs needed)
`ifndef VERILATOR
initial begin : tcm_sbr_autodetect
    forever begin
        @(posedge clk);
        if (test_running && !tcm_sbr_test_en
            && test_file.len() >= 7
            && test_file.substr(0, 6) == "tcm_sbr") begin
            tcm_sbr_test_en = 1'b1;
            cpu_rst_release = 1'b0;
            $write("\033[0;34mTCM_SBR: scenario auto-enabled for %s\033[0m\n", test_file);
        end
    end
end
`endif // VERILATOR

`endif // SCR1_TCM_EN