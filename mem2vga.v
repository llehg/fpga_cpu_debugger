`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Grzegorz Ulfik
// 
// Design Name: 
// Module Name:    mem2vga 
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
// 640x480
module mem2vga(
		input memoryCLK, //zegar synchroniczny pamieci (aktywne zboczem narastajacym)
		input [7:0] DataIN, // Wejscie danych (zapis do pamieci)
		output reg [7:0] DataOUT, //Wyjscie danych (odczyt z pamieci)
		input [11:0] Adress, // Wybrany adres
		input WE, // Zapis (aktywny stanem wysokim)
		
		input pixelclk,//25,125mhz dla standardu 640x480@60Hz (wiekszosc monitorow przyjmuje z duza tolerancja)
		
		//wyjscia DSUB - VGA
		output hsync,
		output vsync,
		output r,g,b
		
		//dodatkowe debugi (rejestry procesora)

  ,input [11:0] PC
  ,input  [7:0] R0
  ,input  [7:0] R1
  ,input  [7:0] R2
  ,input  [7:0] R3
  ,input  [7:0] acc
  ,input zero_flag
  ,input cy_flag
    );
	 
	 //8x5+1
	 parameter [0:47]font[0:17] = {48'b011100100010100010100010100010100010100010011100,//0
										   48'b001000011000001000001000001000001000001000011100,//1
											48'b011100100010000010000100001000010000100000111110,//2
											48'b111110000010000100001000000100000010100010011100,//3
											48'b000100001100010100100100111110000100000100000000,//4
											48'b111110100000011110000001000001010001001110000000,//5
											48'b001100010000100000111100100010100010011100000000,//6
											48'b111110000010000100001000010000100000100000000000,//7
											48'b011100100010100010011100100010100010011100000000,//8
											48'b011100100010100010011100000010000100011000000000,//9
											48'b011100100010100010111110100010100010000000000000,//A
											48'b111100100010100010111100100010100010111100000000,//B
											48'b011100100010100000100000100000100000100010011100,//C
											48'b111000100100100010100010100010100010100100111000,//D
											48'b111110100000100000111100100000100000111110000000,//E
											48'b111110100000100000111100100000100000100000000000,//F	
											48'b111100100010100010111100100000100000100000000000,//
											48'b111100100010100010111100110000101000100100000000//

											};
											
											
	 
	 reg [7:0]RAM[1024:0];
	 
	 initial begin
		$readmemh("RAM.txt", RAM);
	 end
	 
	 reg [11:0]selected_adress;
	 reg we_bak;
	 always @(posedge memoryCLK)begin
		selected_adress <= Adress;
		we_bak <= WE;
		DataOUT <= RAM[Adress];
		if(WE)RAM[Adress] <= DataIN;
	 end
	 
	 reg [11:0] horizontal;
	 reg [10:0] vertical;
	 wire enable_dac;
	 
	 wire burn;
	 
	 //h, v reg
	 always@(posedge pixelclk)begin
	 horizontal <= horizontal + 1;
	 if(horizontal >= 800)begin
		horizontal <= 0;
		vertical <= vertical + 1;
		if(vertical >= 525)begin
			vertical <= 0;
			end
		end
	 end
	 
	 // h,v sync
	 assign hsync = (horizontal >= 656 && horizontal <= 752) ? 1'b0:1'b1;
	 assign vsync = (vertical >= 490 && vertical <= 492) ? 0:1;
	 assign enable_dac = (horizontal <= 640 && vertical <= 480) ? 1:0; 
	 
	 
	 wire [5:0] line; //480/9 = 53 [ 8 pikseli wysokosci czcionki + 1 odstepu]
	 wire [6:0] char; //640/8 = 80
	 assign line = vertical / 9;
	 assign char = horizontal / 6;
	
	 reg onlyblue;
	 reg onlygreen;
	 reg onlyred;
	 assign r = (~onlyblue & ~onlygreen) ?(burn & enable_dac) :0;
	 assign g = (~onlyblue & ~onlyred) ?(burn & enable_dac) :0;
	 assign b = (~onlygreen & ~onlyred) ? burn & enable_dac :0;
	 
	 reg [4:0] currentChar;
	 wire [6:0] fontSelect;
	 assign fontSelect = (horizontal % 6)+(6*(vertical % 9));
	 
	 reg displayChar;
	 
	 assign burn = font[currentChar][fontSelect] & (fontSelect <= 48) & displayChar ;
	 
	 reg [7:0] bufor;
	 
	 wire [6:0] kolumna;
	 assign kolumna = char / 3;
	 
	 wire [11:0] terazAdres;
	 assign terazAdres = 16 * line + (kolumna-3);
	 
	 wire [11:0]legenda;
	 assign legenda = line * 16;
	 
	 always@(*)begin
	 onlyblue <= 0;
	 onlygreen <= 0;
	 onlyred <= 0;
	 currentChar[4] <= 0; //w sumie niepotrzebny FIX dla literek > F
		if(line <= 48 & kolumna < 19 && kolumna >= 3)begin 
			displayChar <= 1;
			bufor[7:0] <= RAM[terazAdres];
			if(terazAdres == selected_adress && we_bak == 0)onlygreen <= 1;
			if(terazAdres == selected_adress && we_bak)onlyred <= 1;
			if(char % 3 == 1)currentChar <= bufor[7:4];
			if(char % 3 == 2)currentChar <= bufor[3:0];
			if(char % 3 == 0)displayChar <= 0;
		end
		
		else if(line <= 48 & char <= 4 )begin 
			onlyblue <= 1;
			displayChar <= 1;
			bufor <= RAM[terazAdres];
			if(char == 0)displayChar <= 0;
			if(char == 1)currentChar <= 0;
			if(char == 2)currentChar <= legenda[11:8];
			if(char == 3)currentChar <= legenda[7:4];
			if(char == 4)currentChar <= legenda[3:0];

		end
			
			else if (line == 10 || line == 18)begin //PC
			case(char)
				80:begin currentChar <= 18; displayChar <= 1; onlyred <= 1; end
				81:begin currentChar <= 4'hC; displayChar <= 1; onlyred <= 1;end
				90:begin currentChar <= 0; displayChar <= 1;  end
				91:begin currentChar <= PC[11:8]; displayChar <= 1; end
				92:begin currentChar <= PC[7:4]; displayChar <= 1; end
				93:begin currentChar <= PC[3:0]; displayChar <= 1; end
				default:displayChar <= 0;
			endcase
			end
			
			else if (line == 11)begin //Adress
			case(char)
				80:begin currentChar <= 4'hA; displayChar <= 1; onlyred <= 1; end
				81,82:begin currentChar <= 4'hD; displayChar <= 1; onlyred <= 1;end
				
				90:begin currentChar <= 0; displayChar <= 1;  end
				91:begin currentChar <= Adress[11:8]; displayChar <= 1; end
				92:begin currentChar <= Adress[7:4]; displayChar <= 1; end
				93:begin currentChar <= Adress[3:0]; displayChar <= 1; end
				default:displayChar <= 0;
			endcase
			end
			
			else if (line == 12)begin //DataIN
			case(char)
				80:begin currentChar <= 4'hD; displayChar <= 1; onlyred <= 1; end
				81,82:begin currentChar <= 1; displayChar <= 1; onlyred <= 1;;end
				
				88:begin currentChar <= WE; displayChar <= 1; end// WE
				
				90:begin currentChar <= DataIN[7:4]; displayChar <= 1; if(WE)onlyred <= 1; end
				91:begin currentChar <= DataIN[3:0]; displayChar <= 1; if(WE)onlyred <= 1; end
				default:displayChar <= 0;
			endcase
			end
			
			else if (line == 13)begin //DataOUT
			case(char)
				80:begin currentChar <= 4'hD; displayChar <= 1; onlyblue <= 1; end
				81,82:begin currentChar <= 2; displayChar <= 1; onlyblue <= 1;end
				90:begin currentChar <= DataOUT[7:4]; displayChar <= 1; onlyblue <= 0; end
				91:begin currentChar <= DataOUT[3:0]; displayChar <= 1; end
				default:displayChar <= 0;
			endcase
			end
			
		else if (line == 19)begin //ACC
			case(char)
				80:begin currentChar <= 4'hA; displayChar <= 1; onlyred <= 1;end
				81,82:begin currentChar <= 4'hC; displayChar <= 1; onlyred <= 1;end
				90:begin currentChar <= acc[7:4]; displayChar <= 1; end
				91:begin currentChar <= acc[3:0]; displayChar <= 1; end
				default:displayChar <= 0;
			endcase
			end
						else if (line == 20)begin //Adress zamrozony
			case(char)
				80:begin currentChar <= 4'hA; displayChar <= 1; onlyred <= 1; end
				81,82:begin currentChar <= 4'hD; displayChar <= 1; onlyred <= 1;end
				
				90:begin currentChar <= 0; displayChar <= 1;  end
				91:begin currentChar <= selected_adress[11:8]; displayChar <= 1; end
				92:begin currentChar <= selected_adress[7:4]; displayChar <= 1; end
				93:begin currentChar <= selected_adress[3:0]; displayChar <= 1; end
				default:displayChar <= 0;
			endcase
			end
			
		else if (line == 25)begin //R0
			case(char)
				80:begin currentChar <= 17; displayChar <= 1; onlyred <= 1; end
				81:begin currentChar <= 0; displayChar <= 1; onlyred <= 1;end
				90:begin currentChar <= R0[7:4]; displayChar <= 1; onlyblue <= 0; end
				91:begin currentChar <= R0[3:0]; displayChar <= 1; end
				default:displayChar <= 0;
			endcase
			end
		else if (line == 26)begin //R1
			case(char)
				80:begin currentChar <= 17; displayChar <= 1; onlyred <= 1; end
				81:begin currentChar <= 1; displayChar <= 1; onlyred <= 1;end
				90:begin currentChar <= R1[7:4]; displayChar <= 1;  end
				91:begin currentChar <= R1[3:0]; displayChar <= 1; end
				default:displayChar <= 0;
			endcase
			end
		else if (line == 27)begin //R2
			case(char)
				80:begin currentChar <= 17; displayChar <= 1; onlyred <= 1; end
				81:begin currentChar <= 2; displayChar <= 1; onlyred <= 1;end
				90:begin currentChar <= R2[7:4]; displayChar <= 1; onlyblue <= 0; end
				91:begin currentChar <= R2[3:0]; displayChar <= 1; end
				default:displayChar <= 0;
			endcase
			end
		else if (line == 28)begin //R3
			case(char)
				80:begin currentChar <= 17; displayChar <= 1; onlyred <= 1; end
				81:begin currentChar <= 3; displayChar <= 1; onlyred <= 1;end
				90:begin currentChar <= R3[7:4]; displayChar <= 1; onlyblue <= 0; end
				91:begin currentChar <= R3[3:0]; displayChar <= 1; end
				default:displayChar <= 0;
			endcase
			end
			
		else if (line == 29)begin //carry
			case(char)
				80:begin currentChar <= 4'hC;  displayChar <= 1; onlyred <= 1; end
				90:begin currentChar <= cy_flag; displayChar <= 1; end
				
				default:displayChar <= 0;
			endcase
			end
			
			else if (line == 30)begin //zero
			case(char)
				80:begin currentChar <= 0;  displayChar <= 1; onlyred <= 1; end
				90:begin currentChar <= zero_flag; displayChar <= 1; end
				
				default:displayChar <= 0;
			endcase
			end


			
		
		else displayChar <= 0;
	 end
	
	 
	 


endmodule
