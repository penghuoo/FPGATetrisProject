module FSM (
	input logic clk,
	input logic reset_n,
	output logic enable_n
);

	//Define states and type state_t
	typedef enum logic {
		STATE_HIGH,
		STATE_LOW
	} state_t;
	
	state_t current_state, next_state;
	
	//Active High reset
	always_ff @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			current_state <= STATE_HIGH;
		end else begin
			current_state <= next_state;
		end
	end
	
	always_comb begin
		case (current_state)
			STATE_HIGH: next_state = STATE_LOW;
			STATE_LOW: next_state = STATE_HIGH;
			default: next_state = STATE_HIGH;
		endcase
	end
	
	always_comb begin
		case (current_state)
			STATE_HIGH: enable_n = 1'b1;
			STATE_LOW: enable_n = 1'b0;
			default: enable_n = 1'b1;
		endcase
	end
	
endmodule