
//Vertical Counter: Counts ticks from 0 to 800 to time when to increment the Vsync row (Uses 2 counters and comparators)
module VerticalCounter #(
	parameter START = 0,
	parameter MIDDLE = 2,
	
	parameter END = 525

)(
	input logic clk, //Internal Clock
	input logic reset_n, //Button for Resetting
	input logic enable_n,

	output logic result 

);


logic [9:0] count1;
logic [9:0] count2;
logic compare1;
logic compare2;

//Simple sequential logic for each tick of the clock or reset button to make the result output 1 or 0 depending on what pixel its on
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		result <= 1'b0;
	end else begin 
		if (count2 == START) begin
			result <= 1'b0;
		end else if(count2 == MIDDLE) begin
			result <= 1'b1;
		end
	end
end

//Instantiate a counter module and comparator to complete a full line for HSync
Counter #(.N(10)) C1(
	.clock(clk),
	.reset_n(reset_n),
	.count(count1),
	.enable_n(enable_n),
	.addBy(10'd1),
	.clear_n(~compare1)

);

Comparator #(.N(10), .MAX_VAL(800)) Comp1(
	.check(count1),
	.compare(compare1)
);


//Tick count2 to represent when Vsync changes lines vertically
Counter #(.N(10)) C2 (
	.clock(clk),
	.reset_n(reset_n),
	.count(count2),
	.enable_n(~compare1),
	.addBy(10'd1),
	.clear_n(~(compare1 & compare2))

);

Comparator #(.N(10), .MAX_VAL(END)) Comp2(
	.check(count2),
	.compare(compare2)

);


endmodule