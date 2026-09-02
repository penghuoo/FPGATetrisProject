module Game_FSM(
	input logic clk,
	input logic reset_n,
	input logic btn_left,
	input logic btn_right,
	input logic btn_drop,
	input logic btn_start,
	input logic fsm_read_data,
	
	output logic [3:0] x_cord,
	output logic [4:0] y_cord,
	output logic fsm_write_data,
	output logic write_enable

);

	typedef enum logic {
		STATE_IDLE,
		STATE_SPAWN,
		STATE_FALL,
		STATE_LOCK,
		STATE_CLEAR
	} state_t;
	
	state_t current_state, next_state;
	
	logic [2:0] count1;
	logic compare1;
//Randomizer to choose block that runs continuously in the background
Counter C1 #(.N(3))(
	.clock(clk),
	.clear_n(~compare1),
	.addBy(3'd1),
	.enable_n(3'b0),
	.reset_n(reset_n),
	.count(count1)
);

Comparator #(.N(3), .MAX_VAL(6)) Comp1(
	.check(count1),
	.compare(compare1)
);
	
// Force current_state to IDLE state when reset button is clicked, otherwise go to the next state on each clock cycle | Present State Register
always_ff @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
			current_state <= STATE_IDLE;
	end else begin
			current_state <= next_state;
	end
end


//Track floating piece's location
logic [4:0] active_row;
logic [3:0] active_col;

//Create row and col for each tile for a block
logic [4:0] t0_row, t1_row, t2_row, t3_row;
logic [3:0] t0_col, t1_col, t2_col, t3_col;

assign x_cord = active_col; //?
assign y_cord = active_row; //?

//2 Bit register to determine rotation state
logic [1:0] rotation_state;

//Control flags declared
logic is_spawning;
logic is_falling;
logic [1:0] probe_count;



// Logic that moves the current state to the next state in the FSM. 
	always_comb begin
	//Control flags to signal when the data path should update coordinates
		is_spawning = 0;
      is_falling = 0;
      write_enable = 0;
		
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
			begin
				is_spawning = 1;
				if (fsm_read_data == 4'b0000) begin
					next_state = STATE_FALL;
				end else begin
					next_state = STATE_IDLE;
				end
			end
			
			//START HERE
			STATE_FALL: 
			
			if (t0_row == 19 or t1_row == 19 or t2_row == 19 or t3_row == 19 ) begin
				is_falling == 0;
				next_state = STATE_LOCK;
			end else if (fsm_read_data != 4'b0000) begin
				next_state = STATE_LOCK;
				probe_counter = 0;
			end else begin
				next_state = STATE_FALL;
			end
			
			

			
			
			
			
			STATE_LOCK: next_state = STATE_CLEAR;
			STATE_CLEAR: next_state = STATE_SPAWN;
			default: next_state = STATE_IDLE;
		endcase
	end

	//Data Path controls how coordinates are changed
always_ff @(posedge clk) begin


	if(!reset_n) begin
		active_row <= 5'd0;
		active_col <= 4'd4;
	end else begin
		if (is_spawning) begin
			active_row <= 5'd0;
			active_col <= 4'd4;
		end else if (is_falling) begin
			
			if () begin //START HERE
			
			
			end else if(btn_down) begin
				active_row <= active_row + 5'd2;
			end else if (btn_left) begin
				active_col <= active_col - 4'd1;
			end else if (btn_right) begin
				active_col <= active_col + 4'd1;
			end else if (btn_rotate) begin
			// 2 bit register to increment how much rotation
				rotation_state <= rotation_state + 2'd1;
			end else begin //Gravity
				active_row <= active_row + 5'd1;
			end	
			
		end
	end
	
	//START HERE
	if(fsm_read_data == 4'b0000) begin
		probe_count <= probe_count + 1;
	end
	

end


//Rotation Logic Finished
always_comb begin
	
	//Prevent Latches using default assignments
	t1_row = active_row; t1_col = active_col;
   t2_row = active_row; t2_col = active_col;
   t3_row = active_row; t3_col = active_col;


	case(piece_type)
	3'd0 : //I Block
		case(rotation_state)
		2'd0:  
			t1_row = active_row; t1_col = active_col - 1;
			t2_row = active_row; t2_col = active_col - 2;
			t3_row = active_row ; t3_col = active_col + 1;
		2'd1:
			t1_row = active_row - 1; t1_col = active_col;
			t2_row = active_row - 2; t2_col = active_col;
			t3_row = active_row + 1; t3_col = active_col;
		2'd2:
			t1_row = active_row; t1_col = active_col + 1;
			t2_row = active_row; t2_col = active_col + 2;
			t3_row = active_row; t3_col = active_col - 1;
		2'd3:
			t1_row = active_row + 1; t1_col = active_col;
			t2_row = active_row + 2; t2_col = active_col;
			t3_row = active_row - 1; t3_col = active_col;
	3'd1 : //TBlock
		case(rotation_state)
		2'd0: //Flat T pointing up rotating clockwise
			t1_row = active_row; t1_col = active_col - 1;
			t2_row = active_row - 1; t2_col = active_col;
			t3_row = active_row ; t3_col = active_col + 1;
		2'd1:
			t1_row = active_row - 1; t1_col = active_col;
			t2_row = active_row; t2_col = active_col + 1;
			t3_row = active_row + 1; t3_col = active_col;
		2'd2:
			t1_row = active_row; t1_col = active_col + 1;
			t2_row = active_row + 1; t2_col = active_col;
			t3_row = active_row; t3_col = active_col - 1;
		2'd3:
			t1_row = active_row + 1; t1_col = active_col;
			t2_row = active_row; t2_col = active_col - 1;
			t3_row = active_row - 1; t3_col = active_col;
	3'd2 : //SBlock
		case(rotation_state)
		2'd0: //S pointing towards the right
			t1_row = active_row; t1_col = active_col - 1;
			t2_row = active_row - 1; t2_col = active_col;
			t3_row = active_row - 1; t3_col = active_col + 1;
		2'd1:
			t1_row = active_row - 1; t1_col = active_col;
			t2_row = active_row; t2_col = active_col + 1;
			t3_row = active_row + 1; t3_col = active_col + 1;
		2'd2:
			t1_row = active_row; t1_col = active_col + 1;
			t2_row = active_row + 1; t2_col = active_col;
			t3_row = active_row + 1; t3_col = active_col - 1;
		2'd3:
			t1_row = active_row + 1; t1_col = active_col;
			t2_row = active_row; t2_col = active_col - 1;
			t3_row = active_row - 1; t3_col = active_col - 1;
	3'd3 : //ZBlock
		case(rotation_state)
		2'd0: //Z pointing to the left
			t1_row = active_row - 1; t1_col = active_col - 1;
			t2_row = active_row - 1; t2_col = active_col;
			t3_row = active_row ; t3_col = active_col + 1;
		2'd1:
			t1_row = active_row - 1; t1_col = active_col + 1;
			t2_row = active_row; t2_col = active_col + 1;
			t3_row = active_row + 1; t3_col = active_col;
		2'd2:
			t1_row = active_row + 1; t1_col = active_col + 1;
			t2_row = active_row + 1; t2_col = active_col;
			t3_row = active_row; t3_col = active_col - 1;
		2'd3:
			t1_row = active_row + 1; t1_col = active_col - 1;
			t2_row = active_row; t2_col = active_col - 1;
			t3_row = active_row - 1; t3_col = active_col;
	3'd4 : //JBlock
		case(rotation_state)
		2'd0:
			t1_row = active_row; t1_col = active_col - 1;
			t2_row = active_row - 1; t2_col = active_col - 1;
			t3_row = active_row ; t3_col = active_col + 1;
		2'd1:
			t1_row = active_row - 1; t1_col = active_col;
			t2_row = active_row - 1; t2_col = active_col + 1;
			t3_row = active_row + 1; t3_col = active_col;
		2'd2:
			t1_row = active_row; t1_col = active_col + 1;
			t2_row = active_row + 1; t2_col = active_col + 1;
			t3_row = active_row; t3_col = active_col - 1;
		2'd3:
			t1_row = active_row + 1; t1_col = active_col;
			t2_row = active_row + 1; t2_col = active_col - 1;
			t3_row = active_row - 1; t3_col = active_col;
	3'd5 : //LBlock
		case(rotation_state):
		2'd0:
			t1_row = active_row; t1_col = active_col - 1;
			t2_row = active_row - 1; t2_col = active_col + 1;
			t3_row = active_row ; t3_col = active_col + 1;
		2'd1:
			t1_row = active_row - 1; t1_col = active_col;
			t2_row = active_row + 1; t2_col = active_col + 1;
			t3_row = active_row + 1; t3_col = active_col;
		2'd2:
			t1_row = active_row; t1_col = active_col + 1;
			t2_row = active_row + 1; t2_col = active_col - 1;
			t3_row = active_row; t3_col = active_col - 1;
		2'd3:
			t1_row = active_row + 1; t1_col = active_col;
			t2_row = active_row - 1; t2_col = active_col - 1;
			t3_row = active_row - 1; t3_col = active_col;

end


//Next task work on how to detect collisions and stateFall from memory grid to game_fsm
//Work on how grid memory and game_fsm communicate information, right now only the anchor is activated


	
	
//Logic that determines what each state does


endmodule