`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:23:38 01/04/2022 
// Design Name: 
// Module Name:    top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module top(
		input clk,
		
		output hsync,
		output vsync,
		output r,g,b,
		
		output debugA,debugB,led0,led1,led2,led3,
		input key1,key2,key3,key4,resetkey,
		input uart_rx,
		output uart_tx
		
    );
	 
	 //zegar dla VGA
	 reg pixelClockPresc;
	 always@(posedge clk)pixelClockPresc <= ~pixelClockPresc;
	 
	 //zegar dla procesora i pamieci
	 wire cpuClock;
	 wire cpuClockFast;
	 wire cpuClockSlow;
	 reg cpuClockSelect;
	 clk_prescaler #(.DIVISOR(40000000))  presc_cpuclock (clk, cpuClockSlow);
	 clk_prescaler #(.DIVISOR(2000000))  presc_cpuclockfast (clk, cpuClockFast);
	 wire selectedSpeed;
	 assign selectedSpeed = (cpuClockSelect) ? cpuClockFast : cpuClockSlow ;
	 always@(posedge key1) cpuClockSelect <= ~cpuClockSelect;
	 reg haltClock;
	 always@(posedge key4) haltClock <= ~haltClock;
	 assign cpuClock = (~haltClock) ? selectedSpeed : 0;
	 
	 
	 
	 //szyny procesora
	 wire CPU_RESET;
	 assign CPU_RESET = ~resetkey;
	 wire [7:0] CPU_DATAOUT;
	 wire [7:0] CPU_DATAIN;
	 wire [11:0] CPU_ADRESS;
	 wire CPU_WE;
	 wire CPU_IOBAR;
	 
	 wire MEMORY_WRITE;
	 assign MEMORY_WRITE = ~CPU_IOBAR & CPU_WE;
	 
	 //szyny debug
	 wire [11:0] PC;
	 wire [7:0] acc;
	 wire [7:0] R0;
	 wire [7:0] R1;
	 wire [7:0] R2;
	 wire [7:0] R3;
	 wire carry;
	 wire zero_flag;
	 
	 
	
	 
	 mem2vga memandvga(~cpuClock, CPU_DATAOUT, CPU_DATAIN, CPU_ADRESS, MEMORY_WRITE , pixelClockPresc, hsync, vsync, r, g, b ,
	 PC, R0, R1, R2, R3, acc, zero_flag, carry);
	 
	 PROCESOR s_cpu(.clock(cpuClock) , .reset(CPU_RESET), .we(CPU_WE), .i_obar(CPU_IOBAR) , .datain(CPU_DATAIN) , .dataout(CPU_DATAOUT) , .adress(CPU_ADRESS) ,
	 .PC(PC), .acc(acc), .R0(R0), .R1(R1), .R2(R2), .R3(R3), .zero_flag(zero_flag), .cy_flag(carry) ); 
	 
	 
	 //LED DEBUG
	 assign led0 = cpuClock & ~CPU_RESET;
	 assign led1 = MEMORY_WRITE;
	 assign led2 = CPU_IOBAR;
	 assign led3 = haltClock; // ZATRZYMANE

	 
	 assign debugA = pixelClockPresc;
	 assign debugB = pixelClockPresc;
	 
	 

endmodule
