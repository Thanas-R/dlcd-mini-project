//==============================================================
// File    : tb_demo.v
// Purpose : DEMO testbench - built for showing the design live
//           in GTKWave during the presentation / viva.
//
// Differences from tb_prefix_adder_8.v:
//   * vectors are held for 100 ns, so they are easy to read
//   * a short description is printed for every vector
//   * the console also shows the carries c7..c0 from the prefix network
//   * ALL internal signals (G0..G3) are dumped, so you can show
//     the three prefix levels in the waveform
//
// Output  : console log + demo.vcd   (open with demo.gtkw)
//==============================================================
`timescale 1ns/1ps
module tb_demo;

    localparam STEP = 100;      // time each vector is held (ns)

    reg  [7:0] a, b;
    reg        cin;
    wire [7:0] sum;
    wire       cout;
    reg  [8:0] expected;
    integer    errors;

    prefix_adder_8 dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    // demo : apply one vector, hold it, check it, print a labelled line
    task demo;
        input [7:0] xa, xb;
        input       xc;
        input [8*34-1:0] label;     // text, up to 34 characters
        begin
            a = xa; b = xb; cin = xc;
            #(STEP/2);                         // wait for logic to settle
            expected = xa + xb + xc;           // golden result
            if ({cout, sum} !== expected) errors = errors + 1;
            // dut.G3 = carries out of each bit (c7..c0) from the prefix network
            $display("t=%4d ns | %3d + %3d + %b = %3d | sum=%b cout=%b | carries c7..c0=%b | %0s | %s",
                     $time, xa, xb, xc, {cout, sum}, sum, cout, dut.G3,
                     ({cout, sum} === expected) ? "PASS" : "FAIL", label);
            #(STEP/2);                         // keep the vector on screen
        end
    endtask

    initial begin
        $dumpfile("demo.vcd");
        $dumpvars(0, tb_demo);          // 0 = dump every signal below tb_demo,
                                        //     including dut.G0..G3 / P0..P3
        errors = 0;
        a = 0; b = 0; cin = 0;
        #50;                            // quiet start so the waveform has no X

        $display("==================================================================================================");
        $display("  DEMO : 8-bit Kogge-Stone prefix adder   (each vector is held for %0d ns)", STEP);
        $display("==================================================================================================");

        //   a     b    cin   description shown in the log
        demo(  0,   0,  0, "all zeros");
        demo(  1,   1,  0, "simplest carry: 1+1");
        demo( 15,   1,  0, "carry across the low nibble");
        demo( 85, 170,  0, "all propagate, NO carries");
        demo( 85, 170,  1, "cin ripples through ALL 8 bits");
        demo(255,   1,  0, "overflow -> cout = 1");
        demo(255, 255,  1, "maximum case: 511");
        demo(128, 128,  0, "only the MSBs generate");
        demo(127,   1,  0, "01111111 + 1 = 10000000");
        demo(200, 100,  1, "ordinary case with cin");

        #STEP;                          // tail so the last vector is visible
        $display("==================================================================================================");
        if (errors == 0) $display("  DEMO RESULT: all vectors PASSED");
        else             $display("  DEMO RESULT: %0d vector(s) FAILED", errors);
        $display("  Waveform saved to demo.vcd  ->  gtkwave demo.vcd demo.gtkw");
        $display("==================================================================================================");
        $finish;
    end
endmodule
