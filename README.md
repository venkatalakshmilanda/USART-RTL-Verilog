# 8-bit Asynchronous USART RTL Design

A Verilog RTL implementation of an 8-bit asynchronous USART with configurable baud rate, FSM-based transmitter and receiver, frame synchronization, and error detection.
## Features

- 8-bit data transmission and reception
- Asynchronous serial communication
- Configurable clock frequency and baud rate
- FSM-based TX and RX design
- 8N1 frame format
- RX frame synchronization
- Framing error detection
- TX busy indication
- RX data valid indication
- Loopback verification
- Simulation using EDA Playground and EPWave
- ## USART Frame Format

This design uses the standard 8N1 asynchronous serial frame.

```text
Idle | Start | D0 D1 D2 D3 D4 D5 D6 D7 | Stop
  1  |   0   |          8 Data Bits     |  1
```

- 1 Start bit
- 8 Data bits
- No parity bit
- 1 Stop bit

## Design Architecture

```text
                 +----------------------+
tx_data -------->|                      |
tx_start -------->|      USART TX       |------> tx
                  |    Baud Generator   |
                  |       TX FSM        |
                  +----------------------+

                  +----------------------+
rx -------------->|                      |
                  |      USART RX        |------> rx_data
                  |    Synchronizer      |------> rx_valid
                  |    Baud Generator    |------> rx_error
                  |       RX FSM         |
                  +----------------------+
```

## Transmitter

The transmitter converts 8-bit parallel data into an asynchronous serial data stream.

### TX Operation

1. Wait for `tx_start`.
2. Load the 8-bit transmit data.
3. Send the start bit.
4. Transmit the 8 data bits.
5. Send the stop bit.
6. Return to the idle state.

The `tx_busy` signal indicates that transmission is in progress.

## Receiver

The receiver converts the incoming asynchronous serial data stream into 8-bit parallel data.

### RX Operation

1. Detect the start-bit transition.
2. Synchronize the asynchronous RX input.
3. Verify the start bit at its midpoint.
4. Sample the 8 data bits.
5. Check the stop bit.
6. Store the received byte in `rx_data`.
7. Assert `rx_valid` when valid data is received.

The `rx_error` signal indicates a framing error when the expected stop bit is not detected.

## Baud Rate Generation

The baud-rate timing is generated from the system clock.

The number of clock cycles required for one baud period is calculated as:

```text
BAUD_TICKS = CLK_FREQ / BAUD_RATE
```

For the simulation:

```text
CLK_FREQ  = 1 MHz
BAUD_RATE = 9600
```

Therefore:

```text
BAUD_TICKS ≈ 1,000,000 / 9,600 ≈ 104 clock cycles
```

## Module Interface

### Input Signals

| Signal | Description |
|---|---|
| `clk` | System clock |
| `reset` | Active-high reset |
| `tx_data` | 8-bit parallel transmit data |
| `tx_start` | Starts data transmission |
| `rx` | Asynchronous serial input |

### Output Signals

| Signal | Description |
|---|---|
| `tx` | Serial transmit output |
| `tx_busy` | Indicates transmitter is busy |
| `rx_data` | 8-bit received data |
| `rx_valid` | Indicates valid received data |
| `rx_error` | Indicates framing error |

## Parameters

The USART module provides configurable parameters for different system clock frequencies and baud rates.

| Parameter | Simulation Value | Description |
|---|---:|---|
| `CLK_FREQ` | 1,000,000 Hz | Simulation clock frequency |
| `BAUD_RATE` | 9,600 | Serial communication baud rate |

Example:

```verilog
parameter integer CLK_FREQ  = 1_000_000;
parameter integer BAUD_RATE = 9_600;
```

The `CLK_FREQ` parameter can be changed according to the target hardware clock frequency.

## Verification

The USART was verified using a loopback configuration in which the transmitter output is directly connected to the receiver input.

```text
        +----------------+
        |     USART      |
        |                |
        | TX --------+   |
        |            |   |
        | RX <-------+   |
        +----------------+
```

The testbench transmits multiple 8-bit data patterns and checks the received data.

### Test Data

The following hexadecimal values were used during verification:

```text
41
42
55
AA
FF
00
```

The received data was observed using the simulation waveform.

### Simulation Tools

- Icarus Verilog
- EDA Playground
- EPWave

The testbench generates a VCD waveform for signal analysis.

## Project Structure

```text
USART-RTL-Verilog/
├── rtl/
│   └── usart.v
├── tb/
│   └── usart_tb.v
├── waveform/
│   ├── usart_waveforms.jpg
│   └── usart_epwave.jpeg
├── LICENSE
└── README.md
```

## Design Concepts Demonstrated

This project demonstrates practical RTL design concepts including:

- Verilog RTL coding
- Finite State Machines (FSM)
- Baud-rate generation
- Serial data transmission
- Serial data reception
- Asynchronous input synchronization
- Bit sampling
- Frame error detection
- Testbench development
- Loopback verification
- Waveform analysis

## Future Improvements

- Configurable parity support
- Multiple stop-bit configurations
- Synchronous USART mode
- Oversampling-based receiver
- FIFO buffering
- FPGA hardware implementation
- More extensive automated verification

## Author

**Venkata Lakshmi**

Electronics and Communication Engineering

## License

This project is licensed under the MIT License.
