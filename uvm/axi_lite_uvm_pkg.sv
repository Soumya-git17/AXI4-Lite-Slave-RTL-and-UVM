package axi_lite_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import axi_lite_pkg::*;

  `include "axi_lite_item.sv"
  `include "axi_lite_sequence.sv"
  `include "axi_lite_rand_seq.sv"
  `include "axi_lite_sequencer.sv"
  `include "axi_lite_driver.sv"
  `include "axi_lite_monitor.sv"
  // `include "axi_lite_coverage.sv"
  `include "axi_lite_agent.sv"
  `include "axi_lite_scoreboard.sv"
  `include "axi_lite_env.sv"
  `include "axi_lite_test.sv"

endpackage