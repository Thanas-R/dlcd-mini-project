#!/usr/bin/env bash
# Usage:  ./run.sh [demo|test]
#   demo (default) : run tb_demo.v, then open demo.vcd in GTKWave
#   test           : run the full verification (131,072 vectors)
set -e
cd "$(dirname "$0")"                      # always work in this folder
MODE="${1:-demo}"

command -v iverilog >/dev/null || { echo "iverilog not found. Install: sudo apt install iverilog gtkwave"; exit 1; }

case "$MODE" in
  test)
    iverilog -g2005 -o sim_test.out prefix_adder_8.v tb_prefix_adder_8.v   # compile
    vvp sim_test.out                                                       # simulate
    echo "Waveform of the directed tests: prefix_adder_8.vcd"
    ;;
  demo)
    iverilog -g2005 -o sim_demo.out prefix_adder_8.v tb_demo.v             # compile
    vvp sim_demo.out                                                       # simulate
    command -v gtkwave >/dev/null && gtkwave demo.vcd demo.gtkw &          # open waveform
    ;;
  *) echo "Usage: ./run.sh [demo|test]"; exit 1 ;;
esac
