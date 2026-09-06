//Module for rendering the screen's layout: 10x20 Tiles of 20px by 20px for the play area
module Tile_Renderer(
	input logic [9:0] x_pos, // 800 pixels
	input logic [9:0] y_pos, // 525 pixels
	input logic video_active,
	input logic [3:0] vga_read_data,
	
	input logic [3:0] fsm_write_data, //Color from Game_fsm that represents the chosen piece's color
	input logic [4:0] t0_row, t1_row, t2_row, t3_row, //Takes input from game_fsm to track and draw active piece
	input logic [3:0] t0_col, t1_col, t2_col, t3_col,

	
	output logic [3:0] RedDisplay,
	output logic [3:0] GreenDisplay,
	output logic [3:0] BlueDisplay,
	
	output logic [3:0] vga_col,
	output logic [4:0] vga_row

);


//Initialize variables to represent when the line being rendered is within the playfield and what col/row it is, in the memory grid
logic in_playfield;
logic in_piece;

//Calculate the column and row in the memory grid you're currently traversing, in order to continue outputing stored tile color | Uses truncation 
assign vga_col = (x_pos - 220) / 20; // pixel position - offset from beginning of play area to find column position
assign vga_row = (y_pos - 40) / 20;


//Logic used to determine whether the vga signal is within the designated play area. Outputs 1 when the signal is between horiontal pixel 76 to 256, then vertical pixel 5 to 415 during display lengths
assign in_playfield =  (x_pos >= 220 && x_pos < 420) && (y_pos >= 40 && y_pos < 440); //200x400 pixel play area

//Determine whether the scanner is currently
assign in_piece = ((vga_col == t0_col) & (vga_row == t0_row)) ||
						((vga_col == t1_col) & (vga_row == t1_row)) ||
						((vga_col == t2_col) & (vga_row == t2_row)) ||
						((vga_col == t3_col) & (vga_row == t3_row));

//Color logic
always_comb begin
	if(!video_active) begin // During blanking interval make color outputs black
		RedDisplay = 4'b0000;
		BlueDisplay = 4'b0000;
		GreenDisplay = 4'b0000;
		
	end else if (in_playfield && in_piece) begin //If within the playfield and on active piece, display the color output from FSM choosing the active piece color
		
		case(fsm_write_data)
			4'd1: {RedDisplay, GreenDisplay, BlueDisplay} = 12'h0FF; // Cyan Line Block
			4'd2: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hF0F; // Purple T Block
			4'd3: {RedDisplay, GreenDisplay, BlueDisplay} = 12'h0F0; // Green S Block
			4'd4: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hF00; // Red Z Block
			4'd5: {RedDisplay, GreenDisplay, BlueDisplay} = 12'h00F; // Blue J Block
			4'd6: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hF80; // Orange L Blocks
			4'd7: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hFF0; // Yellow Square Block
			default: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hFFF; //White
		endcase
		
	end else if(in_playfield) begin //If looking at grid memory itself within the playfield, display stored 4 bit colors
	
		case(vga_read_data) //Each case is a 4 bit value that represents a color output for RGB display in memory
			4'd0: {RedDisplay, GreenDisplay, BlueDisplay} = 12'h000; //Black Empty
			4'd1: {RedDisplay, GreenDisplay, BlueDisplay} = 12'h0FF; // Cyan Line Block
			4'd2: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hF0F; // Purple T Block
			4'd3: {RedDisplay, GreenDisplay, BlueDisplay} = 12'h0F0; // Green S Block
			4'd4: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hF00; // Red Z Block
			4'd5: {RedDisplay, GreenDisplay, BlueDisplay} = 12'h00F; // Blue J Block
			4'd6: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hF80; // Orange L Blocks
			4'd7: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hFF0; // Yellow Square Block
			default: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hFFF; //White
		endcase
	
	end else begin	//Color output is dark gray around the play field
		{RedDisplay, GreenDisplay, BlueDisplay} = 12'h222;
	end
	
end

endmodule
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		