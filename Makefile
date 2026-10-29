TOP = tb_axi_lite_slave

RTL = \
	rtl/axi_lite_pkg.sv \
	rtl/axi_lite_if.sv \
	rtl/axi_lite_addr_decoder.sv \
	rtl/axi_lite_reg_bank.sv \
	rtl/axi_lite_write_channel.sv \
	rtl/axi_lite_read_channel.sv \
	rtl/axi_lite_slave_top.sv

TB = tb/tb_axi_lite_slave.sv

all: 
	verilator --binary --timing --trace --sv \
	--timescale 1ns/1ps \
	--top-module $(TOP) \
	$(RTL) $(TB)

run: all
	./obj_dir/V$(TOP)

lint:
	mkdir -p lint
	verilator --lint-only -Wall --Wno-IMPORTSTAR --Wno-SYNCASYNCNET --sv \
	--top-module $(TOP) \
	$(RTL) $(TB) 2>&1 | tee lint/lint.log

clean:
	rm -rf obj_dir lint *.vcd

wave:
	gtkwave axi_lite.vcd