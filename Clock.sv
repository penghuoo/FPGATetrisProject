module Clock (
	
	input logic clock, //Internal Clock
	input logic reset_n, //Reset button linked to all clear_n
	
	output logic [25:0]tick,
	output logic [5:0] seconds, //60 Seconds
	output logic [5:0] minutes, // 60 Minutes
	output logic [4:0] hours	// 60 hours
	
);


logic [25:0] count1;
logic compare1;

assign tick = count1;
//set max val to 4 when doing test bench

Comparator #(.N(26), .MAX_VAL(49999999)) Comp1(
	.check(count1),
	.compare(compare1)
);

//Counter for the tick count
Counter #(.N(26)) C1(
	.clock(clock),
	.clear_n(~compare1),
	.addBy(26'd1),
	.reset_n(reset_n),
	.enable_n(1'b0),
	.count(count1)

);

logic [5:0] count2;
logic compare2;

assign seconds = count2;

//Counter for seconds count
Comparator #(.N(6), .MAX_VAL(59)) Comp2(
	.check(count2),
	.compare(compare2)
);

Counter #(.N(6))C2 (
	.clock(clock),
	.reset_n(reset_n),
	.count(count2),
	.enable_n(~compare1),
	.addBy(6'd1),
	.clear_n(~(compare1 & compare2))

);

logic [5:0] count3;
logic compare3;

assign minutes = count3;


//Counter for minutes count
Comparator #(.N(6), .MAX_VAL(59)) Comp3(
	.check(count3),
	.compare(compare3)
);

Counter #(.N(6)) C3 (
	.clock(clock),
	.reset_n(reset_n),
	.count(count3),
	.enable_n(~(compare1 & compare2)),
	.addBy(6'd1),
	.clear_n(~(compare1 & compare2 & compare3))
);

logic [4:0] count4;
logic compare4;

assign hours = count4;


//Counter for hours count
Comparator #(.N(5), .MAX_VAL(23)) Comp4(
	.check(count4),
	.compare(compare4)
);

Counter #(.N(5)) C4(
	.clock(clock),
	.reset_n(reset_n),
	.count(count4),
	.enable_n(~(compare1 & compare2 & compare3)),
	.addBy(5'd1),
	.clear_n(~(compare1 & compare2 & compare3 & compare4))
);



endmodule