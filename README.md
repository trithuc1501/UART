# UART Controller — SystemVerilog

A fully parameterizable UART controller implemented in SystemVerilog, featuring a synchronous FIFO buffer and a complete UVM verification environment.

---

## Features

- Configurable baud rate, clock frequency, data width, and parity mode via parameters
- 16x oversampling with mid-bit sampling for robust receive
- 2-flip-flop synchronizer on RX input to prevent metastability
- Parity error and framing error detection
- Synchronous FIFO (RX → TX loopback path) with full/empty flags
- UVM testbench with directed, back-to-back, burst, and error injection sequences

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
    ├── uart_if.sv               # SystemVerilog interface + SVA assertions
    ├── uart_pkg.sv              # UVM package (includes all TB files)
    ├── uart_transaction.sv      # UVM sequence item
    ├── uart_driver.sv           # UVM driver
    ├── uart_monitor.sv          # UVM monitor (RX & TX)
    ├── uart_scoreboard.sv       # UVM scoreboard
    ├── uart_agent.sv            # UVM agent
    ├── uart_env.sv              # UVM environment
    ├── uart_directed_seq.sv     # Corner-case directed sequence
    ├── uart_b2b_seq.sv          # Back-to-back sequence
    ├── uart_burst_seq.sv        # Burst traffic sequence
    ├── uart_error_seq.sv        # Parity & framing error injection
    ├── uart_master_seq.sv       # Master sequence (runs all phases)
    ├── uart_master_test.sv      # Top-level UVM test
    └── uart_top.sv              # Testbench top module
```

---

## Parameters

| Parameter       | Default        | Description                          |
|-----------------|----------------|--------------------------------------|
| `CLK_FREQ`      | `50_000_000`   | System clock frequency (Hz)          |
| `BAUD_RATE`     | `9_600`        | UART baud rate (bps)                 |
| `DATA_WIDTH`    | `8`            | Number of data bits per frame        |
| `PARITY_EN`     | `1`            | Enable parity bit (`0` = disabled)   |
| `PARITY_IS_EVEN`| `1`            | `1` = even parity, `0` = odd parity  |
| `FIFO_DEPTH`    | `16`           | RX FIFO depth (must be power of 2)   |

---

## Architecture

```
              ┌─────────────────────────────────────────┐
  i_rx_serial │                uart_controller           │ o_tx_serial
─────────────►│  uart_rx ──► fifo_sync ──► uart_tx      │────────────►
              │         baud_rate_generator              │
              └─────────────────────────────────────────┘
```

The controller operates as a loopback pipeline: received bytes are pushed into a FIFO, then the TX controller drains the FIFO and retransmits each byte serially.

---

## Verification

The UVM testbench runs four test phases via `uart_master_seq`:

| Phase | Sequence            | Description                                      |
|-------|---------------------|--------------------------------------------------|
| 1     | `uart_directed_seq` | Sends corner-case bytes: `0x00`, `0xFF`, `0xAA`, `0x55`, etc. |
| 2     | `uart_b2b_seq`      | 20 back-to-back frames with zero inter-frame gap |
| 3     | `uart_burst_seq`    | 4 bursts × 5 bytes with random idle gaps         |
| 4     | `uart_error_seq`    | Injects parity errors, framing errors, and both simultaneously |

The scoreboard tracks clean matches, parity-error frames, framing drops, FIFO-full drops, and mismatches. A `PASS` verdict requires zero mismatches and an empty reference queue at end of simulation.

SVA properties in `uart_if.sv` assert FIFO flag consistency throughout the run.

---

## How to Run on EDA Playground

1. Go to [https://www.edaplayground.com](https://www.edaplayground.com) and sign in.

2. **Simulator:** Select `Synopsys VCS` (supports UVM natively).

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

7. Click **Run** — the UVM log and scoreboard summary will appear in the output panel.

> Waveform is dumped to `dump.vcd` and can be viewed via the **EPWave** button after simulation.

---

## License

This project is for educational and portfolio purposes.