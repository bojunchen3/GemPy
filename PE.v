module PE #(
    parameter DATA_WIDTH = 16,
    parameter OUT_WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  aresetn,
    input  wire                  load,       // load matrix value if high
    input  wire [31:0] matrix_in,  // input matrix value
    input  wire [DATA_WIDTH-1:0] top_in, 
    input  wire [OUT_WIDTH+1:0]  left_in,
    output reg  [DATA_WIDTH-1:0] down_out,  
    output reg  [OUT_WIDTH+1:0]  partial_out // ruslut for right PE 
);

    reg  signed [31:0] matrix_val;
    wire signed [48:0] temp;

    // assign temp = ($signed(matrix_val) * $signed(top_in)) >>> 21; // 16+5=21
    assign temp = ($signed(matrix_val) * $signed({1'b0, top_in})) >>> 21; // 16+5=21

    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            partial_out <= 0;
            down_out    <= 0;
        end
        else begin
          partial_out <= left_in + temp;
          down_out    <= top_in;  // no change 
        end
    end

    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            matrix_val  <= 0;
        end
        else begin
            if (load)
                matrix_val <= matrix_in;
        end
    end

endmodule
