module Game_FSM(
	//Input Ports
	input logic clk, // Master clock
	input logic reset_n, // Reset Button
	input logic btn_left, // Left Button
	input logic btn_right, // Right Button
	input logic btn_drop, // Down Button
	input logic btn_start,	// Start Button
	input logic btn_rotate, // Rotate Button
	input logic [3:0] fsm_read_data, // FSM_read_data reading from grid memory wherever x_cord and y_cord is pointing at in grid memory
	
	//Output Ports
	output logic [3:0] x_cord, // Current x_cord that game_fsm is rendering
	output logic signed [5:0] y_cord, // Current y_cord that game_fsm is rendering | Signed to match the temp_row_check
	output logic [3:0] fsm_write_data, // Wire for outputting the 4 bit color code of the current block to Grid Memory and Tile Renderer
	output logic write_enable, // Enables the Grid Memory to write down the current x_cord and y_cord colors into memory array
	
	// Outputs the coordinates for active blocks, t0 representing the anchor block for tile renderer
	output logic signed [5:0] t0_row, t1_row, t2_row, t3_row, 
	output logic [3:0] t0_col, t1_col, t2_col, t3_col

);
	// Define States for FSM
	typedef enum logic [3:0]{
		STATE_IDLE,
		STATE_SPAWN,
		STATE_FALL,
		STATE_LOCK,
		STATE_CHECK_NEXT,
		STATE_APPLY_MOVE,
		STATE_CHECK_LATERAL,
		STATE_CHECK_ROTATE,
		STATE_SCAN_ROW,
		STATE_SHIFT_DOWN,
		STATE_FLUSH_TOP
	} state_t;
	
	state_t current_state, next_state; // Initialize state variables
	
// Background processes	
	
	// Section for randomly selecting pieces
	
	logic [2:0] piece_type; // Represents current piece type
	logic [2:0] choose; // Counter variable that ticks in the background to "randomly" select a piece
	logic compare1; // Counter Reset

	// Counter that resets from 1 to 7
	Counter #(.N(3), .M(1)) C1( 
		.clock(clk),
		.clear_n(~compare1),
		.addBy(3'd1),
		.enable_n(3'b0),
		.reset_n(reset_n),
		.count(choose)
	);

	Comparator #(.N(3), .MAX_VAL(7)) Comp1(
		.check(choose),
		.compare(compare1)
	);


	// Section for piece's gravity
	
	logic [25:0] gravitytick; // Counter Variable
	logic gravity; // Flips to high whenever 50 million cycles/1 second passes to signal game's gravity
	// Counter to increment once every 50 million clock cycles = 1 second to drop 1 tile down
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
	if (!reset_n) begin
			current_state <= STATE_IDLE;
	end else begin
			current_state <= next_state;
	end
end



//Variables/Register Declarations

	// Block Tracking
		// Track an active piece's anchor block in the "Center"
		logic signed [5:0] active_row;
		logic [3:0] active_col;

		// Assign t0 to the anchor block
		assign t0_row = active_row;
		assign t0_col = active_col;

	

	// Combinational Flags
		//Control flags to determine whether the block is currently falling or spawning in
		logic is_spawning; //STATE_SPAWN = 1
		logic is_falling; //STATE_FALLING = 1

		
	// Variables for scanning

		// Main board scanning variables
		logic signed [5:0] row_check; // Variable used to increment from 19 to 0 from bottom to top of board | Signed to determine when you go outside of board (-1)
		logic [3:0] col_check; // Variable used to increment from 0 to 9 through an entire row | From the left to the right
		
		// STATE_SHIFT_DOWN variables
		logic [3:0] fsm_write_read_check; //STATE_SHIFT_DOWN: Stores the data read above the current block, in order to shift it down when write_enable = 1
		logic signed [5:0] temp_row_check; //Variable to temporarily hold row_check's current value to help shift everything above down
		logic read_write; // STATE_SHIFT_DOWN: Register for 2 clock cycle switching between reading and writing

		// STATE_CHECK_ROTATE variables
		logic [1:0] future_rotation_state; // Rotation state + 1 | Used to predict the tile locations for next rotation state
		
		// Registers for clock cycles
		logic [1:0] rotate_check; //STATE_CHECK_ROTATE: Register for 3 clock cycle scan for 3 tiles when checking future rotation position
		logic [1:0] side_check; //STATE_CHECK_LATERAL: Register for iterating through 4 tiles when checking left/right sides for movement
		logic [1:0] check_finish; //STATE_LOCK: Register for iterating through 4 tiles when writing into grid memory
		logic [1:0] probe_count; //STATE_FALL: Used to track which tile we're probing under, to see if the block should lock into place

		
		// MISC.
		logic safe_move; //Flags when a safe move after the tiles below the main 4 tiles have been checked
		logic [1:0] rotation_state; //2 Bit register to determine rotation state from 0 to 3 (Each incrementing by 90 degrees)

		// Button Presses
		logic intent_left, intent_right, intent_rotate; // Flag when the user intends to make a movement to apply after checking


// Next State Logic | Logic determining next state based on current state and inputs

	always_comb begin
		// Intialization 
			// Initialize control flags
				is_spawning = 0;
				is_falling = 0;
				write_enable = 0;

				fsm_write_data = piece_type; // Store the piece type into write_data to track active piece's color
				future_rotation_state = rotation_state + 1; // future_rotation_state will always be 1 rotation state ahead for probing
				
			// Start with coordinates at anchor block to prevent errors
				x_cord = t0_col;
				y_cord = t0_row;
				
		
		
		// State Logic
			case (current_state)
				
				STATE_IDLE: // Wait for start button to be pressed before moving to STATE_SPAWN
				begin		
					if(btn_start) begin
						next_state = STATE_SPAWN;
					end else begin
						next_state = STATE_IDLE;
					end
				end
				
			
			
				STATE_SPAWN: // Check to see if spawn location( row: 0, col: 4 ) contains an empty slot in grid memory, if so enter STATE_FALL, otherwise the top has been reached and reset at STATE_IDLE
				begin
					is_spawning = 1;
					fsm_write_data = piece_type;
					if (fsm_read_data == 4'b0000) begin
						next_state = STATE_FALL;
					end else begin
						next_state = STATE_IDLE;
					end
				end
				
				
				
				STATE_CHECK_LATERAL: // Check to see if left or right of the block has a collision
				begin
					 
					 
					 case(side_check) // Iterate through each tile and probe adjacent block to left or right, using the MUX operator
						  2'd0: begin x_cord = intent_left ? t0_col - 1 : t0_col + 1; y_cord = t0_row; end
						  2'd1: begin x_cord = intent_left ? t1_col - 1 : t1_col + 1; y_cord = t1_row; end
						  2'd2: begin x_cord = intent_left ? t2_col - 1 : t2_col + 1; y_cord = t2_row; end
						  2'd3: begin x_cord = intent_left ? t3_col - 1 : t3_col + 1; y_cord = t3_row; end
					 endcase
					 
					 // Evaluate the read data for any collisions
					 if (fsm_read_data != 4'b0000) begin 
						  next_state = STATE_FALL; // Revert to fall state if collision detected
					 end else if (side_check >= 3) begin
						  next_state = STATE_APPLY_MOVE; // Apply move when all blocks have been cleared
					 end else begin
						  next_state = STATE_CHECK_LATERAL; // Repeat state to check all blocks
					 end
				end
				
				STATE_CHECK_ROTATE: // Check to see if rotation is possible w/o clipping
				begin
				
					 // Probe positions for tiles in the next rotation state
					 case(rotate_check) // Iterate through each tile
						  2'd0: begin // Tile 1
								case(piece_type) // Based on the piece type
									3'd1: begin // Line Block
										case(future_rotation_state) // Based on what next rotation state is 
											2'd0: begin y_cord = active_row; x_cord = active_col - 1; end //Example: Checking tile 1 in a line block at 0 degrees of rotation
											2'd1: begin y_cord = active_row - 1; x_cord = active_col; end
											2'd2: begin y_cord = active_row; x_cord = active_col - 1; end
											2'd3: begin y_cord = active_row + 1; x_cord = active_col; end
										endcase
									end
									
									3'd2: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row; x_cord = active_col - 1; end
											2'd1: begin y_cord = active_row - 1; x_cord = active_col; end
											2'd2: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd3: begin y_cord = active_row + 1; x_cord = active_col; end
										endcase
									end
									
									3'd3: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row; x_cord = active_col - 1; end
											2'd1: begin y_cord = active_row - 1; x_cord = active_col; end
											2'd2: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd3: begin y_cord = active_row + 1; x_cord = active_col; end
										endcase
									end
									
									3'd4: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row - 1; x_cord = active_col - 1; end
											2'd1: begin y_cord = active_row - 1; x_cord = active_col; end
											2'd2: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd3: begin y_cord = active_row + 1; x_cord = active_col; end
										endcase
									end
									
									3'd5: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row; x_cord = active_col - 1; end
											2'd1: begin y_cord = active_row - 1; x_cord = active_col; end
											2'd2: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd3: begin y_cord = active_row + 1; x_cord = active_col; end
										endcase
									end
									
									3'd6: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row; x_cord = active_col - 1; end
											2'd1: begin y_cord = active_row - 1; x_cord = active_col; end
											2'd2: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd3: begin y_cord = active_row + 1; x_cord = active_col; end
										endcase
									end
							endcase
						  end
						  
						  
						  2'd1: begin // Tile 2
								case(piece_type)
									3'd1: begin // Line Block
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row; x_cord = active_col - 2; end
											2'd1: begin y_cord = active_row - 2; x_cord = active_col; end
											2'd2: begin y_cord = active_row; x_cord = active_col - 2; end
											2'd3: begin y_cord = active_row + 2; x_cord = active_col; end
										endcase
									end
									
									3'd2: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row - 1; x_cord = active_col; end
											2'd1: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd2: begin y_cord = active_row + 1; x_cord = active_col; end
											2'd3: begin y_cord = active_row; x_cord = active_col - 1; end
										endcase
									end
									
									3'd3: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row - 1; x_cord = active_col; end
											2'd1: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd2: begin y_cord = active_row + 1; x_cord = active_col; end
											2'd3: begin y_cord = active_row; x_cord = active_col - 1; end
										endcase
									end
									
									3'd4: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row - 1; x_cord = active_col; end
											2'd1: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd2: begin y_cord = active_row + 1; x_cord = active_col; end
											2'd3: begin y_cord = active_row; x_cord = active_col - 1; end
										endcase
									end
									
									3'd5: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row - 1; x_cord = active_col - 1; end
											2'd1: begin y_cord = active_row - 1; x_cord = active_col + 1; end
											2'd2: begin y_cord = active_row + 1; x_cord = active_col + 1; end
											2'd3: begin y_cord = active_row + 1; x_cord = active_col - 1; end
										endcase
									end
									
									3'd6: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row - 1; x_cord = active_col + 1; end
											2'd1: begin y_cord = active_row + 1; x_cord = active_col + 1; end
											2'd2: begin y_cord = active_row + 1; x_cord = active_col - 1; end
											2'd3: begin y_cord = active_row - 1; x_cord = active_col; end
										endcase
									end
								endcase
							end
							
						  2'd2: begin // Tile 3
								case(piece_type)
									3'd1: begin // Line Block
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd1: begin y_cord = active_row + 1; x_cord = active_col; end
											2'd2: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd3: begin y_cord = active_row - 1; x_cord = active_col; end
										endcase
									end
									
									3'd2: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd1: begin y_cord = active_row + 1; x_cord = active_col; end
											2'd2: begin y_cord = active_row; x_cord = active_col - 1; end
											2'd3: begin y_cord = active_row - 1; x_cord = active_col; end
										endcase
									end
									
									3'd3: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row - 1; x_cord = active_col + 1; end
											2'd1: begin y_cord = active_row + 1; x_cord = active_col + 1; end
											2'd2: begin y_cord = active_row + 1; x_cord = active_col - 1; end
											2'd3: begin y_cord = active_row - 1; x_cord = active_col - 1; end
										endcase
									end
									
									3'd4: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd1: begin y_cord = active_row + 1; x_cord = active_col; end
											2'd2: begin y_cord = active_row; x_cord = active_col - 1; end
											2'd3: begin y_cord = active_row - 1; x_cord = active_col; end
										endcase
									end
									
									3'd5: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd1: begin y_cord = active_row + 1; x_cord = active_col; end
											2'd2: begin y_cord = active_row; x_cord = active_col - 1; end
											2'd3: begin y_cord = active_row - 1; x_cord = active_col; end
										endcase
									end
									
									3'd6: begin
										case(future_rotation_state) 
											2'd0: begin y_cord = active_row; x_cord = active_col + 1; end
											2'd1: begin y_cord = active_row + 1; x_cord = active_col; end
											2'd2: begin y_cord = active_row; x_cord = active_col - 1; end
											2'd3: begin y_cord = active_row - 1; x_cord = active_col; end
										endcase
									end
									
									endcase
							end
					 endcase
					 
					 // Evaluate the read data for any collisions
					 if (fsm_read_data != 4'b0000) begin 
						  next_state = STATE_FALL; // Revert to fall state if collision detected
					 end else if (rotate_check >= 2) begin
						  next_state = STATE_APPLY_MOVE; // Apply move when all blocks have been cleared
					 end else begin
						  next_state = STATE_CHECK_ROTATE; // Repeat state to check all blocks
					 end
				end

				
				STATE_APPLY_MOVE: // Apply the next move if collision isn't detected
				begin
					 next_state = STATE_FALL; // Return back to falling
				end
				 
				STATE_FALL: // STATE_FALL is when the block is moving down the board. Main collision logic to determine when to lock or continue
				begin
					// 4 State clock cycle: Using probe_count to "iterate" through each tile and read the stored color in each slot below to determine whether collision occurs
					// grid[x_cord][y_cord] = fsm_read_data
					case(probe_count)
						2'd0: begin x_cord = t0_col; y_cord = t0_row + 1; end
						2'd1: begin x_cord = t1_col; y_cord = t1_row + 1; end
						2'd2: begin x_cord = t2_col; y_cord = t2_row + 1; end
						2'd3: begin x_cord = t3_col; y_cord = t3_row + 1; end
					endcase
					
					is_falling = 1;
					
					//Collision Detection Logic
					if (btn_left && t0_col > 0 && t1_col > 0 && t2_col > 0 && t3_col > 0) begin 
						 next_state = STATE_CHECK_LATERAL;
					end else if (btn_right && t0_col < 9 && t1_col < 9 && t2_col < 9 && t3_col < 9) begin
						 next_state = STATE_CHECK_LATERAL;
					end else if (btn_rotate && piece_type == 1 && t0_col < 9 && t0_col > 1) begin //Line piece specific rotation condition
						 next_state = STATE_CHECK_ROTATE;
					end else if (btn_rotate && t0_col < 9 && t0_col > 0 && piece_type != 1) begin
						 next_state = STATE_CHECK_ROTATE; 
					end else if (t0_row == 19 || t1_row == 19 || t2_row == 19 || t3_row == 19 ) begin // Lock block in place when any of the tiles hit the floor
						is_falling = 0;
						next_state = STATE_LOCK;
					end else if (fsm_read_data != 4'b0000) begin // Lock block when any color is detected below a tile within memory grid
						is_falling = 0;
						next_state = STATE_LOCK; 
					end else begin 
						next_state = STATE_FALL; // Otherwise continue falling
					end
				
				end
				 
				STATE_LOCK: //Once the block stops, prepare to lock it and write into memory grid
				begin
				write_enable = 1; // fsm_write_data enabled for grid_memory

					//4 State clock cycle: Using probe_count to "iterate" through and write every tile through the fsm_write_data port, during each clock cycle
					//grid[x_cord][y_cord] <= fsm_write_data
					case(check_finish)
						2'd0: begin x_cord = t0_col; y_cord = t0_row; end //Tile1
						2'd1: begin x_cord = t1_col; y_cord = t1_row; end //Tile2
						2'd2: begin x_cord = t2_col; y_cord = t2_row; end //Tile3
						2'd3: begin x_cord = t3_col; y_cord = t3_row; end //Tile4
					endcase
				
					if (check_finish >= 3) begin // Once check_finish writes all 4 tiles move to STATE_SCAN_ROW
						next_state = STATE_SCAN_ROW;
					end else begin	
						next_state = STATE_LOCK; // Otherwise keep writing tile information until 4 state clock cycle finished
					end
				end
				
				STATE_SCAN_ROW: // State for scanning each row after memory grid is finalized with previous active block
				begin
				// fsm_read_data = grid[col_check][row_check] | Read through grid memory
					x_cord = col_check;
					y_cord = row_check;
				
					if (fsm_read_data == 4'b0000) begin // Whenever fsm_read_data reads black (empty) then move to next state to check next row
						next_state = STATE_CHECK_NEXT;
					end else if (col_check == 9) begin // If full row is iterated through, without moving to next row, shift all blocks down
						next_state = STATE_SHIFT_DOWN;
					end else begin
						next_state = STATE_SCAN_ROW; // Continue scanning row otherwise
					end
				end
				
				STATE_CHECK_NEXT:// State for checking each row in the board until top is hit
				begin
					write_enable = 0;
				
					if(row_check < 0) begin // If less than the top of the board, go back to spawning a block in
						next_state = STATE_SPAWN;
					end else begin
						next_state = STATE_SCAN_ROW; // Otherwise keep scanning rows
					end
				end
				
				STATE_SHIFT_DOWN: // State to shift down all rows from above | Starts when you clear a full row
				
				// Start at where row_check stops then look above to write the data in temp_row_check and col_check
				// Read grid[col_check][temp_row_check - 1], which stores the block in the row above into fsm_read_data
				// Transfer fsm_read_data to fsm_write_read_data
				// Then finally write fsm_write_read_data to grid[col_check][temp_row_check]
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
				
				STATE_FLUSH_TOP:// For when clear is successful and all blocks move down. Make sure to make top row all black to prevent layer duplication
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


	


// Data Path controls how coordinates are changed on each clock cycle
	always_ff @(posedge clk) begin
	
		// Intialization of variables when reset or spawning
			if(!reset_n) begin //Reset coordinates to top of board when reset is hit
				active_row <= 5'd2;
				active_col <= 4'd4;
				rotation_state <= 0;
				read_write <= 0;
				safe_move <= 0;
			end else begin 
				if (is_spawning) begin // Set to top of board in STATE_SPAWN
					active_row <= 5'd2;
					active_col <= 4'd4;
					rotation_state <= 0;
					read_write <= 0;
					safe_move <= 0;
					piece_type <= choose;
				end else if (safe_move) begin
					if(btn_drop) begin
						active_row <= active_row + 5'd1; // Move down when no collision is detected
						safe_move <= 0;
					end else if (gravity) begin 
						active_row <= active_row + 5'd1; // Gravity logic
						safe_move <= 0;
					end	
				end
			end 
			
		// Safe move is possible when piece is in freefall and no blocks are detected underneath
			if (is_falling && probe_count == 3 && fsm_read_data == 4'b0000) begin
				safe_move <= 1;
			end
		
		//State Clock Cycles
		
			// STATE_LOCK: 4 State Clock Cycle Logic for writing/reading tiles
				if (current_state != STATE_LOCK) begin 
					check_finish <= 0;
				end else if(check_finish >= 3) begin
					check_finish <= 0;
				end else begin
					check_finish <= check_finish + 1;
				end
				
			// STATE_FALL: 4 State Clock Cycle Logic for detecting bottom collision
			if(current_state != STATE_FALL) begin //Reset probe_count to 0 when not fall or lock state
				probe_count <= 0;
			end else if (probe_count >= 3) begin //When probe_count finishes looking at each tile resest back to 0
				probe_count <= 0;
			end else if (fsm_read_data == 4'b0000 && current_state == STATE_FALL) begin //Increment probe_count when no color/tile is detected underneath an active tile
				probe_count <= probe_count + 1;
			end
					//Logic for incrementing probe_count when scanning for collision/tiles beneath active piece and writing each tile into memory

			// STATE_CHECK_LATERAL: 4 State Clock Cycle Logic for detecting side collisions
			if(current_state != STATE_CHECK_LATERAL) begin
				side_check <= 0;
			end else if (side_check >= 3) begin
				side_check <= 0;
			end else if (current_state == STATE_CHECK_LATERAL) begin
				side_check <= side_check + 1;
			end
			
			// STATE_CHECK_ROTATE: 3 State Clock Cycle Logic for checking future rotation state
			if(current_state != STATE_CHECK_ROTATE) begin
				rotate_check <= 0;
			end else if (rotate_check >= 2) begin
				rotate_check <= 0;
			end else if (current_state == STATE_CHECK_ROTATE) begin
				rotate_check <= rotate_check + 1;
			end


		
		// Button Movement Logic
			if (current_state == STATE_FALL) begin
				// Latch the intent when button is pressed
				if (btn_left) begin 
					intent_left <= 1;
					intent_right <= 0;
				end else if (btn_right) begin
					intent_right <= 1;
					intent_left <= 0;
				end else if (btn_rotate) begin
					intent_rotate <= 1;
				end else begin
					intent_left <= 0;
					intent_right <= 0;
					intent_rotate <= 0;
				end
			end else if (current_state == STATE_APPLY_MOVE) begin
					intent_left <= 0;
					intent_right <= 0;
					intent_rotate <= 0;
			end

			// Execute the move safely during STATE_APPLY_MOVE
			if (current_state == STATE_APPLY_MOVE) begin
				if (intent_left) begin
					active_col <= active_col - 4'd1;
				end
				if (intent_right) begin
					active_col <= active_col + 4'd1;
				end
				if	(intent_rotate) begin
					rotation_state <= rotation_state + 2'd1;
				end
			end
		

		
		// STATE_SHIFT_DOWN shifting logic
		if(read_write >= 1) begin //When read_write is 1, writing, reset back to 0 for reading
			read_write <= 0;
		end else if (current_state == STATE_SHIFT_DOWN && read_write == 0) begin // Once data is read during read_write = 0, begin writing and store the read data into the fsm_write_read_check wire for writing.
			read_write <= read_write + 1;
			fsm_write_read_check <= fsm_read_data;
		end 
		
		// Logic for manipulating col_check or row_check for scanning (STATE_SCAN_ROW, STATE_SHIFT_DOWN, STATE_FLUSH_TOP, STATE_CHECK_NEXT)
		// col_check for reading each row, left to right
		// row_check for reading from bottom to top of board
		if(current_state == STATE_SCAN_ROW) begin // During scan row increment col_check as you check each tile from left to right within a row
			col_check <= col_check + 1;
		end else if (current_state == STATE_SHIFT_DOWN && read_write == 1) begin // Move to the right as you write
			col_check <= col_check + 1;
		end else if (current_state == STATE_FLUSH_TOP && col_check == 9) begin  // Once top row is flushed
			row_check <= 20; //Reset row_check to bottom of the screen and keep scanning to clear reset of lines (20 because it'll decrement when check_next is next state)
		end else if (current_state == STATE_FLUSH_TOP) begin
			col_check <= col_check + 1;
			row_check <= 0;
		end else if(current_state == STATE_CHECK_NEXT) begin //Move up to the next row when in STATE_CHECK_NEXT and reset col_check to left side of board
			row_check <= row_check - 1;
			col_check <= 0;
		end else if(current_state == STATE_LOCK) begin //At start of STATE_LOCK prepare col and row check at the bottom left of the board, before entering SCAN_ROW state
			col_check <= 0;
			row_check <= 19;
		end 
		
		// Logic for manipulating temporary row check variable for shifting tiles down
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
	3'd1 : begin //I Block
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
			t1_row = active_row; t1_col = active_col - 1;
			t2_row = active_row; t2_col = active_col - 2;
			t3_row = active_row ; t3_col = active_col + 1; end
		2'd3: begin
			t1_row = active_row + 1; t1_col = active_col;
			t2_row = active_row + 2; t2_col = active_col;
			t3_row = active_row - 1; t3_col = active_col; end
		endcase
	end
	3'd2 : begin//TBlock
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
	3'd3 : begin //SBlock
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
	3'd4 : begin//ZBlock
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
	3'd5 : begin //JBlock
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
	3'd6 : begin //LBlock
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
	3'd7 : begin
			t1_row = active_row; t1_col = active_col + 1;
			t2_row = active_row + 1; t2_col = active_col;
			t3_row = active_row + 1 ; t3_col = active_col + 1; 
		end
	endcase

end

endmodule