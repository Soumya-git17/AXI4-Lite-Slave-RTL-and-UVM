# AXI4-Lite Slave IP with UVM, SVA, and Coverage-Driven Verification

An **AXI4-Lite slave IP** in SystemVerilog (16 registers, byte strobes, `DECERR` handling) with two verification environments: a self-checking Verilator testbench and a **UVM 1.2 testbench** with a scoreboard-based register model, protocol assertions (SVA), and functional coverage.

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
├── sva/
│   └── axi_lite_sva.sv             # protocol assertions and cover properties (module)
├── uvm/                            # UVM environment
│   ├── axi_lite_uvm_pkg.sv         # package: includes all classes below
│   ├── tb_top.sv                   # clock, reset, DUT, SVA instance, config_db, run_test
│   ├── axi_lite_item.sv            # transaction with randomized delays and strobes
│   ├── axi_lite_sequence.sv        # directed: write then read back
│   ├── axi_lite_rand_seq.sv        # random read/write traffic
│   ├── axi_lite_sequencer.sv
│   ├── axi_lite_driver.sv
│   ├── axi_lite_monitor.sv
│   ├── axi_lite_coverage.sv        # functional coverage (uvm_subscriber)
│   ├── axi_lite_agent.sv
│   ├── axi_lite_scoreboard.sv
│   ├── axi_lite_env.sv
│   ├── axi_lite_test.sv
│   ├── design.sv                   # EDA Playground: includes the RTL files
│   └── testbench.sv                # EDA Playground: includes SVA, UVM package, tb_top
├── Makefile
├──.gitignore
├── LICENSE 
└── README.md
```

## Verification

### 1. Self-checking testbench (Verilator)

Directed tests for write and read transactions, AW-first / W-first / simultaneous handshakes, valid and invalid addresses, `WSTRB` byte enables, response codes, and reset behavior. Waveforms are generated as VCD and viewed in GTKWave. The RTL is also linted with Verilator.

### 2. UVM environment (Questa, UVM 1.2)

Simulator: Questa, library: UVM 1.2. Paste `design.sv`, `testbench.sv`, and the other files from `uvm/` as separate tabs.

```
tb_top
 ├── DUT + interface
 ├── axi_lite_sva                  (assertions and covers on the interface signals)
 └── test
      └── env
           ├── agent
           │    ├── sequencer
           │    ├── driver         (master: AW / W / B and AR / R handshakes)
           │    └── monitor        (rebuilds transactions from handshakes)
           ├── scoreboard          (16-register reference model, WSTRB-aware)
           └── coverage            (covergroup, sampled from the monitor)
```

- **Driver:** drives AW and W concurrently (`fork ... join`) with a randomized delay on each channel, so AW-first, W-first, and same-cycle writes can all occur. Randomized delays are also applied before `BREADY` and `RREADY` (response backpressure).
- **Monitor:** one watcher per channel, with queues pairing AW/W with B and AR with R. It publishes complete transactions through an analysis port, which feeds both the scoreboard and the coverage collector.
- **Scoreboard:** keeps a model of the register file, applies `WSTRB` byte lanes on writes, and checks read data and response codes (`OKAY` for valid addresses, `DECERR` for invalid).
- **Sequences:** a directed write-then-read sequence, and a random read/write sequence that only reads addresses it has already written. Strobes are weighted toward full-word writes, with some zero and partial strobes.
- **SVA module:** 18 concurrent assertions on the AXI signals, plus cover properties. Categories: VALID/payload stability on all five channels, response-after-request ordering (using handshake counters), legal `BRESP`/`RRESP` values, no new request accepted while a response is pending, bounded `BVALID`/`RVALID` latency, one-shot responses, no X on slave outputs, and reset behavior. Assertions on master-driven signals also act as checks on the driver.
- **Functional coverage:** a covergroup over operation, register address class (16 registers, misaligned, out of range), write strobe pattern, and response, with crosses of operation x address and strobe x response.

**Latest run (random test, 200 transactions: 110 writes, 90 reads):**

| Check | Result |
|-------|--------|
| Scoreboard errors | 0 |
| Assertion failures | 0 |
| Functional coverage (total) | 84.72% |
| Operation / address / strobe / response | 100% / 88.89% / 100% / 50% |

All 16 registers were accessed and all 9 write-strobe bins were hit. The remaining coverage holes are the `misaligned` and `out_of_range` address bins and the `DECERR` response bin: the random sequence currently sends only valid addresses, so the invalid-address (`DECERR`) paths are not yet exercised in UVM. (Invalid addresses are covered in the Verilator testbench.)

## Bug Found by the UVM Environment

The random test exposed a real RTL bug that a directed test on address `0x00` had not caught.

- **Symptom:** every read of a previously written non-zero register returned `0x00000000` with `OKAY`, and the scoreboard flagged each one.
- **Root cause:** in `axi_lite_read_channel`, `read_index` was only driven in the `RD_READ` state. In `RD_RESP`, where `RDATA` is driven, it fell back to its default of 0. Because the register bank read is combinational, every read returned `regfile[0]`.
- **Why it was missed:** a test using only address `0x00` returns the right value by coincidence.
- **Fix:** hold `read_index = reg_index` in `RD_RESP` as well.
- **Result:** the random test passes with 0 scoreboard errors after the fix.

## Tools

SystemVerilog, UVM 1.2, SVA, Questa (EDA Playground), Verilator, GTKWave, Make

## Learning Objectives

- AMBA AXI4-Lite protocol and FSM-based RTL design
- Memory-mapped register interfaces and byte-enable logic
- UVM testbench architecture (agent, monitor, scoreboard, sequences)
- Constrained-random verification and reference-model checking
- SystemVerilog Assertions and functional coverage
- Debugging with waveforms and scoreboard logs