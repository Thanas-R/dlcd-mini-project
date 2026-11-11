//==============================================================
// File    : prefix_adder_8.v
// Project : 8-bit Parallel Prefix (Kogge-Stone) Adder
// Course  : Digital Logic and Computer Design (UE25CS251A)
//
// Computes  {cout, sum} = a + b + cin   (all unsigned)
// The design is purely combinational (no clock, no state/FSM).
//
// Idea: instead of letting the carry ripple through 8 bits one
// after the other, we compute every carry in parallel using a
// "prefix network" with only log2(8) = 3 levels.
//==============================================================

//--------------------------------------------------------------
// prefix_cell : the "black cell" of the prefix network.
//
// It merges two neighbouring bit-groups into one bigger group:
//   hi = the more significant group, lo = the less significant one
//
//   G_out = G_hi | (P_hi & G_lo)  -> the combined group GENERATES a
//                                    carry if hi generates one, or hi
//                                    propagates a carry made by lo.
//   P_out = P_hi & P_lo           -> the combined group PROPAGATES an
//                                    incoming carry only if both do.
//
// Cost: 2 AND gates + 1 OR gate (3 two-input gates).
//--------------------------------------------------------------
module prefix_cell (
    input  g_hi, p_hi,   // generate / propagate of the high group
    input  g_lo, p_lo,   // generate / propagate of the low group
    output g_out, p_out  // generate / propagate of the merged group
);
    assign g_out = g_hi | (p_hi & g_lo);
    assign p_out = p_hi & p_lo;
endmodule

//--------------------------------------------------------------
// prefix_adder_8 : top-level 8-bit adder with carry-in.
//--------------------------------------------------------------
module prefix_adder_8 (
    input  [7:0] a,     // first operand
    input  [7:0] b,     // second operand
    input        cin,   // carry-in
    output [7:0] sum,   // 8-bit sum
    output       cout   // carry-out (bit 8 of the result)
);
    // ---- Internal signals -------------------------------------
    wire [7:0] p, g;     // per-bit propagate / generate
    wire [7:0] G0, P0;   // after pre-processing (cin folded into bit 0)
    wire [7:0] G1, P1;   // after prefix level 1 (groups of 2 bits,  distance 1)
    wire [7:0] G2, P2;   // after prefix level 2 (groups of 4 bits,  distance 2)
    wire [7:0] G3, P3;   // after prefix level 3 (groups of 8 bits,  distance 4)
                         // G3[i] = carry OUT of bit i  (the carry we want)

    // ---- Stage 1 : pre-processing -----------------------------
    // p[i] = a[i] XOR b[i] : bit i passes a carry through
    // g[i] = a[i] AND b[i] : bit i creates a carry by itself
    assign p = a ^ b;
    assign g = a & b;

    // Fold the carry-in into bit 0 so the network needs no extra input:
    //   G0[0] = g[0] | (p[0] & cin)  = carry out of bit 0
    // Bits 1..7 are unchanged.
    assign G0 = {g[7:1], g[0] | (p[0] & cin)};
    assign P0 = p;

    genvar i;   // loop variable used by the generate blocks below

    // ---- Stage 2 : prefix network (Kogge-Stone) ----------------
    // At each level, every bit i (that has a partner) merges with
    // the bit "distance" positions below it. The distance doubles:
    // 1, 2, 4. After 3 levels bit i covers bits [i:0].

    // Level 1 : distance = 1   (7 cells: bits 1..7)
    generate
        for (i = 0; i < 8; i = i + 1) begin : LVL1
            if (i < 1) begin : PASS            // no partner -> copy through
                assign G1[i] = G0[i];
                assign P1[i] = P0[i];
            end else begin : CELL              // merge with bit i-1
                prefix_cell u (
                    .g_hi(G0[i]),   .p_hi(P0[i]),
                    .g_lo(G0[i-1]), .p_lo(P0[i-1]),
                    .g_out(G1[i]),  .p_out(P1[i]));
            end
        end
    endgenerate

    // Level 2 : distance = 2   (6 cells: bits 2..7)
    generate
        for (i = 0; i < 8; i = i + 1) begin : LVL2
            if (i < 2) begin : PASS
                assign G2[i] = G1[i];
                assign P2[i] = P1[i];
            end else begin : CELL              // merge with bit i-2
                prefix_cell u (
                    .g_hi(G1[i]),   .p_hi(P1[i]),
                    .g_lo(G1[i-2]), .p_lo(P1[i-2]),
                    .g_out(G2[i]),  .p_out(P2[i]));
            end
        end
    endgenerate

    // Level 3 : distance = 4   (4 cells: bits 4..7)
    generate
        for (i = 0; i < 8; i = i + 1) begin : LVL3
            if (i < 4) begin : PASS
                assign G3[i] = G2[i];
                assign P3[i] = P2[i];
            end else begin : CELL              // merge with bit i-4
                prefix_cell u (
                    .g_hi(G2[i]),   .p_hi(P2[i]),
                    .g_lo(G2[i-4]), .p_lo(P2[i-4]),
                    .g_out(G3[i]),  .p_out(P3[i]));
            end
        end
    endgenerate
    // Total prefix cells: 7 + 6 + 4 = 17.  (P3 is unused: the carry
    // only needs the G outputs, so synthesis will drop it.)

    // ---- Stage 3 : post-processing ----------------------------
    // The carry INTO bit i is the carry OUT of bit i-1; into bit 0 it is cin.
    //   sum[i] = p[i] XOR carry_into_bit_i
    assign sum  = p ^ {G3[6:0], cin};
    assign cout = G3[7];   // carry out of the top bit
endmodule
