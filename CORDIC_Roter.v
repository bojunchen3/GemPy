module CORDIC_Roter #(
  parameter SHIFT_BASE = 0,
  parameter WIDTH      = 20
)(
  input      signed [WIDTH-1:0] Input_x,
  input      signed [WIDTH-1:0] Input_y,
  output reg signed [WIDTH-1:0] Output_x,
  output reg signed [WIDTH-1:0] Output_y
);

  wire signed [WIDTH-1:0] shift_x;
  wire signed [WIDTH-1:0] shift_y;

  generate
    if (SHIFT_BASE == 0) begin
      assign shift_x = Input_x;
      assign shift_y = Input_y;
    end else begin
      assign shift_x = (Input_x >>> SHIFT_BASE) + $signed({1'b0, Input_x[SHIFT_BASE-1]});
      assign shift_y = (Input_y >>> SHIFT_BASE) + $signed({1'b0, Input_y[SHIFT_BASE-1]});
    end
  endgenerate

  always @(*) begin
    if (!Input_y[WIDTH-1]) begin // Y >= 0
      Output_x = Input_x + shift_y;
      Output_y = Input_y - shift_x;
    end
    else begin                   // Y < 0
      Output_x = Input_x - shift_y;
      Output_y = Input_y + shift_x;
    end
  end

endmodule
