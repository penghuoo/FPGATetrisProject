	module Counter #(
	parameter N = 4 // How many bits the counter can hold and represent in numbers i.e 4 = 4 bits and p to number 16
)(
	input logic clock,
	input logic clear_n,
	input logic [N-1:0] addBy,
	input logic enable_n,
	input logic reset_n,
	output logic [N-1:0] count
);


logic [N-1:0] count_next;

//assign count_next = count + addBy;

//assign count_next = (!enable_n) ? (count + addBy) : count;

	always_comb begin
		if(!enable_n) begin
			count_next = count + addBy;
		end else begin
			count_next = count;
		end
	end
	


	
	RegisterFourBit #(.N(N)) RFB1(
		.clock (clock),
		.clear_n (clear_n),
		.reset_n (reset_n),
		.d (count_next),
		.q (count)
	);	
	
endmodule