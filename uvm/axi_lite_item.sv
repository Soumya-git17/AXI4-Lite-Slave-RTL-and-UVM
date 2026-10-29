class axi_lite_item extends uvm_sequence_item;
  
  rand bit is_write;
  rand bit [ADDR_WIDTH-1:0] addr;
  rand bit [DATA_WIDTH-1:0] data;
  rand bit [STRB_WIDTH-1:0] strb;
  
  resp_t resp;
  bit [DATA_WIDTH-1:0] rdata;
  
  bit valid_addr_only = 1;
  
  `uvm_object_utils_begin(axi_lite_item)
    `uvm_field_int(is_write, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(strb, UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON)
  	`uvm_field_enum(resp_t, resp, UVM_ALL_ON)
  `uvm_object_utils_end
  
  constraint c_addr {
    if (valid_addr_only) {
      addr[1:0] == 2'b00;
      addr inside {[0:'h3C]};
    }
  }
      
  constraint c_rd_clean { if(!is_write) {data == 0; strb == 0;}}
  
  function new(string name = "axi_lite_item");
    super.new(name);
  endfunction
  
  function string convert2string();
    return $sformatf("%s addr=0x%08h data=0x%08h strb=%04b resp=%s rdata=0x%08h", is_write ? "WR" : "RD", addr, data, strb, resp.name(), rdata);
  endfunction
    
endclass