module Decoder2_4(
	input logic [1:0] a,
	
	output logic [3:0] y
);

	always_comb
		case(a)
		
			2'b00: y = 4'b0000;
			2'b01: y = 4'b0101;
			2'b10: y = 4'b1010;
			2'b11: y = 4'b1111;
			default: y = 4'bxxxx;
		endcase
		
endmodule