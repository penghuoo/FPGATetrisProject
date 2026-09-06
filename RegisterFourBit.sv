module RegisterFourBit #(
	parameter N = 4,
	parameter M = 0 //Reset to 0
)(
	input logic clock,
	input logic clear_n,
	input logic [N-1:0] d,
	output logic [N-1:0] q,
	input logic reset_n
);

always_ff @(posedge clock or negedge reset_n) begin //clear_n before
    if (!reset_n) begin
        // Set all q bits to 0 when `clear_n` is low (active)
		q <= M;
    end else if (!clear_n) begin
		q <= M;
		
	 end else begin
        // Set all 4 q bits to all 4 d bits on `clock` rising edge
        q <= d;
    end
end

endmodule
