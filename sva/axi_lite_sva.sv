import axi_lite_pkg::*;

module axi_lite_sva (axi_lite_if axi_if);

wire clk = axi_if.ACLK;
wire rst_n = axi_if.ARESETn;

wire aw_hs = axi_if.AWVALID && axi_if.AWREADY;
wire  w_hs = axi_if.WVALID  && axi_if.WREADY;
wire  b_hs = axi_if.BVALID  && axi_if.BREADY;
wire ar_hs = axi_if.ARVALID && axi_if.ARREADY;
wire  r_hs = axi_if.RVALID  && axi_if.RREADY;

int unsigned aw_cnt, w_cnt, b_cnt, ar_cnt, r_cnt;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) {aw_cnt, w_cnt, b_cnt, ar_cnt, r_cnt} <= '0;
    else begin
        if (aw_hs) aw_cnt <= aw_cnt + 1;
        if (w_hs)   w_cnt <=  w_cnt + 1;
        if (b_hs)   b_cnt <=  b_cnt + 1;
        if (ar_hs) ar_cnt <= ar_cnt + 1;
        if (r_hs)   r_cnt <=  r_cnt + 1;
    end
end

default clocking cb @(posedge clk); endclocking
default disable iff (!rst_n);

a_aw_stable: assert property (
    axi_if.AWVALID && !axi_if.AWREADY |=> axi_if.AWVALID && $stable(axi_if.AWADDR)
) else $error("AW: AWVALID dropped or AWADDR changed before AWREADY");

a_w_stable: assert property (
    axi_if.WVALID && !axi_if.WREADY |=> axi_if.WVALID && $stable(axi_if.WDATA) && $stable(axi_if.WSTRB)
) else $error("W: WVALID dropped or WDATA/WSTRB changed before WREADY");

a_b_stable: assert property (
    axi_if.BVALID && !axi_if.BREADY |=> axi_if.BVALID && $stable(axi_if.BRESP)
) else $error("B: BVALID dropped or BRESP changed before BREADY");

a_ar_stable: assert property (
    axi_if.ARVALID && !axi_if.ARREADY |=> axi_if.ARVALID && $stable(axi_if.ARADDR)
) else $error("AR: ARVALID dropped or ARADDR changed before ARREADY");

a_r_stable: assert property (
    axi_if.RVALID && !axi_if.RREADY |=> axi_if.RVALID && $stable(axi_if.RDATA) && $stable(axi_if.RRESP)
) else $error("R: RVALID dropped or RDATA/RRESP changed before RREADY");


a_b_after_req: assert property (
    axi_if.BVALID |-> (aw_cnt > b_cnt) && (w_cnt > b_cnt)
) else $error("B: BVALID without a complete AW or W");

a_r_after_ar: assert property (
    axi_if.RVALID |-> (ar_cnt > r_cnt)
) else $error("R: RVALID without a complete AR");

a_bresp_legal: assert property (
    axi_if.BVALID |-> axi_if.BRESP inside {RESP_OKAY, RESP_DECERR}
) else $error("B: illegal BRESP");

a_rresp_legal: assert property (
    axi_if.RVALID |-> axi_if.RRESP inside {RESP_OKAY, RESP_DECERR}
) else $error("R: illegal RRESP");

a_reset_outputs_low: assert property (@(posedge axi_if.ACLK) disable iff (1'b0)
    !axi_if.ARESETn |-> !axi_if.BVALID && !axi_if.RVALID
) else $error("RESET: BVALID or RVALID high while reset asserted");


a_no_wr_while_b: assert property (
    axi_if.BVALID |-> !axi_if.AWREADY && !axi_if.WREADY
) else $error("B: AWREADY/WREADY high while BVALID pending");

a_no_rd_while_r: assert property (
    axi_if.RVALID |-> !axi_if.ARREADY
) else $error("R: ARREADY high while RVALID pending");

a_b_latency: assert property (
    $rose((aw_cnt > b_cnt) && (w_cnt > b_cnt)) |-> ##[0:3] axi_if.BVALID
) else $error("B: BVALID did not rise in time after AW and W");

a_r_latency: assert property (
    ar_hs |-> ##[1:4] axi_if.RVALID
) else $error("R: RVALID did not rise in time after AR");

a_no_x_outputs: assert property (
    !$isunknown({axi_if.AWREADY, axi_if.WREADY, axi_if.ARREADY, axi_if.BVALID, axi_if.RVALID})
) else $error("X/Z on a slave output after reset");

a_master_quiet_in_reset: assert property (@(posedge clk) disable iff (1'b0)
    !axi_if.ARESETn |-> !axi_if.AWVALID && !axi_if.WVALID && !axi_if.ARVALID
) else $error("RESET: master VALID high while reset asserted");

a_b_oneshot: assert property (
    b_hs |=> !axi_if.BVALID
) else $error("B: BVALID still high after the response was accepted");

a_r_oneshot: assert property (
    r_hs |=> !axi_if.RVALID
) else $error("R: RVALID still high after the response was accepted");


c_aw_hs:    cover property (aw_hs);
c_w_hs:     cover property (w_hs) ;
c_b_hs:     cover property (b_hs);
c_ar_hs:    cover property (ar_hs);
c_r_hs:     cover property (r_hs);
c_same_cycle: cover property (aw_hs && w_hs);
c_aw_first: cover property (aw_hs && !w_hs && (aw_cnt == w_cnt) ##[1:8] w_hs);
c_w_first:  cover property (w_hs && !aw_hs && (aw_cnt == w_cnt) ##[1:8] aw_hs);
c_bresp_decerr: cover property (b_hs && axi_if.BRESP == RESP_DECERR);
c_rresp_decerr: cover property (r_hs && axi_if.RRESP == RESP_DECERR);
c_aw_stall: cover property (axi_if.AWVALID && !axi_if.AWREADY);
c_w_stall:  cover property (axi_if.WVALID  && !axi_if.WREADY);
c_ar_stall: cover property (axi_if.ARVALID && !axi_if.ARREADY);
c_b_stall:  cover property (axi_if.BVALID  && !axi_if.BREADY);
c_r_stall:  cover property (axi_if.RVALID  && !axi_if.RREADY);
c_write_complete_req: cover property ($rose((aw_cnt > b_cnt) && (w_cnt > b_cnt)));
c_b_stall_long: cover property ((axi_if.BVALID && !axi_if.BREADY)[*3]);
c_r_stall_long: cover property ((axi_if.RVALID && !axi_if.RREADY)[*3]);
c_b2b_write:   cover property (b_hs ##[1:4] aw_hs);
c_b2b_read:    cover property (r_hs ##[1:4] ar_hs);
c_wr_then_rd:  cover property (b_hs ##[1:4] ar_hs);
c_rd_then_wr:  cover property (r_hs ##[1:4] (aw_hs || w_hs));
c_awfirst_bstall: cover property (
    (aw_hs && !w_hs && (aw_cnt == w_cnt)) ##[1:8] w_hs
    ##[1:6] (axi_if.BVALID && !axi_if.BREADY));
c_wfirst_bstall: cover property (
    (w_hs && !aw_hs && (aw_cnt == w_cnt)) ##[1:8] aw_hs
    ##[1:6] (axi_if.BVALID && !axi_if.BREADY));

endmodule