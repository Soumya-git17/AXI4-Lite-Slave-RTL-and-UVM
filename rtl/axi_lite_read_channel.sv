import axi_lite_pkg::*;

module axi_lite_read_channel (
    axi_lite_if.slave axi_if,
    input logic decoder_valid,
    input logic [$clog2(NUM_REGS)-1:0] reg_index,
    input  logic [DATA_WIDTH-1:0] reg_read_data,
    output logic [$clog2(NUM_REGS)-1:0] read_index,
    output logic [ADDR_WIDTH-1:0] read_addr
);

read_state_t state, next_state;

logic [ADDR_WIDTH-1:0] araddr_reg;
logic ar_handshake, r_handshake;

assign ar_handshake = axi_if.ARVALID && axi_if.ARREADY;
assign r_handshake  = axi_if.RVALID  && axi_if.RREADY;

assign read_addr = araddr_reg;

always_ff @(posedge axi_if.ACLK, negedge axi_if.ARESETn) begin
    if (!axi_if.ARESETn) state <= RD_IDLE;
    else state <= next_state;
end

always_comb begin
    next_state = state;
    case(state)
        RD_IDLE: if (ar_handshake) next_state = RD_READ;
        RD_READ: next_state = RD_RESP;
        RD_RESP: if (r_handshake) next_state = RD_IDLE;
        default: next_state = RD_IDLE;
    endcase
end

always_ff @(posedge axi_if.ACLK or negedge axi_if.ARESETn) begin
    if (!axi_if.ARESETn) araddr_reg <= '0;
    else if (ar_handshake) araddr_reg <= axi_if.ARADDR;
end

always_comb begin
    read_index     = '0;
    axi_if.ARREADY = 1'b0;
    axi_if.RDATA   = '0;
    axi_if.RRESP   = RESP_OKAY;
    axi_if.RVALID  = 1'b0;
    case (state)
        RD_IDLE: axi_if.ARREADY = 1'b1;
        RD_READ: read_index = reg_index;
        RD_RESP: begin
            read_index      = reg_index;
            axi_if.RDATA    = reg_read_data;
            axi_if.RVALID   = 1'b1;
            axi_if.RRESP    = (decoder_valid) ? RESP_OKAY : RESP_DECERR;
        end
        default: ;
    endcase 
end

endmodule
