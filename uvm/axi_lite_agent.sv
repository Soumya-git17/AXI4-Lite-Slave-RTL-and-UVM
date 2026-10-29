class axi_lite_agent extends uvm_agent;
  `uvm_component_utils(axi_lite_agent)
  
  axi_lite_driver 	 m_driver;
  axi_lite_monitor   m_monitor;
  axi_lite_sequencer m_sequencer;
  
  function new(string name = "axi_lite_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (get_is_active()) begin
      m_sequencer = axi_lite_sequencer::type_id::create("m_sequencer", this);
      m_driver	  = axi_lite_driver::type_id::create("m_driver", this);
    end
    m_monitor = axi_lite_monitor::type_id::create("m_monitor", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active()) m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
  endfunction

endclass