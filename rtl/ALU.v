module alu (
    input  wire [31:0] a,        // operand A (rs1 or PC)
    input  wire [31:0] b,        // operand B (rs2 or immediate)
    input  wire [3:0]  alu_op,   // operation select (from ALU control)
    output reg  [31:0] result,
    output wire        zero      // result == 0 (handy for BEQ/BNE)
);

    // ALU operation encodings (keep in sync with your ALU control block)
    localparam ALU_ADD   = 4'b0000;
    localparam ALU_SUB   = 4'b0001;
    localparam ALU_SLL   = 4'b0010;
    localparam ALU_SLT   = 4'b0011;
    localparam ALU_SLTU  = 4'b0100;
    localparam ALU_XOR   = 4'b0101;
    localparam ALU_SRL   = 4'b0110;
    localparam ALU_SRA   = 4'b0111;
    localparam ALU_OR    = 4'b1000;
    localparam ALU_AND   = 4'b1001;
    localparam ALU_COPYB = 4'b1010;  // pass B through (for LUI)

    wire [4:0] shamt = b[4:0];       // shifts use only the low 5 bits of B

    wire signed [31:0] a_s = a;      // signed views for SLT and SRA
    wire signed [31:0] b_s = b;

    always @(*) begin
        case (alu_op)
            ALU_ADD:   result = a + b;
            ALU_SUB:   result = a - b;
            ALU_SLL:   result = a << shamt;
            ALU_SLT:   result = {31'b0, (a_s < b_s)};
            ALU_SLTU:  result = {31'b0, (a < b)};
            ALU_XOR:   result = a ^ b;
            ALU_SRL:   result = a >> shamt;
            ALU_SRA:   result = a_s >>> shamt;
            ALU_OR:    result = a | b;
            ALU_AND:   result = a & b;
            ALU_COPYB: result = b;
            default:   result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);

endmodule
