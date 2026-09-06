
module TopLevel(
	input logic clk,
	input logic reset_n,

	input logic btn_left, //Left Button
	input logic btn_right, //Right Button
	input logic btn_drop, //Down Button
	input logic btn_start, //Start Button
	input logic btn_rotate,
	
	output logic Hsync, 
	output logic Vsync,
	output logic [3:0] RedDisplay,
	output logic [3:0] GreenDisplay,
	output logic [3:0] BlueDisplay
	

);


//Connections from VGADriver to Tile_Renderer 
logic [9:0] x_wire;
logic [9:0] y_wire;
logic va_wire;

//Connections from Game_FSM to Tile_Renderer/Grid_Memory
logic [3:0] Active_Piece_Color;
logic [4:0] t0c, t1c, t2c, t3c;
logic [3:0] t0r, t1r, t2r, t3r;

//Connections from Tile_Renderer to Grid_Memory
logic [3:0] v_col;
logic [4:0] v_row;

//Connection from Grid_Memory to Tile_Renderer
logic [3:0] Grid_Memory_Color;

//Connections from Game_FSM to Grid Memory
logic [3:0] x_coordinates;
logic [4:0] y_coordinates;
logic write;

//Connections from Grid Memory to Game_FSM
logic [3:0] Grid_Memory_Read;

VGADriver VGA(
	//Inputs
	.Clock50MHz(clk),
	.reset_n(reset_n),
	
	//Outputs
	.Hsync(Hsync), //Low for 96 lines, then High 704 lines - Hsync Line
	.Vsync(Vsync), //LOW for 2 lines, then High for 523 lines - VSync Line
	.x_pos(x_wire),
	.y_pos(y_wire),
	.video_active(va_wire)

);

Tile_Renderer TR(
	//Inputs
	.x_pos(x_wire), // 800 pixels
	.y_pos(y_wire), // 525 pixels
	.video_active(va_wire),
	.fsm_write_data(Active_Piece_Color), //Color from Game_fsm that represents the chosen piece's color
	.t0_row(t0r), .t1_row(t1r), .t2_row(t2r), .t3_row(t3r), //Active piece tile locations
	.t0_col(t0c), .t1_col(t1c), .t2_col(t2c), .t3_col(t3c),
	.vga_read_data(Grid_Memory_Color),
	
	//Outputs
	.vga_col(v_col),
	.vga_row(v_row),
	.RedDisplay(RedDisplay),
	.GreenDisplay(GreenDisplay),
	.BlueDisplay(BlueDisplay)
);

Game_FSM GF(
	//Input Ports
	.clk(clk), // Master clock
	.reset_n(reset_n), //Reset Button
	.btn_left(left), //Left Button
	.btn_right(right), //Right Button
	.btn_drop(down), //Down Button
	.btn_start(1), //Start Button //Look into states
	.btn_rotate(up),
	.fsm_read_data(Grid_Memory_Read), //FSM_read_data reading from grid memory at x_cord and y_cord
	
	//Output Ports
	.x_cord(x_coordinates), //Current x cord that game_fsm is rendering
	.y_cord(y_coordinates), //Current y cord that game_fsm is rendering
	.fsm_write_data(Active_Piece_Color), //Wire to grid memory and tile renderer | Outputs the 4 bit color of the current block
	.write_enable(write), //Enables the grid_memory to write down the current x_cord and y_cord colors into memory array
	
	.t0_row(t0r), .t1_row(t1r), .t2_row(t2r), .t3_row(t3r), 
	.t0_col(t0c), .t1_col(t1c), .t2_col(t2c), .t3_col(t3c)

);

Grid_Memory GM(
	.clk(clk),
	
	//PORT A - Game FSM
	
	//Inputs
	.write_enable(write),
	.fsm_row(y_coordinates),
	.fsm_col(x_coordinates),
	.fsm_write_data(Active_Piece_Color),
	//Output
	.fsm_read_data(Grid_Memory_Read),
	
	//PORT B - VGA
	
	//Inputs
	.vga_row(v_row),
	.vga_col(v_col),
	//Output
	.vga_read_data(Grid_Memory_Color)
	

);
//Buttons
logic left;
logic right;
logic down;
logic up;
logic start;

Input_Debouncer leftbutton(
	//Inputs
	.clk(clk),
	.rawsignal(btn_left),
	.reset_n(reset_n),
	
	//Outputs
	.press(left)// Flip to high signal 

);


Input_Debouncer rightbutton(
	//Inputs
	.clk(clk),
	.rawsignal(btn_right),
	.reset_n(reset_n),
	
	//Outputs
	.press(right)// Flip to high signal 

);

Input_Debouncer upbutton(
	//Inputs
	.clk(clk),
	.rawsignal(btn_rotate),
	.reset_n(reset_n),
	
	//Outputs
	.press(up)// Flip to high signal 

);

Input_Debouncer downbutton(
	//Inputs
	.clk(clk),
	.rawsignal(btn_drop),
	.reset_n(reset_n),
	
	//Outputs
	.press(down)// Flip to high signal 

);


Input_Debouncer startbutton(
	//Inputs
	.clk(clk),
	.rawsignal(btn_start),
	.reset_n(reset_n),
	
	//Outputs
	.press(start)// Flip to high signal 

);



endmodule