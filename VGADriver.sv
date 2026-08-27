
//Counting and syncing, but not colors
module VGADriver (
	input logic Clock50MHz,
	input logic reset_n,
	input logic [1:0] RedControl,
	input logic [1:0] GreenControl,
	input logic [1:0] BlueControl,
	
	output logic Hsync, //Low for 96 lines, then High 704 lines. Increment
	output logic Vsync, //LOW for 2 lines, then High for 523 lines
	output logic video_active,
	output logic [9:0] x_pos,
	output logic [9:0] y_pos
	
);
	logic flip;
	

	//Wire between SyncCount and Each RGB Display
	logic Hd;
	logic Vd;
	
	assign video_active = Hd & Vd;
	

FSM F1(
	.clk(Clock50MHz),
	.reset_n(reset_n),
	.enable_n(flip)
);

SyncCount SC(
	.clk(Clock50MHz),
	.reset_n(reset_n),
	.enable_n(flip),
	
	.VDisplay(Vd),
	.HDisplay(Hd),
	.HSync(Hsync),
	.VSync(Vsync),
	
	.x_pos(x_pos),
	.y_pos(y_pos)
);
	
	
	
	
	
/*
	//Wires between Mux and Decoder output
	logic [3:0] RedWire;
	logic [3:0] GreenWire;
	logic [3:0] BlueWire;
	
*/
	
	
	
/*
//Mux and Decoders for each RGB display

//Bluedisplay
Decoder2_4 BlueDecoder(
	.a(BlueControl),
	.y(BlueWire)
);

//s is select line from SyncCount block. d0 is hooked to ground and selected when HD & VD are 
Mux BlueMux(
	.s(Hd & Vd),
	.d1(BlueWire),
	.d0(4'b0000),
	.y(BlueDisplay)
);

//Reddisplay
Decoder2_4 RedDecoder(
	.a(RedControl),
	.y(RedWire)
);

//s is select line from SyncCount block. d0 is hooked to ground and selected when HD & VD are 
Mux RedMux(
	.s(Hd & Vd),
	.d1(RedWire),
	.d0(4'b0000),
	.y(RedDisplay)
);

//GreenDisplay
Decoder2_4 GreenDecoder(
	.a(GreenControl),
	.y(GreenWire)
);

//s is select line from SyncCount block. d0 is hooked to ground and selected when HD & VD are 
Mux GreenMux(
	.s(Hd & Vd),
	.d1(GreenWire),
	.d0(4'b0000),
	.y(GreenDisplay)
);

//Top half of the diagram enable_n and synccount

*/


endmodule
	
