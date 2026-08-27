module Comparator #(
	parameter N = 6,
	parameter MAX_VAL = 59
)(
	input logic [N-1:0] check, // The input that is being checked
	output logic compare //Send back to clear_n whether the two numbers are equal
);

assign compare = (check >= MAX_VAL);

endmodule

//Compare time and 59 to get equal output

