module Parser #(
	parameter N = 6
)(
	input logic [N-1:0] number,
	output logic [3:0] ones,
	output logic [3:0] tens
);

always_comb begin
	tens = number / 10;
	ones = number % 10;
	
end
endmodule

