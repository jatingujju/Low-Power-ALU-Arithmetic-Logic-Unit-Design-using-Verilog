module lp_adder #(
    parameter WIDTH       = 16,
    parameter APPROX_BITS = 4
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             cin,
    input  wire             mode,
    input  wire             lp_mode,
    output wire [WIDTH-1:0] sum,
    output wire             cout
);

wire [WIDTH:0] ripple_carry;
assign ripple_carry[0] = cin;

wire [WIDTH-1:0] ripple_sum;

genvar i;

generate
for(i=0;i<WIDTH;i=i+1)
begin : RCA

    assign ripple_sum[i] =
        a[i] ^ b[i] ^ ripple_carry[i];

    assign ripple_carry[i+1] =
        (a[i] & b[i]) |
        (a[i] & ripple_carry[i]) |
        (b[i] & ripple_carry[i]);

end
endgenerate

wire ripple_cout = ripple_carry[WIDTH];

wire [WIDTH-1:0] p;
wire [WIDTH-1:0] g;

assign p = a ^ b;
assign g = a & b;

wire [WIDTH:0] cla_carry;
assign cla_carry[0] = cin;

generate
for(i=0;i<WIDTH;i=i+1)
begin : CLA

    assign cla_carry[i+1] =
        g[i] | (p[i] & cla_carry[i]);

end
endgenerate

wire [WIDTH-1:0] cla_sum;
assign cla_sum = p ^ cla_carry[WIDTH-1:0];

wire cla_cout = cla_carry[WIDTH];

wire [WIDTH-1:0] exact_sum;
wire exact_cout;

assign exact_sum  = mode ? cla_sum : ripple_sum;
assign exact_cout = mode ? cla_cout : ripple_cout;

reg [WIDTH-1:0] final_sum;

integer k;

always @(*) begin

    final_sum = exact_sum;

    if(lp_mode) begin
        for(k=0;k<APPROX_BITS;k=k+1)
            final_sum[k] = a[k] ^ b[k];
    end

end

assign sum  = final_sum;
assign cout = exact_cout;

endmodule