module CORDIC_Vector #(
  parameter WIDTH = 20, 
  parameter ITER = 12
)(
  input         clk,
  input  [16:0] Input_x,
  input  [16:0] Input_y,
  input  [16:0] Input_z,
  output reg [32:0] Output_xn
);

  // K = 0.6072529350 * 2^32
  parameter signed [32:0] K_32 = 33'h0_9b74eda8;  

  localparam INT_WIDTH = 23; // Narrowed to reduce replicated CORDIC carry chains.
  
  // Pad Q16 inputs to Q21 by appending 5 zeros. Sign extend to 24 bits.
  reg signed [INT_WIDTH-1:0] x_00, y_00, z_00;
  
  always @ (posedge clk) begin
    x_00 <= { Input_x[16], Input_x, 5'd0 };
    y_00 <= { Input_y[16], Input_y, 5'd0 };
    z_00 <= { Input_z[16], Input_z, 5'd0 };
  end
  
  reg  signed [INT_WIDTH-1:0]  x[0: ITER-1];
  reg  signed [INT_WIDTH-1:0]  y[0: ITER/2-1];
  reg  signed [INT_WIDTH-1:0]  z[0: ITER-1];
  wire signed [INT_WIDTH-1:0]  x_mid[0: ITER-1];
  wire signed [INT_WIDTH-1:0]  y_mid[0: ITER/2-1];
  wire signed [INT_WIDTH-1:0]  z_mid[0: ITER-1];
  wire signed [INT_WIDTH-1:0]  x_next[0: ITER-1];
  wire signed [INT_WIDTH-1:0]  y_next[0: ITER/2-1];
  wire signed [INT_WIDTH-1:0]  z_next[0: ITER-1];
  reg  signed [INT_WIDTH-1:0]  z_delay;
  
  // Q21 * Q32 = Q53. 24 bits * 33 bits = 57 bits.
  reg  signed [56:0] x_temp;
  reg  signed [56:0] output_temp;

  generate
    genvar i;
    for(i = 0; i < ITER; i = i + 1) begin: roter    
      if (i == 0) 
        CORDIC_Roter #(.SHIFT_BASE(i), .WIDTH(INT_WIDTH))
          rote00 ( .Input_x(x_00),      .Input_y(y_00),
                   .Output_x(x_mid[i]), .Output_y(y_mid[i]));
      else if(i < (ITER/2)) 
        CORDIC_Roter #(.SHIFT_BASE(i*2), .WIDTH(INT_WIDTH))
          rote01 ( .Input_x(x[i-1]),    .Input_y(y[i-1]),
                   .Output_x(x_mid[i]), .Output_y(y_mid[i]));
      else if(i == (ITER/2)) begin 
        wire signed [INT_WIDTH-1:0] x_temp_shifted = x_temp >>> 32; // Q49 -> Q17
        CORDIC_Roter #(.SHIFT_BASE((i-ITER/2)*2), .WIDTH(INT_WIDTH))
            rote02 ( .Input_x(x_temp_shifted), .Input_y(z_delay),
                     .Output_x(x_mid[i]),           .Output_y(z_mid[i]));
      end
      else 
        CORDIC_Roter #(.SHIFT_BASE((i-ITER/2)*2), .WIDTH(INT_WIDTH))
          rote03 ( .Input_x(x[i-1]),    .Input_y(z[i-1]),
                   .Output_x(x_mid[i]), .Output_y(z_mid[i]));

      if(i < (ITER/2))
        CORDIC_Roter #(.SHIFT_BASE(i*2+1), .WIDTH(INT_WIDTH))
          rote04 ( .Input_x(x_mid[i]),   .Input_y(y_mid[i]),
                   .Output_x(x_next[i]), .Output_y(y_next[i]));
      else begin 
        CORDIC_Roter #(.SHIFT_BASE((i-ITER/2)*2+1), .WIDTH(INT_WIDTH))
          rote05 ( .Input_x(x_mid[i]),   .Input_y(z_mid[i]),
                   .Output_x(x_next[i]), .Output_y(z_next[i]));
      end

      if(i < (ITER/2)) begin
        assign z_mid[i] = (i == 0) ? z_00 : z[i-1];
        assign z_next[i] = z_mid[i];
      end

    end
  endgenerate

  integer j;
  always @(posedge clk) begin
    for (j = 0; j < ITER; j = j + 1) begin
      x[j] <= x_next[j];
      z[j] <= z_next[j];
    end

    for (j = 0; j < ITER/2; j = j + 1) begin
      y[j] <= y_next[j];
      end
  end

  always @(posedge clk) begin
    x_temp <= x[ITER/2-1] * K_32;
  end

  always @(posedge clk) begin
    z_delay <= z[ITER/2-1];
  end
  
  always @(posedge clk) begin
    output_temp <= x[ITER-1] * K_32;
    Output_xn <= output_temp >>> 21; // Q53 -> Q32 Output truncation
  end

endmodule
