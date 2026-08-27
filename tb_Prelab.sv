`timescale 1ns / 1ps //?

module testBench_VGADriver();

	//Declare testbench signals Inputs
	logic clk;
	logic reset_n;
	logic enable_n;

	//Outputs
	logic HDisplay; //1 bit signal high during display interval c only (640)
	logic VDisplay;// 1 bit signal high during display interval c only (480)
	logic HSync; // Low for 96 clock cycles and high for 704 cycles
	logic VSync;
	//Instantiate module of VerticalCounter or HorizontalCounter named dut
	SyncCount dut (
		.clk(clk),
		.reset_n(reset_n),
		.enable_n(enable_n),
		.HDisplay(HDisplay),
		.VDisplay(VDisplay),
		.HSync(HSync),
		.VSync(VSync)
	
	);
	
	//Generate a clock (10 ns period is 100 MHZ)
	always #5 clk = ~clk; //?
	
	initial begin
		clk = 0;
		reset_n = 0;
		enable_n = 1;
		
		#20;
		reset_n = 1;
		enable_n = 0;
		repeat(840000) @(posedge clk); //840000 to test vsync (800 count * 2 full cycles * 525 Vsync Pixels), 1600 to test hsync (800 Count * 2 Cycles)
		
		$stop;
	end
	
endmodule
	
	