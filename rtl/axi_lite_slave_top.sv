import axi_lite_pkg::*;

module axi_lite_slave_top (
    axi_lite_if.slave axi_if
);

logic [ADDR_WIDTH-1:0] wr_addr, rd_addr;
logic wr_valid, rd_valid;
logic [$clog2(NUM_REGS)-1:0] wr_reg_index, rd_reg_index;
logic [$clog2(NUM_REGS)-1:0] write_index, read_index;
logic [DATA_WIDTH-1:0] write_data, reg_read_data;
logic [STRB_WIDTH-1:0] write_strobe;
logic write_enable;

axi_lite_addr_decoder wr_ad (.addr(wr_addr), .valid(wr_valid), .reg_index(wr_reg_index));
axi_lite_addr_decoder rd_ad (.addr(rd_addr), .valid(rd_valid), .reg_index(rd_reg_index));

axi_lite_reg_bank rb (.ACLK(axi_if.ACLK), .ARESETn(axi_if.ARESETn), .write_enable(write_enable),
                    .write_index(write_index), .read_index(read_index), .write_data(write_data),
                    .write_strobe(write_strobe), .read_data(reg_read_data));

axi_lite_write_channel wc (.axi_if(axi_if), .decoder_valid(wr_valid), .reg_index(wr_reg_index),
                        .write_enable(write_enable), .write_index(write_index), .write_data(write_data),
                        .write_strobe(write_strobe), .write_addr(wr_addr));

axi_lite_read_channel rc (.axi_if(axi_if), .decoder_valid(rd_valid), .reg_index(rd_reg_index),
                        .reg_read_data(reg_read_data), .read_index(read_index), .read_addr(rd_addr));

endmodule
