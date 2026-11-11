@echo off
REM Usage:  run.bat [demo|test]      (default: demo)
REM Needs Icarus Verilog and GTKWave on PATH.
cd /d %~dp0
set MODE=%1
if "%MODE%"=="" set MODE=demo

if "%MODE%"=="test" goto test
if "%MODE%"=="demo" goto demo
echo Usage: run.bat [demo^|test]
exit /b 1

:test
iverilog -g2005 -o sim_test.out prefix_adder_8.v tb_prefix_adder_8.v
vvp sim_test.out
echo Waveform of the directed tests: prefix_adder_8.vcd
exit /b 0

:demo
iverilog -g2005 -o sim_demo.out prefix_adder_8.v tb_demo.v
vvp sim_demo.out
gtkwave demo.vcd demo.gtkw
exit /b 0
