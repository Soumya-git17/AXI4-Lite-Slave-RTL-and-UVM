import axi_lite_pkg::*;

module axi_lite_write_channel (
    axi_lite_if.slave axi_if,
    input logic decoder_valid,
    input logic [$clog2(NUM_REGS)-1:0] reg_index,
    output logic write_enable,
    output logic [$clog2(NUM_REGS)-1:0] write_index,
    output logic [DATA_WIDTH-1:0] write_data,
    output logic [STRB_WIDTH-1:0] write_strobe,
    output logic [ADDR_WIDTH-1:0] write_addr
);

write_state_t state, next_state;

logic [ADDR_WIDTH-1:0] awaddr_reg;
logic [DATA_WIDTH-1:0] wdata_reg;
logic [STRB_WIDTH-1:0] wstrb_reg;

logic aw_received, w_received;
logic aw_handshake, w_handshake, b_handshake;

assign aw_handshake = axi_if.AWVALID && axi_if.AWREADY;
assign w_handshake  = axi_if.WVALID  && axi_if.WREADY;
assign b_handshake  = axi_if.BVALID  && axi_if.BREADY;

assign write_addr = awaddr_reg;

always_ff @(posedge axi_if.ACLK, negedge axi_if.ARESETn) begin
    if (!axi_if.ARESETn) state <= WR_IDLE;
    else state <= next_state;
end

always_comb begin
    next_state = state;
    case(state)
        WR_IDLE: begin
            if (aw_handshake && w_handshake) next_state = WR_WRITE;
            else if (aw_handshake || w_handshake) next_state = WR_WAIT_DATA;
        end
        WR_WAIT_DATA: if ((aw_received || aw_handshake) && (w_received || w_handshake)) next_state = WR_WRITE;
        WR_WRITE: next_state = WR_RESP;
        WR_RESP: if (b_handshake) next_state = WR_IDLE;
        default: next_state = WR_IDLE;
    endcase
end

always_ff @(posedge axi_if.ACLK, negedge axi_if.ARESETn) begin
    if (!axi_if.ARESETn) begin
        awaddr_reg  <= '0;
        wdata_reg   <= '0;
        wstrb_reg   <= '0;
        aw_received <= 1'b0;
        w_received  <= 1'b0;
    end
    else begin
        if (aw_handshake) begin
            awaddr_reg <= axi_if.AWADDR;
            aw_received  <= 1'b1;
        end
        if (w_handshake) begin
            wdata_reg   <= axi_if.WDATA;
            wstrb_reg   <= axi_if.WSTRB;
            w_received  <= 1'b1;
        end
        if (b_handshake) begin
            aw_received <= 1'b0;
            w_received  <= 1'b0;
        end
    end
end

always_comb begin
    write_enable   = 1'b0;
    write_index    = '0;
    write_data     = '0;
    write_strobe   = '0;
    axi_if.AWREADY = 1'b0;
    axi_if.WREADY  = 1'b0;
    axi_if.BRESP   = RESP_OKAY;
    axi_if.BVALID  = 1'b0;
    case (state)
        WR_IDLE: begin
            axi_if.AWREADY = !aw_received;
            axi_if.WREADY  = !w_received;
        end
        WR_WAIT_DATA: begin
            axi_if.AWREADY = !aw_received;
            axi_if.WREADY  = !w_received;
        end
        WR_WRITE: begin
            if (decoder_valid) begin
                write_enable   = 1'b1;
                write_index    = reg_index;
                write_data     = wdata_reg;
                write_strobe   = wstrb_reg;
            end
        end
        WR_RESP: begin
            axi_if.BRESP   = (decoder_valid) ? RESP_OKAY : RESP_DECERR;
            axi_if.BVALID  = 1'b1;
        end
    endcase 
end

endmodule
