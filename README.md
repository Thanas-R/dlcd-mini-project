# 8-bit Kogge-Stone Parallel Prefix Adder (Verilog)

Computes `{Cout, Sum} = A + B + Cin` with all carries found in 3 prefix levels
(log2 8) instead of an 8-stage ripple.

## Files

| File | What it is |
|---|---|
| `prefix_adder_8.v` | The design (`prefix_cell` + `prefix_adder_8`), fully commented |
| `tb_prefix_adder_8.v` | Full verification: 12 directed + 131,072 exhaustive vectors |
| `tb_demo.v` | Demo testbench: slow, labelled vectors, internal signals dumped |
| `demo.gtkw` | GTKWave layout for the demo (signals pre-arranged) |
| `prefix_adder_8.gtkw` | GTKWave layout for the full testbench's VCD |
| `run.sh` / `run.bat` | One-command run for Linux/macOS/WSL and Windows |

## 1. Install the tools (once)

- **Ubuntu / WSL:** `sudo apt install iverilog gtkwave`
- **macOS:** `brew install icarus-verilog gtkwave`
- **Windows:** install Icarus Verilog (iverilog-v12 installer, tick "Add to PATH" and "GTKWave") and restart the terminal.

Check: `iverilog -V` and `gtkwave --version` should both print a version.

## 2. Quick start

Open a terminal in this folder.

    ./run.sh test      # full verification        (Windows: run.bat test)
    ./run.sh demo      # demo + opens GTKWave     (Windows: run.bat demo)

### Manual commands (what the scripts do)

Full verification:

    iverilog -g2005 -o sim_test.out prefix_adder_8.v tb_prefix_adder_8.v
    vvp sim_test.out

Demo + waveform:

    iverilog -g2005 -o sim_demo.out prefix_adder_8.v tb_demo.v
    vvp sim_demo.out
    gtkwave demo.vcd demo.gtkw

## 3. Expected output

`test` ends with:

    Vectors applied : 131084
    Errors found    : 0
    RESULT: ALL TESTS PASSED

`demo` prints one labelled line per vector (all must say PASS) and ends with
`DEMO RESULT: all vectors PASSED`.

## 4. How to demo GTKWave

### Open
`gtkwave demo.vcd demo.gtkw` - the `.gtkw` file loads the signals already grouped as
INPUTS / PREFIX NETWORK / CARRIES / OUTPUTS.

### If the signal list is empty (no .gtkw loaded)
1. In the left **SST** panel click `tb_demo`, then `dut`.
2. Select signals in the lower-left list and press **Append** (or drag them into the Signals pane).
   Add: `a`, `b`, `cin`, `G0`, `G1`, `G2`, `G3`, `sum`, `cout`.

### Make it readable
1. **Zoom Fit:** menu *Time > Zoom > Zoom Full* (or the "Zoom Fit" toolbar button) so the whole 1.1 us run fills the screen.
2. **Number format:** select a bus > right-click > *Data Format* > Hexadecimal for `a`, `b`, `sum`;
   Binary for `G0..G3` (so you can see each carry bit).
3. Optionally *Edit > Alias Highlighted Trace* to rename signals.

### What to point at (each vector lasts 100 ns, first starts at 50 ns)

| Time (ns) | a + b + cin | Say this |
|---|---|---|
| 50-150 | 0 + 0 + 0 | Everything zero, baseline |
| 150-250 | 1 + 1 + 0 | `sum` = 02: first carry |
| 250-350 | 15 + 1 + 0 | `sum` = 10: carry crosses the low nibble |
| 350-450 | 85 + 170 + 0 | `sum` = FF, `G3` = 00000000: all bits propagate, nothing generates |
| 450-550 | 85 + 170 + 1 | **Key moment**: `G3` = 11111111 and `cout` = 1. The carry from cin reaches the MSB in 3 levels |
| 550-650 | 255 + 1 + 0 | Overflow: `sum` = 00, `cout` = 1 |
| 650-750 | 255 + 255 + 1 | Maximum: `sum` = FF, `cout` = 1 (511) |
| 750-850 | 128 + 128 + 0 | Only the top bit generates a carry |
| 850-950 | 127 + 1 + 0 | `sum` = 80 |
| 950-1050 | 200 + 100 + 1 | `sum` = 2D, `cout` = 1 (301) |

**Talking point:** at 450 ns, follow the signals `G0 -> G1 -> G2 -> G3`: the group of
carry-producing bits doubles each level (1, 2, 4 bits), so the carry reaches bit 7 after
3 levels, not 8.

### Handy GTKWave actions
- **Marker:** left-click on the waveform places a marker; the time shows at the top.
- **Zoom in/out:** `Ctrl + scroll`, or the magnifier buttons.
- **Reload after re-simulating:** *File > Reload Waveform* (Ctrl+Shift+R). No need to close GTKWave.
- **Save your layout:** *File > Write Save File* (Ctrl+S).

## 5. Troubleshooting

| Problem | Fix |
|---|---|
| `iverilog: command not found` | Tools not installed / not on PATH. Reinstall and reopen the terminal |
| `gtkwave: command not found` | Install GTKWave, or open the `.vcd` from the GTKWave app: *File > Open New Window* |
| Waveform is empty | Run the simulation first so `demo.vcd` exists; check you are opening it from this folder |
| Signals show `x` at the start | Normal for the first instant only; the demo holds inputs at 0 for 50 ns before testing |
| `Permission denied: ./run.sh` | `chmod +x run.sh` |
| macOS: GTKWave won't open | Launch it from the Applications folder once, or run `gtkwave` from a terminal |

## 6. Design in 30 seconds (for the viva)
1. **Pre-process:** `p = a^b`, `g = a&b`, `cin` folded into bit 0.
2. **Prefix network:** 3 levels at distance 1, 2, 4 -> 7 + 6 + 4 = 17 cells; `G3[i]` is the carry out of bit i.
3. **Post-process:** `sum[i] = p[i] ^ carry_into_bit_i`, `cout = G3[7]`.
4. Combinational circuit, so there is no FSM.
