module low_power_alu #(
    parameter WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  en,
    input  wire                  lp_mode,

    input  wire [WIDTH-1:0]      A,
    input  wire [WIDTH-1:0]      B,
    input  wire [3:0]            opcode,

    output reg  [WIDTH-1:0]      result,
    output reg                   zero,
    output reg                   carry,
    output reg                   overflow,
    output reg                   negative
);

    // Operand Isolation
    wire [WIDTH-1:0] A_iso;
    wire [WIDTH-1:0] B_iso;

    assign A_iso = en ? A : {WIDTH{1'b0}};
    assign B_iso = en ? B : {WIDTH{1'b0}};

    // Shift Amount Logic
    localparam SHIFT_W =
        (WIDTH <= 2 ) ? 1 :
        (WIDTH <= 4 ) ? 2 :
        (WIDTH <= 8 ) ? 3 :
        (WIDTH <= 16) ? 4 :
        (WIDTH <= 32) ? 5 : 6;

    wire [SHIFT_W-1:0] shift_amt;

    assign shift_amt =
        lp_mode ?
        B_iso[1:0] :
        B_iso[SHIFT_W-1:0];

    reg [WIDTH-1:0] alu_result;
    reg carry_next;
    reg overflow_next;
    reg [WIDTH:0] temp;

    always @(*) begin

        alu_result    = {WIDTH{1'b0}};
        carry_next    = 1'b0;
        overflow_next = 1'b0;
        temp          = {(WIDTH+1){1'b0}};

        case(opcode)

            // ADD
            4'b0000: begin
                temp = A_iso + B_iso;

                alu_result = temp[WIDTH-1:0];
                carry_next = temp[WIDTH];

                overflow_next =
                    (~A_iso[WIDTH-1] &
                     ~B_iso[WIDTH-1] &
                      alu_result[WIDTH-1]) |
                    ( A_iso[WIDTH-1] &
                      B_iso[WIDTH-1] &
                     ~alu_result[WIDTH-1]);
            end

            // SUB
            4'b0001: begin
                temp = A_iso - B_iso;

                alu_result = temp[WIDTH-1:0];
                carry_next = temp[WIDTH];

                overflow_next =
                    (~A_iso[WIDTH-1] &
                      B_iso[WIDTH-1] &
                      alu_result[WIDTH-1]) |
                    ( A_iso[WIDTH-1] &
                     ~B_iso[WIDTH-1] &
                     ~alu_result[WIDTH-1]);
            end

            // AND
            4'b0010:
                alu_result = A_iso & B_iso;

            // OR
            4'b0011:
                alu_result = A_iso | B_iso;

            // XOR
            4'b0100:
                alu_result = A_iso ^ B_iso;

            // NOT
            4'b0101:
                alu_result = ~A_iso;

            // SHIFT LEFT
            4'b0110:
                alu_result = A_iso << shift_amt;

            // SHIFT RIGHT
            4'b0111:
                alu_result = A_iso >> shift_amt;

            // INC
            4'b1000: begin
                temp = A_iso + 1'b1;
                alu_result = temp[WIDTH-1:0];
                carry_next = temp[WIDTH];
            end

            // DEC
            4'b1001: begin
                temp = A_iso - 1'b1;
                alu_result = temp[WIDTH-1:0];
                carry_next = temp[WIDTH];
            end

            // COMPARE
            4'b1010:
                alu_result =
                    (A_iso == B_iso) ?
                    {{(WIDTH-1){1'b0}},1'b1} :
                    {WIDTH{1'b0}};

            default: begin
                alu_result    = {WIDTH{1'b0}};
                carry_next    = 1'b0;
                overflow_next = 1'b0;
            end

        endcase
    end

    // Registered Outputs
    always @(posedge clk or negedge rst_n) begin

        if(!rst_n) begin

            result   <= {WIDTH{1'b0}};
            carry    <= 1'b0;
            overflow <= 1'b0;
            zero     <= 1'b0;
            negative <= 1'b0;

        end
        else if(en) begin

            result   <= alu_result;
            carry    <= carry_next;
            overflow <= overflow_next;

            zero     <= (alu_result == 0);
            negative <= alu_result[WIDTH-1];

        end

    end

endmodule