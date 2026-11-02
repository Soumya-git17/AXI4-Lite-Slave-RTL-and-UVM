class axi_lite_coverage extends uvm_subscriber #(axi_lite_item);
    `uvm_component_utils(axi_lite_coverage)

    bit is_write;
    bit [4:0] addr_class;
    bit [3:0] strb;
    resp_t resp;
    int unsigned sample_count; 

    covergroup cg;
        option.per_instance = 1;
      
        cp_op: coverpoint is_write {
            bins read  = {0};
            bins write = {1};
        }
        cp_addr: coverpoint addr_class {
            bins reg_hit[]    = {[0:15]};
            bins misaligned   = {16};
            bins out_of_range = {17};
        }
        cp_strb: coverpoint strb iff (is_write) {
            bins zero       = {4'b0000};
            bins byte0      = {4'b0001};
            bins byte1      = {4'b0010};
            bins byte2      = {4'b0100};
            bins byte3      = {4'b1000};
            bins lower_half = {4'b0011};
            bins upper_half = {4'b1100};
            bins full       = {4'b1111};
            bins other      = {4'b0101, 4'b0110, 4'b0111, 4'b1001, 4'b1010, 4'b1011, 4'b1101, 4'b1110};
        }
        cp_resp: coverpoint resp {
            bins okay   = {RESP_OKAY};
            bins decerr = {RESP_DECERR};
        }
    endgroup

    function new(string name = "axi_lite_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg = new();
    endfunction

    virtual function void write(axi_lite_item t);
        is_write = t.is_write;
        strb     = t.strb;
        resp     = t.resp;
        if (t.addr[1:0] != 2'b00) addr_class = 16;
        else if (t.addr > 32'h3C) addr_class = 17;
        else addr_class = t.addr[5:2];
        sample_count++;
        cg.sample();
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf(
            "samples=%0d  total=%0.2f%%  op=%0.2f%%  addr=%0.2f%%  strb=%0.2f%%  resp=%0.2f%%",
            sample_count, cg.get_inst_coverage(), cg.cp_op.get_inst_coverage(), cg.cp_addr.get_inst_coverage(),
         	cg.cp_strb.get_inst_coverage(), cg.cp_resp.get_inst_coverage()), UVM_LOW)
    endfunction
endclass