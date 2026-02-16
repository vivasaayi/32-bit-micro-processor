# FPGA-First SoC Execution Playbook (Open-Source Focus)

This is a practical path from your current CPU RTL to **real FPGA hardware** and then to a manufacturable SoC direction.

## 1) The shortest path to real hardware

Use this order and do not skip steps:

1. **CPU + SRAM + UART only** on FPGA (hello-world serial output).
2. Add **timer + interrupt controller** (prove deterministic periodic ISR).
3. Add **PWM outputs** (scope/logic-analyzer validation).
4. Add **sensor buses** (SPI/I2C) with loopback and then real sensor boards.
5. Add **DMA + timestamping** (measure jitter reduction).
6. Add safety blocks (**watchdog/reset/failsafe states**) before autonomous flights.

If step 1 is unstable, do not proceed to later blocks.

## 2) Recommended open-source stack

### RTL simulation and debug
- **Icarus Verilog + GTKWave** (already aligned with repo).
- **Verilator** for faster cycle-accurate tests.
- **cocotb** for Python-driven randomized peripheral testing.

### Linting and formal (highly recommended)
- **Verilator lint** for synthesizability and common RTL issues.
- **SymbiYosys** for safety properties:
  - watchdog must trigger within N cycles,
  - interrupt pending bits cannot be lost,
  - DMA finite-state machine cannot deadlock.

### Synthesis / P&R / bitstream
- **Yosys** synthesis.
- **nextpnr + Project Trellis / prjoxide / Project IceStorm** depending on FPGA family.
- If your board requires vendor flow only, keep RTL/tooling open-source and use vendor place-and-route as a thin final stage.

## 3) FPGA board strategy

Pick one board and commit to it for 3-6 months to avoid integration churn.

### Good starter classes
- Lattice ECP5 boards (strong open-source support).
- iCE40 boards for smaller prototypes.

### Board selection checklist
- Enough BRAM for code/data + traces.
- At least 1 UART, multiple PWM-capable pins.
- Stable clocking options and accessible debug headers.
- 3.3V IO compatibility with common sensors/transceivers.

## 4) Minimal SoC memory map for bring-up

Start with a clean map and freeze it early:

- `0x0000_0000 - 0x0001_FFFF`: On-chip SRAM
- `0x1000_0000 - 0x1000_00FF`: UART
- `0x1000_0100 - 0x1000_01FF`: Timer/PWM
- `0x1000_0200 - 0x1000_02FF`: Interrupt controller
- `0x1000_0300 - 0x1000_03FF`: SPI/I2C
- `0x1000_0400 - 0x1000_04FF`: DMA
- `0x1000_0500 - 0x1000_05FF`: Watchdog/reset status
- `0x2000_0000+`: External memory window (future)

Consistency here saves weeks of firmware churn.

## 5) How to test if the SoC is "real" and not just sim-passing

## Stage A: Simulation tests
- Boot ROM test: reset vector fetch + UART banner.
- Timer ISR test: fixed frequency interrupt with cycle counter logging.
- PWM test: programmable duty cycle changes at runtime.
- Bus abuse test: random reads/writes across all peripherals.

## Stage B: FPGA bench tests
- UART banner appears after every reset (100/100 resets).
- PWM waveform measured on logic analyzer matches register programming.
- Interrupt latency measured and bounded across load conditions.
- Watchdog timeout forces recoverable reset path.

## Stage C: Drone-control readiness tests
- 500 Hz control loop jitter measured over 30 minutes.
- No missed sensor frames at target rates.
- Failsafe action completes within deadline when sensor stream is dropped.

If you cannot produce these measurements, the platform is not flight-ready.

## 6) Instrumentation you should add immediately

- 64-bit free-running cycle counter.
- Interrupt entry/exit timestamp registers.
- DMA completion and bus-stall counters.
- Reset cause register (POR, watchdog, software reset, brownout).
- Small trace FIFO exported over UART for post-mortem.

These give you visibility when bugs appear only on hardware.

## 7) Open-source autopilot integration approach

Do not port a full autopilot stack on day 1.

1. Start with a **minimal RTOS loop** (or bare-metal scheduler).
2. Implement drivers for UART, timer, PWM, SPI/I2C, interrupts.
3. Integrate just stabilization + telemetry first.
4. Bring in larger autopilot modules incrementally.

This preserves determinism and makes profiling manageable.

## 8) When open source may hinder you (and how to handle it)

Open source is ideal for architecture learning and rapid iteration, but you may hit:
- Missing timing models for a specific FPGA family,
- Limited support for very new devices,
- Hard-IP blocks (e.g., DDR PHY) with weak open tooling.

Mitigation:
- Keep RTL, testbenches, firmware, and CI open-source.
- Allow vendor tools only for the final bitstream stage when unavoidable.
- Continuously validate equivalence between open and vendor flows on regression tests.

## 9) Practical weekly cadence (for fast progress)

- **Mon-Tue:** RTL changes + unit tests.
- **Wed:** full sim regressions + lint/formal checks.
- **Thu:** FPGA deployment + bench measurements.
- **Fri:** bug triage, timing budget updates, milestone review.

Always end the week with measurable hardware evidence (latency numbers, waveform captures, reset reliability).

## 10) Definition of done for your next milestone

Your next milestone should be:

> "CPU + UART + timer + interrupt + PWM running on FPGA with measured interrupt latency, bounded 500 Hz loop jitter, and watchdog reset recovery demonstrated."

Once this is stable, you are genuinely doing SoC engineering, not just CPU RTL development.
