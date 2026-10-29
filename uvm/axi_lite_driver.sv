class axi_lite_driver extends uvm_driver #(axi_lite_item);
  `uvm_component_utils(axi_lite_driver)
  virtual axi_lite_if vif;
  
  function new(string name = "axi_lite_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface axi_lite_if")
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    axi_lite_item req;
    init_signals();
    wait(vif.ARESETn === 1'b1);
    forever begin
      seq_item_port.get_next_item(req);
      if (req.is_write) drive_write(req);
      else drive_read(req);
      seq_item_port.item_done();
    end
  endtask
  
  task init_signals();
    vif.AWADDR  <= 0;
    vif.AWVALID <= 0;
    vif.WDATA   <= 0;
    vif.WSTRB   <= 0;
    vif.WVALID  <= 0;
    vif.BREADY  <= 0;
    vif.ARADDR  <= 0;
    vif.ARVALID <= 0;
    vif.RREADY  <= 0;
  endtask
  
  task drive_read(axi_lite_item item);
    @(posedge vif.ACLK);
    vif.ARADDR  <= item.addr;
    vif.ARVALID <= 1;
    do @(posedge vif.ACLK); while(!vif.ARREADY);
    vif.ARVALID <= 0;
    vif.RREADY  <= 1;
    do @(posedge vif.ACLK); while(!vif.RVALID);
    item.rdata   = vif.RDATA;
    item.resp    = vif.RRESP;
    vif.RREADY	<= 0;
  endtask
  
  task drive_write(axi_lite_item item);
    fork
      drive_aw(item);
      drive_w(item);
    join
    
    vif.BREADY  <= 1;
    do @(posedge vif.ACLK); while(!vif.BVALID);
    item.resp    = vif.BRESP;
    vif.BREADY	<= 0;
  endtask
  
    
  task drive_aw(axi_lite_item item);  
    @(posedge vif.ACLK);
    vif.AWADDR  <= item.addr;
    vif.AWVALID <= 1;
    do @(posedge vif.ACLK); while(!vif.AWREADY);
    vif.AWVALID <= 0;
  endtask
    
  task drive_w(axi_lite_item item);
    @(posedge vif.ACLK);
    vif.WDATA  <= item.data;
    vif.WSTRB  <= item.strb;
    vif.WVALID <= 1;
    do @(posedge vif.ACLK); while(!vif.WREADY);
    vif.WVALID <= 0;
  endtask
    
endclass