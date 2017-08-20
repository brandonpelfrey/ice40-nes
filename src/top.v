module clk_divider(clkin, clkout);
	input clkin;
	output clkout;

	reg [20:0] counter;

	assign clkout = counter[20];

	always @(posedge clkin) begin
		counter <= counter + 1;
	end
endmodule

module top(hwclk, led1, led2, led3, led4, led5, led6, led7, led8);
    input hwclk;
    output led1;
    output led2;
    output led3;
    output led4;
    output led5;
    output led6;
    output led7;
    output led8;

    assign led1 = counter[0];
    assign led2 = counter[1];
    assign led3 = counter[2];
    assign led4 = counter[3];
    assign led5 = counter[4];
    assign led6 = counter[5];
    assign led7 = counter[6];
    assign led8 = counter[7];

    reg [7:0] counter;

    wire clk;
    clk_divider base_clk(hwclk, clk);

    always @ (posedge clk) begin
        counter <= counter + 1;
    end
endmodule
