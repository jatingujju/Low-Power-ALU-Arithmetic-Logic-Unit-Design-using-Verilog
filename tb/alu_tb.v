`timescale 1ns/1ps

module alu_tb;

parameter WIDTH = 16;

reg clk;
reg rst_n;

reg en;
reg lp_mode;

reg [WIDTH-1:0] A;
reg [WIDTH-1:0] B;
reg [3:0] opcode;

wire [WIDTH-1:0] result;
wire zero;
wire carry;
wire overflow;
wire negative;

integer pass_count;
integer fail_count;

low_power_alu #(
    .WIDTH(WIDTH)
)
dut (
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .lp_mode(lp_mode),
    .A(A),
    .B(B),
    .opcode(opcode),
    .result(result),
    .zero(zero),
    .carry(carry),
    .overflow(overflow),
    .negative(negative)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

task check_result;
input [WIDTH-1:0] expected;
begin
    @(posedge clk);
    #1;

    if(result === expected) begin
        pass_count = pass_count + 1;
        $display("[PASS] opcode=%b expected=%h got=%h",
                 opcode, expected, result);
    end
    else begin
        fail_count = fail_count + 1;
        $display("[FAIL] opcode=%b expected=%h got=%h",
                 opcode, expected, result);
    end
end
endtask

initial begin

    $dumpfile("alu_power.vcd");
    $dumpvars(0, alu_tb);

    pass_count = 0;
    fail_count = 0;

    rst_n = 0;
    en = 0;
    lp_mode = 0;
    A = 0;
    B = 0;
    opcode = 0;

    repeat(3) @(posedge clk);

    rst_n = 1;
    en = 1;

    A = 16'd25;
    B = 16'd10;
    opcode = 4'b0000;
    check_result(16'd35);

    A = 16'd50;
    B = 16'd15;
    opcode = 4'b0001;
    check_result(16'd35);

    A = 16'h00FF;
    B = 16'h0F0F;
    opcode = 4'b0010;
    check_result(16'h000F);

    opcode = 4'b0011;
    check_result(16'h0FFF);

    opcode = 4'b0100;
    check_result(16'h0FF0);

    A = 16'h00FF;
    opcode = 4'b0101;
    check_result(~16'h00FF);

    A = 16'h0003;
    B = 16'd2;
    opcode = 4'b0110;
    check_result(16'h000C);

    opcode = 4'b0111;
    check_result(16'h0000);

    A = 16'd99;
    opcode = 4'b1000;
    check_result(16'd100);

    opcode = 4'b1001;
    check_result(16'd98);

    A = 16'h1234;
    B = 16'h1234;
    opcode = 4'b1010;
    check_result(16'h0001);

    A = 16'd5;
    B = 16'd5;
    opcode = 4'b0001;

    @(posedge clk);
    #1;

    if(zero)
        $display("[PASS] ZERO FLAG");
    else
        $display("[FAIL] ZERO FLAG");

    A = 16'd5;
    B = 16'd10;
    opcode = 4'b0001;

    @(posedge clk);
    #1;

    if(negative)
        $display("[PASS] NEGATIVE FLAG");
    else
        $display("[FAIL] NEGATIVE FLAG");

    en = 0;
    A = 16'hFFFF;
    B = 16'hFFFF;
    opcode = 4'b0000;

    repeat(2) @(posedge clk);

    en = 1;
    lp_mode = 1;

    A = 16'h1234;
    B = 16'h0007;
    opcode = 4'b0110;

    repeat(2) @(posedge clk);

    repeat(100) begin
        A = $random;
        B = $random;
        opcode = $random % 11;
        @(posedge clk);
    end

    $display("--------------------------------");
    $display("PASS COUNT = %0d", pass_count);
    $display("FAIL COUNT = %0d", fail_count);
    $display("--------------------------------");

    $finish;

end

endmodule