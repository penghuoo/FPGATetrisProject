module Input_Debouncer #(
	parameter DELAY = 1000000 

)(
	input logic clk,
	input logic rawsignal,
	input logic reset_n,
	output logic press // Flip to high signal 
	
);

// Data line variables
logic q1;
logic q2;

logic [19:0]count1;
logic compare1;
logic clean_signal_prev;

assign press = compare1 & ~clean_signal_prev;
// 2 Stage Flip Flop
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        // Set all q and previous signal bits to 0 when `clear_n` is low (active)
		q1 <= '0;
		q2 <= '0;
		clean_signal_prev <= '0;
	 end else begin
        // Set all 4 q bits to all 4 d bits on `clock` rising edge
        q1 <= ~rawsignal; //Raw signal to q1
		  q2 <= q1; // use q2 cleaned signal for counter incremenation
		  clean_signal_prev <= compare1;
    end
end

Counter #(.N(20)) C1(
	.clock(clk),
	.clear_n(q2), // Clears counter when button is pressed
	.addBy(20'd1),
	.enable_n(compare1), // Run until 1000000 is reached
	.reset_n(reset_n),
	.count(count1)


);

Comparator #(.N(20), .MAX_VAL(1000000)) Comp1(
	.check(count1),
	.compare(compare1)
);




endmodule