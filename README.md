# AXI4-Lite Slave: RTL and UVM Verification

An **AXI4-Lite slave IP** in SystemVerilog (16 registers, byte strobes, `DECERR` handling) with two verification environments: a self-checking Verilator testbench and a **UVM 1.2 testbench** with a scoreboard-based register model.

## Features

- AXI4-Lite slave interface, 32-bit address and 32-bit data
- 16 programmable 32-bit registers (word-aligned, `0x00` to `0x3C`)
- Independent read and write channels
- Write handling for AW-first, W-first, and same-cycle AW/W
- Byte-wise writes using `WSTRB`
- `DECERR` response for invalid (misaligned or out-of-range) addresses
- SystemVerilog interface (with `master` and `slave` modports) and package
- Self-checking testbench (Verilator) and UVM verification environment (Questa)

## Register Map

| Address | Register |
|--------:|----------|
| `0x00`  | REG0     |
| `0x04`  | REG1     |
| `0x08`  | REG2     |
| ...     | ...      |
| `0x3C`  | REG15    |

Only word-aligned addresses in this range are valid. Any other address returns `DECERR`.

## Project Structure

```
├── rtl/
│   ├── axi_lite_pkg.sv
│   ├── axi_lite_if.sv
│   ├── axi_lite_addr_decoder.sv
│   ├── axi_lite_write_channel.sv
│   ├── axi_lite_read_channel.sv
│   ├── axi_lite_reg_bank.sv
│   └── axi_lite_slave_top.sv
├── tb/
│   └── tb_axi_lite_slave.sv        # self-checking testbench (Verilator)
├── uvm/                            # UVM environment
│   ├── axi_lite_uvm_pkg.sv         # package: includes all classes below
│   ├── tb_top.sv                   # clock, reset, DUT, config_db, run_test
│   ├── axi_lite_item.sv
│   ├── axi_lite_sequence.sv        # directed: write then read back
│   ├── axi_lite_rand_seq.sv        # random read/write traffic
│   ├── axi_lite_sequencer.sv
│   ├── axi_lite_driver.sv
│   ├── axi_lite_monitor.sv
│   ├── axi_lite_agent.sv
│   ├── axi_lite_scoreboard.sv
│   ├── axi_lite_env.sv
│   ├── axi_lite_test.sv
│   ├── design.sv                   # EDA Playground: includes the RTL files
│   └── testbench.sv                # EDA Playground: includes the UVM package and tb_top
├── Makefile
└── README.md
```

## Verification

### 1. Self-checking testbench (Verilator)

Directed tests for write and read transactions, AW-first / W-first / simultaneous handshakes, valid and invalid addresses, `WSTRB` byte enables, response codes, and reset behavior. Waveforms are generated as VCD and viewed in GTKWave. The RTL is also linted with Verilator.

### 2. UVM environment (Questa, UVM 1.2)

Simulator: Questa, library: UVM 1.2. Paste `design.sv`, `testbench.sv`, and the other files from `uvm/` as separate tabs.

```
test
 └── env
      ├── agent
      │    ├── sequencer
      │    ├── driver      (master: AW / W / B and AR / R handshakes)
      │    └── monitor     (rebuilds transactions from handshakes)
      └── scoreboard       (16-register reference model, WSTRB-aware)
```

- **Driver:** drives AW and W concurrently (`fork ... join`), then collects the write response; drives AR then R for reads.
- **Monitor:** one watcher per channel, with queues pairing AW/W with B and AR with R. It publishes complete transactions through an analysis port.
- **Scoreboard:** keeps a model of the register file, applies `WSTRB` byte lanes on writes, and checks read data and response codes (`OKAY` for valid addresses, `DECERR` for invalid).
- **Sequences:** a directed write-then-read sequence, and a random read/write sequence that only reads addresses it has already written.

**Current result:** 50 random read/write transactions across all 16 registers, 0 scoreboard errors.

## Bug Found by the UVM Environment

The random test exposed a real RTL bug that a directed test on address `0x00` had not caught.

- **Symptom:** every read of a previously written non-zero register returned `0x00000000` with `OKAY`, and the scoreboard flagged each one.
- **Root cause:** in `axi_lite_read_channel`, `read_index` was only driven in the `RD_READ` state. In `RD_RESP`, where `RDATA` is driven, it fell back to its default of 0. Because the register bank read is combinational, every read returned `regfile[0]`.
- **Why it was missed:** a test using only address `0x00` returns the right value by coincidence.
- **Fix:** hold `read_index = reg_index` in `RD_RESP` as well.
- **Result:** the random test passes with 0 scoreboard errors after the fix.

## Status and Planned Work

| Item | Status |
|------|--------|
| UVM agent, monitor, scoreboard with register model | Done |
| Directed and random sequences | Done |
| Randomized AW/W delays (AW-first, W-first, same-cycle) | Planned |
| Invalid-address stimulus (`DECERR` paths) | Planned |
| Partial and zero `WSTRB`, delayed `BREADY` / `RREADY` | Planned |
| Protocol SVA bound to the interface | Planned |
| Functional coverage with cross coverage | Planned |
| RTL bug injection to measure testbench effectiveness | Planned |

## Tools

SystemVerilog, UVM 1.2, Questa (EDA Playground), Verilator, GTKWave, Make

## Learning Objectives

- AMBA AXI4-Lite protocol and FSM-based RTL design
- Memory-mapped register interfaces and byte-enable logic
- UVM testbench architecture (agent, monitor, scoreboard, sequences)
- Constrained-random verification and reference-model checking
- Debugging with waveforms and scoreboard logs
