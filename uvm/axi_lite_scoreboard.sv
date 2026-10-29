class axi_lite_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi_lite_scoreboard)
  uvm_analysis_imp #(axi_lite_item, axi_lite_scoreboard) ap_imp;
  
  bit [DATA_WIDTH-1:0] model [NUM_REGS];
  int unsigned wr_count, rd_count, error_count;
  
  function new(string name = "axi_lite_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap_imp = new("ap_imp", this);
    foreach(model[i]) model[i] = '0;
  endfunction
  
  function bit is_valid_addr(bit [ADDR_WIDTH-1:0] a);
    return (a[1:0] == 2'b00) && (a <= 32'h3C);
  endfunction
  
  virtual function void write(axi_lite_item item);
    int idx = item.addr[5:2];
    if (item.is_write) begin
      wr_count++;
      if (is_valid_addr(item.addr)) begin
        if (item.resp != RESP_OKAY) begin
          `uvm_error(get_type_name(), $sformatf("WR addr=0x%08h: expected OKAY, got %s", item.addr, item.resp.name()))
          error_count++;
        end
        for (int b = 0; b < STRB_WIDTH; b++) begin
          if (item.strb[b]) model[idx][8*b +: 8] = item.data[8*b +: 8];
        end
      end else begin
        if (item.resp != RESP_DECERR) begin
           `uvm_error(get_type_name(), $sformatf("WR addr=0x%08h: expected DECERR, got %s", item.addr, item.resp.name()))
        	error_count++;
      	end
      end
    end 
    else begin
      rd_count++;
      if (is_valid_addr(item.addr)) begin
        if (item.resp != RESP_OKAY) begin
          `uvm_error(get_type_name(), $sformatf("RD addr=0x%08h: expected OKAY, got %s", item.addr, item.resp.name()))
          error_count++;
        end
        if (item.rdata != model[idx]) begin
          `uvm_error(get_type_name(), $sformatf("RD addr=0x%08h: expected data 0x%08h, got 0x%08h", item.addr, model[idx], item.rdata))
     	  error_count++;
    	end        
      end else begin
        if (item.resp != RESP_DECERR) begin
          `uvm_error(get_type_name(), $sformatf("RD addr=0x%08h: expected DECERR, got %s", item.addr, item.resp.name()))
        	error_count++;
      	end
      end     
    end
  endfunction
  
  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("writes=%0d reads=%0d errors=%0d", wr_count, rd_count, error_count), UVM_LOW)
    if (error_count == 0) begin
      `uvm_info(get_type_name(), "TEST PASSED", UVM_LOW)
    end else begin
      `uvm_error(get_type_name(), "TEST FAILED")
    end
  endfunction  

endclass