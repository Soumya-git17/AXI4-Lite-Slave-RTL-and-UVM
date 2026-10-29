import axi_lite_pkg::*;

interface axi_lite_if;

logic ACLK;
logic ARESETn;

// Write Address
logic [ADDR_WIDTH-1:0] AWADDR;
logic AWVALID;
logic AWREADY;

// Write Data
logic [DATA_WIDTH-1:0] WDATA;
logic [STRB_WIDTH-1:0] WSTRB;
logic WVALID;
logic WREADY;

// Write Response
resp_t BRESP;
logic BVALID;
logic BREADY;

// Read Address
logic [ADDR_WIDTH-1:0] ARADDR;
logic ARVALID;
logic ARREADY;

// Read Data
logic [DATA_WIDTH-1:0] RDATA;
resp_t RRESP;
logic RVALID;
logic RREADY;

modport master (
input ACLK, ARESETn,
input AWREADY, WREADY, BRESP, BVALID, ARREADY, RVALID, RDATA, RRESP,
output AWADDR, AWVALID, WVALID, WDATA, WSTRB, BREADY, ARVALID, ARADDR, RREADY
);

modport slave (
input ACLK, ARESETn,
input AWADDR, AWVALID, WVALID, WDATA, WSTRB, BREADY, ARVALID, ARADDR, RREADY,
output AWREADY, WREADY, BRESP, BVALID, ARREADY, RVALID, RDATA, RRESP
);

endinterface 
