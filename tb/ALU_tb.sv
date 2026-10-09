`timescale 1ns/1ps

module tb_alu;

    localparam logic [3:0] ALU_ADD   = 4'b0000;
    localparam logic [3:0] ALU_SUB   = 4'b0001;
    localparam logic [3:0] ALU_SLL   = 4'b0010;
    localparam logic [3:0] ALU_SLT   = 4'b0011;
    localparam logic [3:0] ALU_SLTU  = 4'b0100;
    localparam logic [3:0] ALU_XOR   = 4'b0101;
    localparam logic [3:0] ALU_SRL   = 4'b0110;
    localparam logic [3:0] ALU_SRA   = 4'b0111;
    localparam logic [3:0] ALU_OR    = 4'b1000;
    localparam logic [3:0] ALU_AND   = 4'b1001;
    localparam logic [3:0] ALU_COPYB = 4'b1010;

    logic [31:0] a, b;
    logic [3:0]  alu_op;
    logic [31:0] result;
    logic        zero;

    int errors = 0;
    int checks = 0;

    alu dut (
        .a      (a),
        .b      (b),
        .alu_op (alu_op),
        .result (result),
        .zero   (zero)
    );

    // Reference model, written independently of the DUT
    function automatic logic [31:0] ref_alu(input logic [3:0] op,
                                            input logic [31:0] x,
                                            input logic [31:0] y);
        logic signed [31:0] xs, ys;
        xs = x;
        ys = y;
        case (op)
            ALU_ADD:   ref_alu = x + y;
            ALU_SUB:   ref_alu = x - y;
            ALU_SLL:   ref_alu = x << y[4:0];
            ALU_SLT:   ref_alu = (xs < ys) ? 32'd1 : 32'd0;
            ALU_SLTU:  ref_alu = (x < y)   ? 32'd1 : 32'd0;
            ALU_XOR:   ref_alu = x ^ y;
            ALU_SRL:   ref_alu = x >> y[4:0];
            ALU_SRA:   ref_alu = xs >>> y[4:0];
            ALU_OR:    ref_alu = x | y;
            ALU_AND:   ref_alu = x & y;
            ALU_COPYB: ref_alu = y;
            default:   ref_alu = 32'd0;
        endcase
    endfunction

    // Apply one vector and check result and zero flag
    task automatic check(input logic [3:0] op,
                         input logic [31:0] x,
                         input logic [31:0] y);
        logic [31:0] expected;
        begin
            a = x;
            b = y;
            alu_op = op;
            #1;
            expected = ref_alu(op, x, y);
            checks++;
            if (result !== expected) begin
                errors++;
                $display("FAIL op=%b a=%h b=%h : got %h, expected %h",
                         op, x, y, result, expected);
            end
            if (zero !== (expected == 32'd0)) begin
                errors++;
                $display("FAIL zero flag op=%b a=%h b=%h : got %b, expected %b",
                         op, x, y, zero, (expected == 32'd0));
            end
        end
    endtask

    // Edge-case operands
    logic [31:0] edge_vals [0:9];

    initial begin
        edge_vals[0] = 32'h00000000;
        edge_vals[1] = 32'h00000001;
        edge_vals[2] = 32'hFFFFFFFF;  // -1
        edge_vals[3] = 32'h7FFFFFFF;  // max positive
        edge_vals[4] = 32'h80000000;  // min negative
        edge_vals[5] = 32'hAAAAAAAA;
        edge_vals[6] = 32'h55555555;
        edge_vals[7] = 32'h0000001F;  // shift by 31
        edge_vals[8] = 32'h00000020;  // shift by 32 (must wrap to 0)
        edge_vals[9] = 32'hDEADBEEF;

        $display("=== ALU testbench start ===");

        // Directed: every op against every pair of edge values
        for (int op = 0; op < 16; op++)
            for (int i = 0; i < 10; i++)
                for (int j = 0; j < 10; j++)
                    check(op[3:0], edge_vals[i], edge_vals[j]);

        // Specific cases that catch classic bugs
        check(ALU_SRA,  32'h80000000, 32'd4);   // sign bit must propagate
        check(ALU_SRL,  32'h80000000, 32'd4);   // logical shift: zeros in
        check(ALU_SLT,  32'hFFFFFFFF, 32'd1);   // -1 < 1 signed -> 1
        check(ALU_SLTU, 32'hFFFFFFFF, 32'd1);   // max < 1 unsigned -> 0
        check(ALU_SUB,  32'd5, 32'd5);          // zero flag should be 1
        check(ALU_SLL,  32'd1, 32'h00000025);   // only low 5 bits (=5) used

        // Random vectors across all operations
        for (int n = 0; n < 20000; n++)
            check($urandom_range(0, 10), $urandom, $urandom);

        $display("=== Done: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("PASS");
        else             $display("FAIL");
        $finish;
    end

endmodule

