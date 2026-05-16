# UART Controller — SystemVerilog

A fully parameterizable UART controller implemented in SystemVerilog, featuring a synchronous FIFO buffer, a complete UVM verification environment, 7 SVA properties, and functional coverage collection.

---

## Features

- Configurable baud rate, clock frequency, data width, and parity mode via parameters
- 16x oversampling with mid-bit sampling for robust receive
- 2-flip-flop synchronizer on RX input to prevent metastability
- Parity error and framing error detection
- Synchronous FIFO (RX → TX loopback path) with full/empty flags using extra-bit pointer technique
- UVM testbench with directed, back-to-back, burst, error injection, and random sequences
- 7 SVA properties covering FIFO integrity and TX handshake
- Functional coverage: protocol, FIFO state, and cross coverage

---

## Project Structure

```
uart/
├── design/
│   ├── baud_rate_generator.sv   # Generates 16x oversampling tick
│   ├── fifo_sync.sv             # Synchronous FIFO (parameterizable depth/width)
│   ├── uart_rx.sv               # UART receiver FSM
│   ├── uart_tx.sv               # UART transmitter FSM
│   └── uart_controller.sv       # Top-level: integrates all submodules
└── tb/
    ├── uart_if.sv                  # SystemVerilog interface + 7 SVA assertions
    ├── uart_pkg.sv                 # UVM package (includes all TB files)
    ├── uart_transaction.sv         # UVM sequence item
    ├── uart_driver.sv              # UVM driver
    ├── uart_monitor.sv             # UVM monitor (RX & TX)
    ├── uart_scoreboard.sv          # UVM scoreboard
    ├── uart_coverage_collector.sv  # Functional coverage (protocol, FIFO, cross)
    ├── uart_agent.sv               # UVM agent
    ├── uart_env.sv                 # UVM environment
    ├── uart_directed_seq.sv        # Corner-case directed sequence
    ├── uart_b2b_seq.sv             # Back-to-back sequence
    ├── uart_burst_seq.sv           # Burst traffic sequence
    ├── uart_error_seq.sv           # Parity & framing error injection
    ├── uart_random_seq.sv          # Fully randomized sequence
    ├── uart_master_seq.sv          # Master sequence (orchestrates all phases)
    ├── uart_master_test.sv         # Top-level UVM test
    └── uart_top.sv                 # Testbench top module
```

---

## Parameters

| Parameter        | Default        | Description                          |
|------------------|----------------|--------------------------------------|
| `CLK_FREQ`       | `50_000_000`   | System clock frequency (Hz)          |
| `BAUD_RATE`      | `9_600`        | UART baud rate (bps)                 |
| `DATA_WIDTH`     | `8`            | Number of data bits per frame        |
| `PARITY_EN`      | `1`            | Enable parity bit (`0` = disabled)   |
| `PARITY_IS_EVEN` | `1`            | `1` = even parity, `0` = odd parity  |
| `FIFO_DEPTH`     | `16`           | RX FIFO depth (must be power of 2)   |

---

## Architecture

```
              ┌─────────────────────────────────────────┐
  i_rx_serial │                uart_controller          │ o_tx_serial
─────────────►│  uart_rx ──► fifo_sync ──► uart_tx      │────────────►
              │         baud_rate_generator             │
              └─────────────────────────────────────────┘
```

The controller operates as a loopback pipeline: received bytes are pushed into a FIFO, then the TX controller drains the FIFO and retransmits each byte serially.

---

## Verification

### Test Sequences

The UVM testbench runs 5 phases via `uart_master_seq`:

| Phase | Sequence              | Description                                                                 |
|-------|-----------------------|-----------------------------------------------------------------------------|
| 1     | `uart_directed_seq`   | Corner-case bytes: `0x00`, `0xFF`, `0xAA`, `0x55`, and other edge values   |
| 2     | `uart_b2b_seq`        | 20 back-to-back frames with zero inter-frame gap                            |
| 3     | `uart_burst_seq`      | 4 bursts × 5 bytes with random idle gaps                                    |
| 4     | `uart_error_seq`      | Injects parity errors, framing errors, and both simultaneously              |
| 5     | `uart_random_seq`     | 20 fully randomized frames                                                  |

The scoreboard classifies every transaction into 5 categories: clean match, parity-error match, framing drop, FIFO-full drop, and mismatch. A `PASS` verdict requires zero mismatches and an empty reference queue at end of simulation.

### SVA Properties

| Assertion              | Description                                               |
|------------------------|-----------------------------------------------------------|
| `A_MUTEX_FLAGS`        | FIFO cannot be full and empty at the same time            |
| `A_EMPTY_STABLE`       | Empty flag must not deassert without a write              |
| `A_FULL_STABLE`        | Full flag must not deassert without a read                |
| `A_NO_FIFO_OVERFLOW`   | Write must not occur when FIFO is full                    |
| `A_NO_FIFO_UNDERFLOW`  | Read must not occur when FIFO is empty                    |
| `A_TX_HANDSHAKE`       | `tx_busy` must respond within 1–2 cycles of `tx_start`   |
| `A_TX_BUSY_GLITCH`     | `tx_busy` must not deassert in the cycle after asserting  |

### Functional Coverage

| Covergroup     | Coverpoints                                                            |
|----------------|------------------------------------------------------------------------|
| `cg_protocol`  | Data payload (corner, checkerboard, random), parity/framing error type |
| `cg_fifo`      | FIFO full and empty flag states                                         |
| `cg_cross`     | Parity × FIFO state, Framing × FIFO state, Both errors × FIFO state   |

---

## How to Run on EDA Playground

1. Go to [https://www.edaplayground.com](https://www.edaplayground.com) and sign in.

2. **Simulator:** Select `Cadence Xcelium` (supports UVM natively).

3. **UVM version:** Tick **"Use UVM"** and select `UVM 1.2`.

4. In the **testbench** pane, paste the contents of `tb/uart_top.sv`.

5. In the **design** pane, paste the contents of all design files in order:
   - `design/baud_rate_generator.sv`
   - `design/fifo_sync.sv`
   - `design/uart_rx.sv`
   - `design/uart_tx.sv`
   - `design/uart_controller.sv`

6. In **"Testbench + Design"** compile options, add:
   ```
   +incdir+. +UVM_TESTNAME=uart_master_test
   ```

7. Click **Run** — the UVM log, scoreboard summary, and coverage report will appear in the output panel.

> Waveform is dumped to `dump.vcd` and can be viewed via the **EPWave** button after simulation.

---

## License

This project is for educational and portfolio purposes.