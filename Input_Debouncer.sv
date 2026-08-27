module Input_Debouncer(
	input logic clk,
	input logic rawsignal,
	input logic reset_n,
	output logic press
	
);


logic q1;
logic q2;
// 2 Stage Flip Flop
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        // Set all q bits to 0 when `clear_n` is low (active)
		q1 <= '0;
		q2 <= '0;
    end else if (!clear_n) begin
		q1 <= '0;
		q2 <= '0;
	 end else begin
        // Set all 4 q bits to all 4 d bits on `clock` rising edge
        q1 <= rawsignal;
		  q2 <= q1; // use q2 cleaned signal for counter incremenation
    end
end

Counter C1(



);

Comparator Comp1(


);