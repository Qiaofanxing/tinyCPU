`timescale 10ns/1ns

`include "tinyCPU.h"

`define ins rom_out [23:20]

module test;
	wire [7:0] ram_addr, ram_in ,ram_out, rom_addr;
	wire [23:0] rom_out;
	wire rd_,wr_;
	reg clk,rst_;
	
	parameter CYCLE =1.0;
	
	RAM ram(.addr(ram_addr),.in(ram_in),.out(ram_out),.rd_(rd_),.wr_(wr_),.clk(clk));
	ROM rom(.addr(rom_addr),.out(rom_out));
	
	TINYCPU cpu (.ram_addr(ram_addr),.ram_wdat(ram_in),.ram_rdat(ram_out),.ram_rd_(rd_),.ram_wr_(wr_),
				.rom_addr(rom_addr),.rom_data(rom_out),
				.clk(clk),.rst_(rst_));
				
	always #(CYCLE/2)  clk <= ~clk;  //产生时钟
	
	integer i;

	//每到时钟的下降沿(时钟周期的中间时刻)，把寄存器的值输出一遍:
	always @(negedge clk) begin
//	always @(posedge  clk) begin	
		if (rst_&&(`ins==`HLT)) #(CYCLE+0.1) $finish; //结束当前仿真
		$write("%3d: ",$stime); //显示出仿真时间
		//for(i=0;i<32;i=i+1)
		//	if(ram.mem[i]!==8'hxx) $write(" %c ",ram.mem[i]); 
		//	else $write(" .  ");  //如果是不确定值，输出一个·
		for(i=0;i<=7;i=i+1)
			if(cpu.regfile.rf[i]!==8'hxx) $write(" %d ",cpu.regfile.rf[i]); 
			else $write(" .  ");  //如果是不确定值，输出一个·
		$write("\n"); 
		end
	
	initial begin    
		$dumpfile("test.vcd");
		$dumpvars;
		cpu.regfile.rf[0] = 0;
		cpu.regfile.rf[1] = 1;
		cpu.regfile.rf[2] = 2;
		cpu.regfile.rf[3] = 3;
		cpu.regfile.rf[4] = 4;
		cpu.regfile.rf[5] = 5;
		cpu.regfile.rf[6] = 6;
		cpu.regfile.rf[7] = 8'b11111111;
		$readmemh("ram.txt",ram.mem,0,255);   //16进制
		$readmemh("rom.txt",rom.mem,0,255);   //16进制
		clk=1'b1; 
		rst_=1'b0; #(CYCLE+CYCLE/2) rst_= ~rst_;  //初始reset为0，一个半时钟周期后reset结束
		end

endmodule