module Grid_Memory(
	input logic clk,
	
	//PORT A - Game FSM
	input logic write_enable,
	input logic [4:0] fsm_row,
	input logic [3:0] fsm_col,
	input logic [3:0] fsm_write_data,
	output logic [3:0] fsm_read_data,
	
	input logic [4:0] vga_row,
	input logic [3:0] vga_col,
	output logic [3:0] vga_read_data

);

endmodule


/*
//Initialize grid that acts like "memory" to store tiles and their colors. 
logic [3:0] grid [0:19][0:9]; //2D Array colxrow 10x20 of 4 bits, (Temporary until grid memory is in FSM)


//Initialize the memory grid with all black tiles
initial begin
	for(int r = 0; r < 20; r++) begin
		for(int c = 0; c < 10; c++) begin
			grid[r][c] = 4'b0000;
		end
	end
	

end

	//Hard coding colored tiles
	assign grid[19][0] = 4'd1; //Cyan
	assign grid[19][1] = 4'd2; //Yellow
	assign grid [10][5] = 4'd3; //Purple //Upside down
	


*/

/*
Steps to take:

Tile Renderer: Remove grid memory and make it so it takes in color values from grid memory and then wrties through the case switch
Figure out what module to calculate vga row and col

Game FSM: Uses Write_enable toggles whether FSM is writing or reading the data. Then 4 bit data is sent into the 2d array or outputted when read


*/