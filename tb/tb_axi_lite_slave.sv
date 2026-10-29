import axi_lite_pkg::*;

module tb_axi_lite_slave;
axi_lite_if axi_if();
axi_lite_slave_top dut(.axi_if(axi_if.slave));

initial begin
    axi_if.ACLK = 1'b0;
    forever #5 axi_if.ACLK = ~axi_if.ACLK;
end

task automatic axi_write_aw_first(
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data,
    input logic [STRB_WIDTH-1:0] strb
);
    axi_if.AWADDR = addr;
    axi_if.AWVALID = 1'b1;

    // repeat (2) @(posedge axi_if.ACLK);
    // axi_if.AWADDR = 32'hDEADBEEF;  // for assertions verifications intentionally changed awaddr

    wait(axi_if.AWVALID && axi_if.AWREADY);
    @(posedge axi_if.ACLK);
    #1;
    axi_if.AWVALID = 1'b0;

    repeat (3) @(posedge axi_if.ACLK);
    #1;
    axi_if.WDATA = data;
    axi_if.WSTRB = strb;
    axi_if.WVALID = 1'b1;

    wait(axi_if.WVALID && axi_if.WREADY);

    @(posedge axi_if.ACLK);
    #1;
    axi_if.WVALID = 1'b0;
    
    axi_if.BREADY = 1'b1;
    wait(axi_if.BVALID && axi_if.BREADY);
    @(posedge axi_if.ACLK);
    #1;
    axi_if.BREADY = 1'b0;
endtask

task automatic axi_write_w_first(
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data,
    input logic [STRB_WIDTH-1:0] strb
);
    axi_if.WDATA = data;
    axi_if.WSTRB = strb;
    axi_if.WVALID = 1'b1;

    wait(axi_if.WVALID && axi_if.WREADY);
    @(posedge axi_if.ACLK);
    #1;
    axi_if.WVALID = 1'b0;    
    
    repeat (3) @(posedge axi_if.ACLK);
    #1;
    axi_if.AWADDR = addr;
    axi_if.AWVALID = 1'b1;

    wait(axi_if.AWVALID && axi_if.AWREADY);
    @(posedge axi_if.ACLK);
    #1;
    axi_if.AWVALID = 1'b0;

    axi_if.BREADY = 1'b1;
    wait(axi_if.BVALID && axi_if.BREADY);
    @(posedge axi_if.ACLK);
    #1;
    axi_if.BREADY = 1'b0;
endtask

task automatic axi_write_both(
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data,
    input logic [STRB_WIDTH-1:0] strb,
    output logic [1:0] resp
);
    axi_if.AWADDR = addr;
    axi_if.AWVALID = 1'b1;

    axi_if.WDATA = data;
    axi_if.WSTRB = strb;
    axi_if.WVALID = 1'b1;
    fork
        begin
            wait (axi_if.AWVALID && axi_if.AWREADY);
            @(posedge axi_if.ACLK);
            #1;
            axi_if.AWVALID = 1'b0;
        end
        begin
            wait (axi_if.WVALID && axi_if.WREADY);
            @(posedge axi_if.ACLK);
            #1;
            axi_if.WVALID = 1'b0;
        end
    join

    axi_if.BREADY = 1'b1;

    wait(axi_if.BVALID && axi_if.BREADY);
    resp = axi_if.BRESP;
    @(posedge axi_if.ACLK);
    #1;
    axi_if.BREADY = 1'b0;
endtask

task automatic axi_read(
    input logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data,
    output logic [1:0] resp
);
    axi_if.ARADDR = addr;
    axi_if.ARVALID = 1'b1;
    wait(axi_if.ARREADY && axi_if.ARVALID);
    @(posedge axi_if.ACLK);
    #1;
    axi_if.ARVALID = 1'b0;
    axi_if.RREADY = 1'b1;

    wait(axi_if.RVALID && axi_if.RREADY);
    data = axi_if.RDATA;
    resp = axi_if.RRESP;
    @(posedge axi_if.ACLK);
    #1;
    axi_if.RREADY = 1'b0;
endtask

initial begin
    axi_if.ARESETn = 1'b0;
    axi_if.AWADDR = '0;
    axi_if.AWVALID = 1'b0;
    
    axi_if.WVALID = '0;
    axi_if.WDATA = '0;
    axi_if.WSTRB = '0;
    
    axi_if.BREADY = 1'b0;
    
    axi_if.ARVALID = 1'b0;
    axi_if.ARADDR = '0;
    
    axi_if.RREADY = 1'b0;
    repeat (2) @(posedge axi_if.ACLK);
    #1;
    axi_if.ARESETn = 1'b1;
end

logic [DATA_WIDTH-1:0] rdata;
int errors = 0;
logic [1:0] bresp, rresp;

task automatic check_read(
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] expected,
    input string test_name
);
    axi_read(addr, rdata, rresp);
    if (rdata != expected) begin
        $error("%s FAILED: Addr=%h Expected=%h Got=%h", test_name, addr, expected, rdata);
        errors++;
    end
    else $display("%s PASSED: Addr=%h Data=%h", test_name, addr, rdata);
endtask

initial begin
    wait(axi_if.ARESETn);

    // TEST 1: AW + W simultaneously
    axi_write_both(32'h00, 32'h11111111, 4'b1111, bresp);
    check_read(32'h00, 32'h11111111, "TEST 1 - AW/W SIMULTANEOUS");

    // TEST 2: AW first
    axi_write_aw_first(32'h00, 32'h12345678, 4'b1111);
    check_read(32'h00, 32'h12345678, "TEST 2 - AW FIRST");

    // TEST 3: W first
    axi_write_w_first(32'h00, 32'h22222222, 4'b1111);
    check_read(32'h00, 32'h22222222, "TEST 3 - W FIRST");
    
    // TEST 4: WSTRB = 0011
    axi_write_both(32'h00, 32'hAAAA5555, 4'b0011, bresp);
    check_read(32'h00, 32'h22225555, "TEST 4 - WSTRB 0011");

    // TEST 5: WSTRB = 1100
    axi_write_both(32'h00, 32'h99999999, 4'b1100, bresp);
    check_read(32'h00, 32'h99995555, "TEST 5 - WSTRB 1100");

    // TEST 6: INVALID WRITE ADDRESS
    axi_write_both(32'h100, 32'hDEADBEEF, 4'b1111, bresp);
    if (bresp !== RESP_DECERR) begin
        $error("TEST 6 FAILED: Expected DECERR, got BRESP=%b", bresp);
        errors++;
    end
    else $display("TEST 6 PASSED: Invalid write returned DECERR");

    // TEST 7: INVALID READ ADDRESS
    axi_read(32'h100, rdata, rresp);
    if (rresp !== RESP_DECERR) begin
        $error("TEST 7 FAILED: Expected DECERR, got RRESP=%b", rresp);
        errors++;
    end
    else $display("TEST 7 PASSED: Invalid read returned DECERR");
    

    if (errors == 0) $display(" ALL AXI-LITE TESTS PASSED");
    else $display(" AXI-LITE VERIFICATION FAILED: %0d errors", errors);
    #20;
    $finish;
end

initial begin
    $dumpfile("axi_lite.vcd");
    $dumpvars(0, tb_axi_lite_slave);
    #1000;
    $finish;
end

// always @(posedge axi_if.ACLK) begin
//     $monitor("TIME=%0t STATE=%0d AWV=%b AWR=%b WV=%b WR=%b AW_REC=%b W_REC=%b BVALID=%b BREADY=%b ARV=%b ARR=%b RV=%b RR=%b",
//             $time, dut.wc.state, axi_if.AWVALID, axi_if.AWREADY, axi_if.WVALID, axi_if.WREADY,
//             dut.wc.aw_received, dut.wc.w_received, axi_if.BVALID, axi_if.BREADY,
//             axi_if.ARVALID, axi_if.ARREADY, axi_if.RVALID, axi_if.RREADY);
// end

endmodule
