class axi_lite_sequence extends uvm_sequence #(axi_lite_item);
  `uvm_object_utils(axi_lite_sequence)
  
  function new(string name = "axi_lite_sequence");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    uvm_phase starting_phase = get_starting_phase();
    if (starting_phase != null) starting_phase.raise_objection(this);
  endtask
  
  virtual task body();
    axi_lite_item item;

    item = axi_lite_item::type_id::create("wr_item");
    start_item(item);
    if(!item.randomize() with {is_write == 1; addr == 32'h0; data == 32'hDEADBEEF; strb == 4'hF;}) `uvm_fatal(get_type_name(), "Randomization failed")
    finish_item(item);

    item = axi_lite_item::type_id::create("rd_item");
    start_item(item);
    if(!item.randomize() with {is_write == 0; addr == 32'h0;}) `uvm_fatal(get_type_name(), "Randomization failed")
    finish_item(item);

    `uvm_info(get_type_name(), {"read back: ", item.convert2string()}, UVM_LOW)
  endtask
  
  virtual task post_body();
    uvm_phase starting_phase = get_starting_phase();
    if (starting_phase != null) starting_phase.drop_objection(this);
  endtask
  
endclass