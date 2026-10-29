class axi_lite_test extends uvm_test;
  `uvm_component_utils(axi_lite_test)
  
  axi_lite_env m_env;
  
  function new(string name = "axi_lite_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = axi_lite_env::type_id::create("m_env", this);
  endfunction
  
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  virtual task run_phase(uvm_phase phase);
    // axi_lite_sequence m_seq = axi_lite_sequence::type_id::create("m_seq");
    axi_lite_rand_seq m_seq = axi_lite_rand_seq::type_id::create("m_seq");
    m_seq.num_items = 50;
    m_seq.set_starting_phase(phase);
    m_seq.start(m_env.m_agent.m_sequencer);
  endtask

endclass