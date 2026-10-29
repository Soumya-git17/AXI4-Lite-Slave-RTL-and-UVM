import axi_lite_pkg::*;

module axi_lite_reg_bank (
    input logic ACLK, ARESETn, write_enable,
    input logic [$clog2(NUM_REGS)-1:0] write_index, read_index,
    input logic [DATA_WIDTH-1:0] write_data,
    input logic [STRB_WIDTH-1:0] write_strobe,
    output logic [DATA_WIDTH-1:0] read_data
);

logic [DATA_WIDTH-1:0] regfile [0:NUM_REGS-1];
integer i;

assign read_data = regfile[read_index];

always_ff @(posedge ACLK, negedge ARESETn) begin
    if (!ARESETn) for (i = 0; i < NUM_REGS; i++) regfile[i] <= '0;
    else begin
        if (write_enable) begin
            for (i = 0; i < STRB_WIDTH; i++) begin
                if (write_strobe[i]) regfile[write_index][8*i +: 8] <= write_data[8*i +: 8];
                // indexed part select
            end
        end
    end
end

endmodule
