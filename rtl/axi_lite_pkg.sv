package axi_lite_pkg;
    parameter int unsigned ADDR_WIDTH = 32;
    parameter int unsigned DATA_WIDTH = 32;
    parameter int unsigned NUM_REGS = 16;
    parameter int unsigned STRB_WIDTH = DATA_WIDTH / 8;

    localparam int unsigned ADDR_LSB = $clog2(DATA_WIDTH/8);

    typedef enum logic [1:0]{
        RESP_OKAY = 2'b00,
        RESP_SLVERR = 2'b10,
        RESP_DECERR = 2'b11
    } resp_t;

    typedef enum logic [1:0]{
        WR_IDLE = 2'b00,
        WR_WAIT_DATA = 2'b01,
        WR_WRITE = 2'b10,
        WR_RESP = 2'b11
    } write_state_t;

    typedef enum logic [1:0]{
        RD_IDLE = 2'b00,
        RD_READ = 2'b01,
        RD_RESP = 2'b10
    } read_state_t;

endpackage
