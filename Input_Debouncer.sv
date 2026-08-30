module Input_Debouncer(
	input logic clk,
	input logic rawsignal,
	input logic reset_n,
	output logic press // Flip to high signal 
	
);


logic q1;
logic q2;

logic [19:0]count1;
logic compare1;

assign press = compare1;
// 2 Stage Flip Flop
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        // Set all q bits to 0 when `clear_n` is low (active)
		q1 <= '0;
		q2 <= '0;
	 end else begin
        // Set all 4 q bits to all 4 d bits on `clock` rising edge
        q1 <= ~rawsignal; //ACti
		  q2 <= q1; // use q2 cleaned signal for counter incremenation
    end
end

Counter #.(.N(20)) C1(
	.clock(clk),
	.clear_n(~compare1 & q2), // Clears the counter when comparator reaches max value, or if q2 reaches high (Not pressed). If either are 0, then clear_n is triggered
	.addBy(10'd1),
	.enable_n(1'b0), // Run Continuously when not being cleared 
	.reset_n(reset_n),
	.count(count1)


);

Comparator #(.N(20), .MAX_VAL(1000000)) Comp1(
	.check(count1),
	.compare(compare1)
);