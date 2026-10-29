class axi_lite_rand_seq extends uvm_sequence #(axi_lite_item);
  `uvm_object_utils(axi_lite_rand_seq)
  
  int unsigned num_items = 50;
  bit [ADDR_WIDTH-1:0] written_q [$];
  
  function new(string name = "axi_lite_rand_seq");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    uvm_phase starting_phase = get_starting_phase();
    if (starting_phase != null) starting_phase.raise_objection(this);
  endtask
  
  virtual task body();
    axi_lite_item item;
    bit do_write;
    bit [ADDR_WIDTH-1:0] rd_addr;
    
    repeat (num_items) begin
      do_write = (written_q.size() == 0) || ($urandom_range(0,1) == 1);
      
      item = axi_lite_item::type_id::create("item");
      start_item(item);
      if (do_write) begin
        if(!item.randomize() with {is_write == 1;}) `uvm_fatal(get_type_name(), "Randomization failed")
      end else begin
        rd_addr = written_q[$urandom_range(0, written_q.size()-1)];
        if (!item.randomize() with {is_write == 0; addr == rd_addr;}) `uvm_fatal(get_type_name(), "Randomization failed")
      end
      finish_item(item);
      if (item.is_write) written_q.push_back(item.addr);
      else `uvm_info(get_type_name(), {"read back: ", item.convert2string()}, UVM_LOW)
    end
  endtask
  
  virtual task post_body();
    uvm_phase starting_phase = get_starting_phase();
    if (starting_phase != null) starting_phase.drop_objection(this);
  endtask
  
endclass