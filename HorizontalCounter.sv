
//Module that goes low for 96 and high for 704 (Line Counter)
module HorizontalCounter #(
	parameter START = 0,
	parameter MIDDLE = 96,
	
	parameter END = 800

)(
	input logic clk, //Internal Clock
	input logic reset_n, //Button for Resetting
	input logic enable_n,

	output logic result 

);


logic [9:0] count1;
logic compare1;

//Simple sequential logic for each tick of the clock or reset button to make the result output 1 or 0 depending on what pixel its on
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		result <= 1'b0;
	end else begin 
		if (count1 == START) begin
			result <= 1'b0;
		end else if(count1 == MIDDLE) begin
			result <= 1'b1;
		end
	end
end

//Instantiate a counter module and comparator 
Counter #(.N(10)) C1(
	.clock(clk),
	.reset_n(reset_n),
	.count(count1),
	.enable_n(enable_n),
	.addBy(10'd1),
	.clear_n(~compare1)

);
 
Comparator #(.N(10), .MAX_VAL(END)) Comp2(
	.check(count1),
	.compare(compare1)
);

endmodule