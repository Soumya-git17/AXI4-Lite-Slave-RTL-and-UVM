`include "uvm_macros.svh"
import uvm_pkg::*;
import axi_lite_pkg::*;
import axi_lite_uvm_pkg::*;

module tb_top;
  axi_lite_if axi_if();
  axi_lite_slave_top dut(.axi_if(axi_if));
  
  initial axi_if.ACLK = 0;
  always #5 axi_if.ACLK = ~axi_if.ACLK;
  
  initial begin
    axi_if.ARESETn = 0;
    repeat (5) @(posedge axi_if.ACLK);
    @(negedge axi_if.ACLK);
    axi_if.ARESETn = 1;
  end
  
  initial begin
    uvm_config_db #(virtual axi_lite_if)::set(null, "*", "vif", axi_if);
    run_test("axi_lite_test");
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
  
endmodule