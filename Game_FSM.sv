module Game_FSM(
	//Input Ports
	input logic clk, // Master clock
	input logic reset_n, //Reset Button
	input logic btn_left, //Left Button
	input logic btn_right, //Right Button
	input logic btn_drop, //Down Button
	input logic btn_start,	//Start Button
	input logic btn_rotate,
	input logic [3:0] fsm_read_data, //FSM_read_data reading from grid memory at x_cord and y_cord
	
	//Output Ports
	output logic [3:0] x_cord, //Current x cord that game_fsm is rendering
	output logic [4:0] y_cord, //Current y cord that game_fsm is rendering
	output logic [3:0] fsm_write_data, //Wire to grid memory and tile renderer | Outputs the 4 bit color of the current block
	output logic write_enable, //Enables the grid_memory to write down the current x_cord and y_cord colors into memory array
	
	output logic [4:0] t0_row, t1_row, t2_row, t3_row, //Outputs the coordinates for active blocks, t0 representing the anchor block
	output logic [3:0] t0_col, t1_col, t2_col, t3_col //Connect to tile renderer

);
	//Define States
	typedef enum logic [2:0]{
		STATE_IDLE,
		STATE_SPAWN,
		STATE_FALL,
		STATE_LOCK,
		STATE_CHECK_NEXT,
		STATE_SCAN_ROW,
		STATE_SHIFT_DOWN,
		STATE_FLUSH_TOP
	} state_t;
	
	state_t current_state, next_state;
	
// Declare 2 bit piece_type and compare1 variable. Stores the piece type from 0 to 6
logic [2:0] piece_type;
logic compare1;
//Randomizer to choose block that runs continuously in the background resets to 1 through 7
Counter #(.N(4), .M(1)) C1(
	.clock(clk),
	.clear_n(~compare1),
	.addBy(3'd1),
	.enable_n(3'b0),
	.reset_n(reset_n),
	.count(piece_type)
);

Comparator #(.N(4), .MAX_VAL(7)) Comp1(
	.check(piece_type),
	.compare(compare1)
);

//Counter to increment once every 50 million clock cycles = 1 second
logic [25:0] gravitytick;
logic gravity;
Counter #(.N(26)) C2(
	.clock(clk),
	.clear_n(~gravity),
	.addBy(26'd1),
	.enable_n(26'b0),
	.reset_n(reset_n),
	.count(gravitytick)
);

Comparator #(.N(26), .MAX_VAL(49999999)) Comp2(
	.check(gravitytick),
	.compare(gravity)
);
	
// Force current_state to IDLE state when reset button is clicked, otherwise go to the next state on each clock cycle | Present State Register
always_ff @(posedge clk or negedge reset_n) begin

//Declare more variables to determine active piece's properties
	if (!reset_n) begin
			current_state <= STATE_IDLE;
	end else begin
			current_state <= next_state;
	end
end





//Variables/Register Declarations
//Track an active piece's anchor block in the "Center"
logic [4:0] active_row;
logic [3:0] active_col;

assign t0_row = active_row;
assign t0_col = active_col;

//2 Bit register to determine rotation state from 0 to 3 (Each incrementing by 90 degrees)
logic [1:0] rotation_state;

//Control flags to determine what state the piece is in (Spawning or falling) to increment location
logic is_spawning;
logic is_falling;

logic [1:0] probe_count; //Variable to increment when probing below the 4 tiles. Allows go through each active tile in a case statement and read whether there's a block below in grid memory

logic signed [5:0] row_check; // Variable used to increment from 19 to 0 from bottom to top of board | Signed to determine when you go outside of board (-1)
logic [3:0] col_check; // Variable used to increment from 0 to 9 through an entire row left to right of board

logic [3:0] fsm_write_read_check; //Stores color value of column above temp_row_check to write in col_check memory grid location
logic signed [5:0] temp_row_check; //Variable to temporarily hold row_check's current value to help shift everything above down
logic read_write; // 2 Bit register for 2 clock cycle switching between reading and writing






// Logic that moves the current state to the next state in the FSM. 
always_comb begin
	//Initialize control flags that signal when the data path should update coordinates
		is_spawning = 0;
      is_falling = 0;
      write_enable = 0;
		fsm_write_data = piece_type; //Select piece_type for color data
		
	//Start with coordinates at anchor block to prevent errors
		x_cord = t0_col;
		y_cord = t0_row;
		
	
	//State Machine
		case (current_state)
			
			STATE_IDLE: //Wait for start button to be pressed before moving to STATE_SPAWN
			begin		
				if(btn_start) begin
					next_state = STATE_SPAWN;
				end else begin
					next_state = STATE_IDLE;
				end
			end
			
			
			STATE_SPAWN: //Check to see if spawn location( row: 0, col: 4 ) contains an empty slot in grid memory, if so enter STATE_FALL, otherwise the top has been reached and reset at STATE_IDLE
			begin
				is_spawning = 1;
				if (fsm_read_data == 4'b0000) begin
					next_state = STATE_FALL;
				end else begin
					next_state = STATE_IDLE;
				end
			end
			
			
			STATE_FALL: //STATE_FALL is when the block is moving down the board. Main collision logic to determine when to lock or continue
			begin
				//4 State clock cycle: Using probe_count to "iterate" through each tile and read the stored color in each slot below to determine whether collision occurs
				//grid[x_cord][y_cord] = fsm_read_data
				case(probe_count)
					2'd0: begin x_cord = t0_col; y_cord = t0_row + 1; end
					2'd1: begin x_cord = t1_col; y_cord = t1_row + 1; end
					2'd2: begin x_cord = t2_col; y_cord = t2_row + 1; end
					2'd3: begin x_cord = t3_col; y_cord = t3_row + 1; end
				endcase
				
				//Collision Logic
				if (t0_row == 19 || t1_row == 19 || t2_row == 19 || t3_row == 19 ) begin //Lock block in place when any of the tiles hit the floor
					next_state = STATE_LOCK;
					is_falling = 0;
				end else if (fsm_read_data != 4'b0000) begin //Lock block when any color is detected below a tile within memory grid
					is_falling = 0;
					next_state = STATE_LOCK; 
				end else begin //Otherwise continue falling
					next_state = STATE_FALL;
				end
			
			end
			 
			STATE_LOCK: //Once the block stops, prepare to lock it and write into memory grid
			begin
			write_enable = 1; // fsm_write_data enabled for grid_memory

				//4 State clock cycle: Using probe_count to "iterate" through and write every tile through the fsm_write_data port, during each clock cycle
				//grid[x_cord][y_cord] <= fsm_write_data
				case(probe_count)
					2'd0: begin x_cord = t0_col; y_cord = t0_row; end //Tile1
					2'd1: begin x_cord = t1_col; y_cord = t1_row; end //Tile2
					2'd2: begin x_cord = t2_col; y_cord = t2_row; end //Tile3
					2'd3: begin x_cord = t3_col; y_cord = t3_row; end //Tile4
				endcase
			
				if (probe_count >= 3) begin //Once probe_count writes all 4 tiles move to STATE_SCAN_ROW
					next_state = STATE_SCAN_ROW;
				end else begin	
					next_state = STATE_LOCK; //Otherwise keep writing tile information until 4 state clock cycle finished
				end
			end
			
			STATE_SCAN_ROW: //State for scanning each row after memory grid is finalized with previous active block
			begin
			//fsm_read_data = grid[col_check][row_check] | Read through grid memory
				x_cord = col_check;
				y_cord = row_check;
			
				if (fsm_read_data == 4'b0000) begin //Whenever fsm_read_data reads black (empty) then move to next state to check next row
					next_state = STATE_CHECK_NEXT;
				end else if (col_check == 9) begin //If full row is iterated through without moving to next row, shift all blocks down
					next_state = STATE_SHIFT_DOWN;
				end else begin
					next_state = STATE_SCAN_ROW; //Continue scanning row otherwise
				end
			end
			
			STATE_CHECK_NEXT://State for checking each row in the board until top is hit
			begin
				write_enable = 0;
			
				if(row_check < 0) begin //If less than the top of the board, go back to spawning a block in
					next_state = STATE_SPAWN;
				end else begin
					next_state = STATE_SCAN_ROW; //Otherwise keep scanning rows
				end
			end
			
			STATE_SHIFT_DOWN: //State to shift down all rows from above | Starts when you clear a full row
			
			//Start at where row_check stops then look above to write the data in temp_row_check and col_check
			//Read grid[col_check][temp_row_check - 1], which stores the block in the row above into fsm_read_data
			//Transfer fsm_read_data to fsm_write_read_data
			//Then finally write fsm_write_read_data to grid[col_check][temp_row_check]
			begin
				case(read_write) //2 state clock cycle for read and write 
					2'd0: begin write_enable = 0; x_cord = col_check; y_cord = temp_row_check - 1; end //Read from tile above 
					2'd1: begin write_enable = 1; x_cord = col_check; y_cord = temp_row_check; fsm_write_data = fsm_write_read_check; end //Write (wire) the tile into memory, shifting it down to current location
				endcase
			

				if(temp_row_check <= 1 && col_check == 9 && read_write == 1) begin //When reaching the 2nd to last row, and after shifting the very last tile in the row, move to flushing the top row with black tiles.
					next_state = STATE_FLUSH_TOP;
				end else begin
					next_state = STATE_SHIFT_DOWN; // Otherwise continue until then
				end
			
			end
			
			STATE_FLUSH_TOP://For when clear is successful and all blocks move down. Make sure to make top row all black to prevent layer duplication
			begin
				x_cord = col_check;
				y_cord = row_check;
			
				write_enable = 1;
				fsm_write_data = 4'b0000;
			
				if(col_check == 9) begin
					next_state = STATE_CHECK_NEXT; // When entire row is filled with black, goes back to CHECK_NEXT, which returns to STATE_SPAWN
				end else begin
					next_state = STATE_FLUSH_TOP; // Continue writing to each block otherwise
				end
			end

			default: begin next_state = STATE_IDLE; end
		endcase
		
	end


	
	
	
	
	
	//Data Path controls how coordinates are changed on each clock cycle
always_ff @(posedge clk) begin
	

	if(!reset_n) begin //Reset coordinates to top of board when reset is hit
		active_row <= 5'd0;
		active_col <= 4'd4;
		read_write <= 0;
	end else begin 
		if (is_spawning) begin //Set to top of board in STATE_SPAWN
			active_row <= 5'd0;
			active_col <= 4'd4;
		end else if (is_falling && probe_count == 3 && fsm_read_data == 4'b0000) begin //Read button input during STATE_FALL and when no block is detected underneath (probe_count && fsm_read_data)
			//Figure out logic when taking into account clock later for gravity
			if(btn_drop) begin
				active_row <= active_row + 5'd2; //Move two squares down
			end else if (btn_left) begin
				active_col <= active_col - 4'd1; //Move left one square
			end else if (btn_right) begin
				active_col <= active_col + 4'd1; //Move right one square
			end else if (btn_rotate) begin
				rotation_state <= rotation_state + 2'd1; //Increment degrees of rotation by 90
			end else if (gravity) begin 
				active_row <= active_row + 5'd1; //Gravity logic
			end	
			
		end
	end
	
	//Logic during STATE_FALL and STATE_LOCK
	//Logic for incrementing probe_count when scanning for collision/tiles beneath active piece and writing each tile into memory
	//Probe_count was used for anything related to each seperate tile's properties
	if(current_state != STATE_FALL && current_state != STATE_LOCK) begin //Reset probe_count to 0 when not fall or lock state
		probe_count <= 0;
	end else if (probe_count >= 3) begin //When probe_count finishes looking at each tile resest back to 0
		probe_count <= 0;
	end else if (current_state == STATE_LOCK) begin //Increment probe_count while writing tiles into memory grid
		probe_count <= probe_count + 1;
	end else if (fsm_read_data == 4'b0000 && current_state == STATE_FALL) begin //Increment probe_count when no color/tile is detected underneath an active tile
		probe_count <= probe_count + 1;
	end else begin //Start off at 0 or other case
		probe_count <= 0;
	end
	
	//read_write logic for reading and writing while shifting blocks down
	if(read_write >= 1) begin //When read_write is 1, writing, reset back to 0 for reading
		read_write <= 0;
	end else if (current_state == STATE_SHIFT_DOWN) begin // If the current state is SHIFT_DOWN, increment read write to go from reading to writing. Additionally store the read data into the fsm_write_read_check wire for writing.
		read_write <= read_write + 1;
		fsm_write_read_check <= fsm_read_data;
	end 
	
	//Logic for manipulating col_check or row_check when scanning rows in grid memory
	//col_check for reading each row, left to right
	//row_check for reading from bottom to top of board
	if(current_state == STATE_SCAN_ROW) begin //During either scan row o increment col_check as you check each tile from left to right
		col_check <= col_check + 1;
	end else if (current_state == STATE_SHIFT_DOWN && read_write == 1) begin //Move to the right as you write
		col_check <= col_check +1;
	end else if (current_state == STATE_FLUSH_TOP) begin //During either FLUSH_TOP increment col_check as you check each tile from left to right and set row to very top 0
		col_check <= col_check + 1;
		row_check <= 0;
	end else if(current_state == STATE_CHECK_NEXT) begin //Move up to the next row when in STATE_CHECK_NEXT and reset col_check to left side of board
		row_check <= row_check - 1;
		col_check <= 0;
	end else if(current_state == STATE_LOCK)begin //At start of STATE_LOCK prepare col and row check at the bottom left of the board, before entering SCAN_ROW state
		col_check <= 0;
		row_check <= 19;
	end 
	
	
	//Logic for manipulating temporary row check variable for shifting tiles down
	if (current_state == STATE_SCAN_ROW && col_check == 9 && fsm_read_data != 4'b0000) begin // When a row is complete (scan state, finished reading entire row with no gaps), set the temporary vairable to same row index
    temp_row_check <= row_check; // Initialize the temporary tracker right before shifting
	end else if (current_state == STATE_SHIFT_DOWN && col_check == 9 && read_write == 1) begin // While shifting all tiles down, move up a row when the specific row is finished, until reaching the top (Logic in state machine)
    temp_row_check <= temp_row_check - 1; // Walk up one row after shifting the entire line
	end
	
end


//Rotation Logic for each block
always_comb begin
	
	//Prevent Latches using default assignments
	t1_row = active_row; t1_col = active_col;
   t2_row = active_row; t2_col = active_col;
   t3_row = active_row; t3_col = active_col;

	//Each piece with each tile calculated relative to the anchor tile (active_col and active_row || t0_col and t0_row)
	case(piece_type)
	4'd1 : begin //I Block
		case(rotation_state)
		2'd0:  begin
			t1_row = active_row; t1_col = active_col - 1;
			t2_row = active_row; t2_col = active_col - 2;
			t3_row = active_row ; t3_col = active_col + 1; end
			
		2'd1: begin
			t1_row = active_row - 1; t1_col = active_col;
			t2_row = active_row - 2; t2_col = active_col;
			t3_row = active_row + 1; t3_col = active_col; end
		2'd2: begin
			t1_row = active_row; t1_col = active_col + 1;
			t2_row = active_row; t2_col = active_col + 2;
			t3_row = active_row; t3_col = active_col - 1; end
		2'd3: begin
			t1_row = active_row + 1; t1_col = active_col;
			t2_row = active_row + 2; t2_col = active_col;
			t3_row = active_row - 1; t3_col = active_col; end
		endcase
	end
	4'd2 : begin//TBlock
		case(rotation_state)
		2'd0: begin //Flat T pointing up rotating clockwise
			t1_row = active_row; t1_col = active_col - 1;
			t2_row = active_row - 1; t2_col = active_col;
			t3_row = active_row ; t3_col = active_col + 1; end
		2'd1: begin
			t1_row = active_row - 1; t1_col = active_col;
			t2_row = active_row; t2_col = active_col + 1;
			t3_row = active_row + 1; t3_col = active_col; end
		2'd2: begin
			t1_row = active_row; t1_col = active_col + 1;
			t2_row = active_row + 1; t2_col = active_col;
			t3_row = active_row; t3_col = active_col - 1; end
		2'd3: begin
			t1_row = active_row + 1; t1_col = active_col;
			t2_row = active_row; t2_col = active_col - 1;
			t3_row = active_row - 1; t3_col = active_col; end
		endcase
	end
	4'd3 : begin //SBlock
		case(rotation_state)
		2'd0: begin //S pointing towards the right
			t1_row = active_row; t1_col = active_col - 1;
			t2_row = active_row - 1; t2_col = active_col;
			t3_row = active_row - 1; t3_col = active_col + 1; end
		2'd1: begin
			t1_row = active_row - 1; t1_col = active_col;
			t2_row = active_row; t2_col = active_col + 1;
			t3_row = active_row + 1; t3_col = active_col + 1; end
		2'd2: begin
			t1_row = active_row; t1_col = active_col + 1;
			t2_row = active_row + 1; t2_col = active_col;
			t3_row = active_row + 1; t3_col = active_col - 1; end
		2'd3: begin
			t1_row = active_row + 1; t1_col = active_col;
			t2_row = active_row; t2_col = active_col - 1;
			t3_row = active_row - 1; t3_col = active_col - 1; end
		endcase
	end
	4'd4 : begin//ZBlock
		case(rotation_state)
		2'd0: begin //Z pointing to the left
			t1_row = active_row - 1; t1_col = active_col - 1;
			t2_row = active_row - 1; t2_col = active_col;
			t3_row = active_row ; t3_col = active_col + 1; end
		2'd1: begin
			t1_row = active_row - 1; t1_col = active_col + 1;
			t2_row = active_row; t2_col = active_col + 1;
			t3_row = active_row + 1; t3_col = active_col; end
		2'd2: begin
			t1_row = active_row + 1; t1_col = active_col + 1;
			t2_row = active_row + 1; t2_col = active_col;
			t3_row = active_row; t3_col = active_col - 1; end
		2'd3: begin
			t1_row = active_row + 1; t1_col = active_col - 1;
			t2_row = active_row; t2_col = active_col - 1;
			t3_row = active_row - 1; t3_col = active_col; end
		endcase
	end
	4'd5 : begin //JBlock
		case(rotation_state)
		2'd0: begin
			t1_row = active_row; t1_col = active_col - 1;
			t2_row = active_row - 1; t2_col = active_col - 1;
			t3_row = active_row ; t3_col = active_col + 1; end
		2'd1: begin
			t1_row = active_row - 1; t1_col = active_col;
			t2_row = active_row - 1; t2_col = active_col + 1;
			t3_row = active_row + 1; t3_col = active_col; end
		2'd2: begin
			t1_row = active_row; t1_col = active_col + 1;
			t2_row = active_row + 1; t2_col = active_col + 1;
			t3_row = active_row; t3_col = active_col - 1; end
		2'd3: begin
			t1_row = active_row + 1; t1_col = active_col;
			t2_row = active_row + 1; t2_col = active_col - 1;
			t3_row = active_row - 1; t3_col = active_col; end
		endcase
	end
	4'd6 : begin //LBlock
		case(rotation_state)
		2'd0: begin
			t1_row = active_row; t1_col = active_col - 1;
			t2_row = active_row - 1; t2_col = active_col + 1;
			t3_row = active_row ; t3_col = active_col + 1; end
		2'd1: begin
			t1_row = active_row - 1; t1_col = active_col;
			t2_row = active_row + 1; t2_col = active_col + 1;
			t3_row = active_row + 1; t3_col = active_col; end
		2'd2: begin
			t1_row = active_row; t1_col = active_col + 1;
			t2_row = active_row + 1; t2_col = active_col - 1;
			t3_row = active_row; t3_col = active_col - 1; end
		2'd3: begin
			t1_row = active_row + 1; t1_col = active_col;
			t2_row = active_row - 1; t2_col = active_col - 1;
			t3_row = active_row - 1; t3_col = active_col; end
		endcase
	end
	endcase

end

endmodule