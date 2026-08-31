module Game_FSM(
	input logic clk,
	input logic reset_n,
	input logic btn_left,
	input logic btn_right,
	input logic btn_drop,
	input logic btn_left,
	input logic btn_start,
	
	output logic x_cord,
	output logic y_cord,
	output logic blockcolor,
	output logic write

);

	typedef enum logic {
		STATE_IDLE,
		STATE_SPAWN,
		STATE_FALL,
		STATE_LOCK,
		STATE_CLEAR
	} state_t
	
	state_t current_state, next_state;
	
// Force current_state to IDLE state when reset button is clicked, otherwise go to the next state on each clock cycle | Present State Register
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
			current_state <= STATE_IDLE;
	end else begin
			current_state <= next_state;
	end
end

// Logic that moves the current state to the next state in the FSM. 
	always_comb begin
		case (current_state)
			//If current state is idle
			STATE_IDLE: 
			
			begin		
				if(btn_start) begin
					next_state = STATE_SPAWN;
				end else begin
					next_state = STATE_IDLE;
				end
			end
			
			//Select piece type, check area to spawn block in, and assign the conditions for the piece to spawn into
			STATE_SPAWN: 
			//Check if area is not occupied to spawn block in
			begin
			if ()
			next_state = STATE_FALL;
			
			
			
			
			STATE_FALL: next_state = STATE_LOCK;
			STATE_LOCK: next_state = STATE_CLEAR;
			STATE_CLEAR: next_state = STATE_SPAWN;
			default: next_state = STATE_IDLE;
		endcase
	end

//Logic that determines what each state does


endmodule