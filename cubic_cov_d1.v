module cubic_cov_d1 #(
  parameter integer DATA_WIDTH = 32
)(
  input  wire clk,
  input  wire [DATA_WIDTH:0] r_q32,         

  // diable register retiming for output to preserve timing
  (* dont_touch = "yes" *) output reg signed [35:0] ans_q32  
);

  localparam signed [27:0] C5 =  28'sd2146529;     //  0.12794 * 2^24
  localparam signed [27:0] C3 = -28'sd20678229;    // -1.23252 * 2^24
  localparam signed [27:0] C1 =  28'sd89640122;    //  5.34297 * 2^24
  localparam signed [27:0] C0 = -28'sd81273711;    // -4.84429 * 2^24

  wire [24:0] r_q24 = r_q32[DATA_WIDTH:8];

  // Stage 1 signals
  wire [48:0] r2_full;
  wire [24:0] r2_w;
  reg  [24:0] r_s1, r2_s1;

  // 28 bits * 25 bits = 53 bits
  wire signed [53:0] mac2_full, mac3_full, mac4_full;
  wire signed [28:0] add2_w, add3_w, add4_w;
  
  reg  signed [28:0] add2_q, add3_q;
  reg  [24:0] r_s2, r2_s2, r_s3;

  // -------------------------
  // Stage 1: r2 = r*r
  // -------------------------
  assign r2_full = r_q24 * r_q24; 
  assign r2_w    = r2_full[48:24];

  // -------------------------
  // Stage 2: s1 = C5*r2 + C3
  // -------------------------
  assign mac2_full = (C5 * $signed({1'b0, r2_s1})) + (C3 <<< 24);
  assign add2_w    = mac2_full >>> 24;

  // -------------------------
  // Stage 3: s2 = s1*r2 + C1
  // -------------------------
  assign mac3_full = (add2_q * $signed({1'b0, r2_s2})) + (C1 <<< 24);
  assign add3_w    = mac3_full >>> 24;

  // -------------------------
  // Stage 4: s3 = s2*r + C0
  // -------------------------
  assign mac4_full = (add3_q * $signed({1'b0, r_s3})) + (C0 <<< 24);
  assign add4_w    = mac4_full >>> 24;

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
    add3_q <= add3_w;

    // Stage4 regs (Output Formatting)
    ans_q32 <= $signed({add4_w, 8'd0});
  end

endmodule
