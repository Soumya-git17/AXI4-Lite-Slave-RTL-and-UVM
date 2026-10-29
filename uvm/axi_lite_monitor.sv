class axi_lite_monitor extends uvm_monitor;
  `uvm_component_utils(axi_lite_monitor)
  virtual axi_lite_if vif;
  uvm_analysis_port #(axi_lite_item) ap;

  bit [ADDR_WIDTH-1:0] aw_q [$];
  bit [ADDR_WIDTH-1:0] ar_q [$];
  bit [DATA_WIDTH-1:0] w_data_q [$];
  bit [STRB_WIDTH-1:0] w_strb_q [$];
  
  function new(string name = "axi_lite_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db #(virtual axi_lite_if)::get(this, "", "vif", vif)) `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface axi_lite_if")
  endfunction

  virtual task run_phase(uvm_phase phase);
    wait (vif.ARESETn === 1'b1);
    fork
      mon_aw();
      mon_w();
      mon_b();
      mon_ar();
      mon_r();
    join
  endtask
  
  task mon_aw();
  	forever begin
      @(posedge vif.ACLK);
      if (vif.AWVALID && vif.AWREADY) aw_q.push_back(vif.AWADDR);
    end
  endtask
  
  task mon_w();
  	forever begin
      @(posedge vif.ACLK);
      if (vif.WVALID && vif.WREADY) begin
        w_data_q.push_back(vif.WDATA);
        w_strb_q.push_back(vif.WSTRB);
      end
    end
  endtask
  
  task mon_b();
    axi_lite_item item;
    forever begin
  	  @(posedge vif.ACLK);
      if (vif.BVALID && vif.BREADY) begin
        if (aw_q.size() == 0) begin
          `uvm_error(get_type_name, "B handshake with no pending AW")
        end
        else if (w_data_q.size() == 0) begin
          `uvm_error(get_type_name(), "B handshake with no pending W data")
        end
        else begin
          item = axi_lite_item::type_id::create("mon_wr_item");
          item.is_write = 1;
          item.addr     = aw_q.pop_front();
          item.data 	= w_data_q.pop_front();
          item.strb		= w_strb_q.pop_front();
          item.resp  	= vif.BRESP;
          ap.write(item);
        end
      end
    end
  endtask
  
  task mon_ar();
  	forever begin
      @(posedge vif.ACLK);
      if (vif.ARVALID && vif.ARREADY) ar_q.push_back(vif.ARADDR);
    end
  endtask
  
  task mon_r();
  	axi_lite_item item; 
    forever begin
      @(posedge vif.ACLK);
      if (vif.RVALID && vif.RREADY) begin
        if (ar_q.size() == 0) `uvm_error(get_type_name, "R handshake with no pending AR")
        else begin
          item = axi_lite_item::type_id::create("mon_rd_item");
          item.is_write = 0;
          item.addr     = ar_q.pop_front();
          item.rdata 	= vif.RDATA;
          item.resp  	= vif.RRESP;
          ap.write(item);
        end
      end
    end
  endtask   
    
endclass