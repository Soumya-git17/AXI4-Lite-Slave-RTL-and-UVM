import axi_lite_pkg::*;

module axi_lite_addr_decoder (
    input logic [ADDR_WIDTH-1:0] addr,
    output logic valid,
    output logic [$clog2(NUM_REGS)-1:0] reg_index
);

always_comb begin
    valid = 1'b0;
    reg_index = '0;
    if ((addr[ADDR_LSB-1:0] == '0) && (addr < NUM_REGS * (DATA_WIDTH/8))) begin
        valid = 1'b1;
        reg_index = addr[ADDR_LSB + $clog2(NUM_REGS)-1:ADDR_LSB]; 
    end
end
    
endmodule
