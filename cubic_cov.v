module cubic_cov #(
  parameter integer DATA_WIDTH = 32
)(
  input  wire clk,
  input  wire [DATA_WIDTH:0] r_q32,         
  (* dont_touch = "yes", keep = "true" *) output reg signed [34:0] ans_q32  
);

  localparam signed [35:0] C7 =  36'sd78512002;      
  localparam signed [35:0] C5 = -36'sd1058709438;    
  localparam signed [35:0] C3 =  36'sd7649293804;    
  localparam signed [35:0] C2 = -36'sd10403055036;   
  localparam signed [35:0] C0 =  36'sd4294967296;    

  wire [32:0] r_q32_val = r_q32[DATA_WIDTH:0];

  wire signed [24:0] r_s = $signed({1'b0, r_q32_val[32:9]}); // Truncated to Q23

  wire signed [49:0] r2_full = r_s * r_s; 
  wire signed [24:0] r2_w    = r2_full[48:24]; // Truncated to Q22

  reg signed [24:0] r2_s1, r2_s2, r2_s3, r2_s4, r2_s5, r2_s6, r2_s7;
  reg signed [24:0] r_s1, r_s2, r_s3, r_s4, r_s5;

  wire signed [60:0] mac2_full, mac3_full, mac4_full, mac5_full;
  wire signed [36:0] add2_w, add3_w, add4_w, add5_w;
  (* dont_touch = "yes" *) reg signed [60:0] mac2_q, mac3_q, mac4_q, mac5_q;
  
  (* dont_touch = "yes" *) reg signed [36:0] add2_q, add3_q, add4_q;

  assign mac2_full = mac2_q + (C5 <<< 22);
  assign add2_w    = mac2_full >>> 22; // Truncation back to Q32

  assign mac3_full = mac3_q + (C3 <<< 22);
  assign add3_w    = mac3_full >>> 22; 

  assign mac4_full = mac4_q + (C2 <<< 23);
  assign add4_w    = mac4_full >>> 23; 

  assign mac5_full = mac5_q + (C0 <<< 22); 
  assign add5_w    = mac5_full >>> 22; 

  always @(posedge clk) begin
    r_s1  <= r_s;
    r2_s1 <= r2_w;

    r_s2   <= r_s1;
    r2_s2  <= r2_s1;
    mac2_q <= C7 * r2_s1;

    r_s3   <= r_s2;
    r2_s3  <= r2_s2;
    add2_q <= add2_w;

    r_s4   <= r_s3;
    r2_s4  <= r2_s3;
    mac3_q <= add2_q * r2_s3;

    r2_s5  <= r2_s4;
    r_s5   <= r_s4;
    add3_q <= add3_w;

    r2_s6  <= r2_s5;
    mac4_q <= add3_q * r_s5;

    r2_s7  <= r2_s6;
    add4_q <= add4_w;

    mac5_q <= add4_q * r2_s7;

    ans_q32 <= add5_w[34:0];
  end

endmodule
