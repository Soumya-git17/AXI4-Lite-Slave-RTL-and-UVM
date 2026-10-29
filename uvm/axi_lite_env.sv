class axi_lite_env extends uvm_env;
  `uvm_component_utils(axi_lite_env)
  
  axi_lite_agent	  m_agent;
  axi_lite_scoreboard m_scoreboard;
  
  function new(string name = "axi_lite_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_agent 	 = axi_lite_agent::type_id::create("m_agent", this);
    m_scoreboard = axi_lite_scoreboard::type_id::create("m_scoreboard", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_agent.m_monitor.ap.connect(m_scoreboard.ap_imp);
  endfunction
  
endclass