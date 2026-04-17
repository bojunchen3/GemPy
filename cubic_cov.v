module cubic_cov #(
  parameter integer DATA_WIDTH = 32
)(
  input  wire clk,
  input  wire [DATA_WIDTH:0] r_q32,         

  // disable register retiming and logic optimization
  (* dont_touch = "yes" *) output reg signed [34:0] ans_q32  
);

  localparam signed [27:0] C7 =  28'sd306647;      //  0.01828 * 2^24
  localparam signed [27:0] C5 = -28'sd4135646;     // -0.2465  * 2^24
  localparam signed [27:0] C3 =  28'sd29880041;    //  1.78099 * 2^24
  localparam signed [27:0] C2 = -28'sd40636855;    // -2.42215 * 2^24
  localparam signed [27:0] C0 =  28'sd16777216;    //  1.0     * 2^24

  wire [24:0] r_q24 = r_q32[DATA_WIDTH:8];

  // Stage 1 signals
  wire [48:0] r2_full;
  wire [24:0] r2_w;
  reg  [24:0] r_s1, r2_s1;

  // Stage 2~5 signals
  // 28 bits  * 25 bits  = 53 bits
  wire signed [53:0] mac2_full, mac3_full, mac4_full, mac5_full;
  wire signed [28:0] add2_w, add3_w, add4_w, add5_w;
  
  reg  signed [28:0] add2_q, add3_q, add4_q;
  reg  [24:0] r_s2, r2_s2, r_s3, r2_s3, r2_s4;

  // -------------------------
  // Stage 1: r2 = r*r
  // -------------------------
  assign r2_full = r_q24 * r_q24; 
  assign r2_w    = r2_full[48:24];

  // -------------------------
  // Stage 2: s1 = C7*r2 + C5
  // -------------------------
  assign mac2_full = (C7 * $signed({1'b0, r2_s1})) + (C5 <<< 24);
  assign add2_w    = mac2_full >>> 24;

  // -------------------------
  // Stage 3: s2 = s1*r2 + C3
  // -------------------------
  assign mac3_full = (add2_q * $signed({1'b0, r2_s2})) + (C3 <<< 24);
  assign add3_w    = mac3_full >>> 24;

  // -------------------------
  // Stage 4: s3 = s2*r + C2
  // -------------------------
  assign mac4_full = (add3_q * $signed({1'b0, r_s3})) + (C2 <<< 24);
  assign add4_w    = mac4_full >>> 24;

  // -------------------------
  // Stage 5: s4 = s3*r2 + C0
  // -------------------------
  assign mac5_full = (add4_q * $signed({1'b0, r2_s4})) + (C0 <<< 24);
  assign add5_w    = mac5_full >>> 24;

  // -------------------------
  // Pipeline Registers
  // -------------------------
  always @(posedge clk) begin
    // Stage1 regs
    r_s1  <= r_q24;
    r2_s1 <= r2_w;

    // Stage2 regs
    r_s2   <= r_s1;
    r2_s2  <= r2_s1;
    add2_q <= add2_w;

    // Stage3 regs
    r_s3   <= r_s2;
    r2_s3  <= r2_s2;
    add3_q <= add3_w;

    // Stage4 regs
    r2_s4  <= r2_s3;
    add4_q <= add4_w;

    // Stage5 regs (Output Formatting)
    ans_q32 <= $signed({add5_w[27:0], 8'd0});
  end

endmodule
