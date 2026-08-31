//Module for rendering the screen's layout: 10x20 Tiles of 20px by 20px for the play area
module Tile_Renderer(
	input logic [9:0] x_pos, // 800 pixels
	input logic [9:0] y_pos, // 525 pixels
	input logic video_active,
	input logic [3:0] vga_read_data,
	
	output logic [3:0] RedDisplay,
	output logic [3:0] GreenDisplay,
	output logic [3:0] BlueDisplay,
	
	output logic [3:0] vga_col,
	output logic [4:0] vga_row

);


//Initialize variables to represent when the line being rendered is within the playfield and what col/row it is, in the memory grid
logic in_playfield;
logic [3:0] col;
logic [4:0] row;

assign vga_col = col;
assign vga_row = row;

//Calculate the column and row in the memory grid you're currently traversing, in order to continue outputing stored tile color | Uses truncation 
assign col = (x_pos - 220) / 20; // pixel position - offset from beginning of play area to find column position
assign row = (y_pos - 40) / 20;

//Logic used to determine whether the vga signal is within the designated play area. Outputs 1 when the signal is between horiontal pixel 76 to 256, then vertical pixel 5 to 415 during display lengths
assign in_playfield =  (x_pos >= 220 && x_pos < 420) && (y_pos >= 40 && y_pos < 440); //200x400 pixel play area

//Color logic
always_comb begin
	if(!video_active) begin // During blanking interval make color outputs black
		RedDisplay = 4'b0000;
		BlueDisplay = 4'b0000;
		GreenDisplay = 4'b0000;
		
	end else if (in_playfield) begin //If within the playfield begin displaying color ouputs based on the block information stored in each array slot
		
		case(vga_read_data) //Each case is a 4 bit value that represents a color output for RGB display
			4'd0: {RedDisplay, GreenDisplay, BlueDisplay} = 12'h000; //Black Empty
			4'd1: {RedDisplay, GreenDisplay, BlueDisplay} = 12'h0FF; // Cyan
			4'd2: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hFF0; // Yellow
			4'd3: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hF0F; //Purple
			default: {RedDisplay, GreenDisplay, BlueDisplay} = 12'hFFF; //White
		endcase
	
	end else begin	//Color output is dark gray around the play field
		{RedDisplay, GreenDisplay, BlueDisplay} = 12'h222;
	end
	
end

endmodule
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		