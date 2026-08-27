module TopLevel(
	input logic clk,
	input logic reset_n,
	
	output logic Hsync, 
	output logic Vsync,
	output logic [3:0] RedDisplay,
	output logic [3:0] GreenDisplay,
	output logic [3:0] BlueDisplay

);


logic [9:0] x_wire;
logic [9:0] y_wire;
logic va_wire;


VGADriver VGA(
	//Inputs
	.Clock50MHz(clk),
	.reset_n(reset_n),
	
	//Outputs
	.Hsync(Hsync), //Low for 96 lines, then High 704 lines - Hsync Line
	.Vsync(Vsync), //LOW for 2 lines, then High for 523 lines - VSync Line
	.x_pos(x_wire), //into tile renderer
	.y_pos(y_wire),
	.video_active(va_wire)

);

Tile_Renderer TR(
	.x_pos(x_wire), // 800 pixels
	.y_pos(y_wire), // 525 pixels
	.video_active(va_wire),
	
	.RedDisplay(RedDisplay),
	.GreenDisplay(GreenDisplay),
	.BlueDisplay(BlueDisplay)
);


endmodule