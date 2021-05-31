`include "tinyCPU.h"

`define ins rom_data[23:20]   	// -> icode (ROM中高四位)
`define fun rom_data[19:16]		// -> ifun (ROM中低四位)，功能码
`define rA  rom_data[14:12]		//只用3位来表示Ra（一共8个寄存器，3位寻址）
`define rB  rom_data[10:8]    //只用3位
`define rC 	rom_data[6:4]		//第三个字节高四位的低三位用来表示rC

module TINYCPU(
	//连接RAM端口
	output wire [7:0] ram_addr,  //写RAM地址
	output wire [7:0] ram_wdat,  //向RAM写数据总线
	input wire [7:0] ram_rdat,  //读总线
	output wire ram_rd_,ram_wr_,  //控制信号
	
	//连接ROM端口
	output wire [7:0] rom_addr,
	input wire [23:0] rom_data,
	
	//时钟信号与复位信号(CPU复位->PC寄存器置0，从0取出第一条地址)
	input wire clk,rst_
);

	wire [7:0] valA,valB,valC,valP,valE,valM,aluB,new_pc;
	wire [1:0] cc;
	wire [2:0] dstE, dstM;
	
	PC pc( .new_pc(new_pc),.pc(rom_addr),.clk(clk),.rst_(rst_)); //实例化一个PC寄存器
	
	assign valC = (`ins==`JXX && `fun==`JMP) ? rom_data[15:8] : rom_data[7:0];  //如果取出来了一个无条件转移指令，输出第二个字节，否则其他的是第三个字节
	
	assign valP = rom_addr + ((`ins==`HLT )? 0:
						 (`ins==`NOP )? 1: 
						 (`ins==`JXX && `fun==`JMP) ? 2:3);  //下一条指令的地址
	
	REGFILE regfile(.srcA(`rA),.srcB(`rB),.A(valA),.B(valB),.dstM(dstM),.dstE(dstE),.M(valM),.E(valE),.clk(clk)	);  //实例化译码器，虽然全部读出来了但是不一定全都用，这样可以简化电路
	
	assign aluB= (`ins==`LD||`ins==`ST||`ins==`OPI)?valC:valB;			//状态信号
	
	ALU alu(.A(valA),.B(aluB),.op(`fun),.E(valE),.cc(cc));   //实例化一个运算器
	//访存阶段:
	assign ram_addr=valE; //地址就是运算器输出的结果
	assign ram_wdat=valB;  
	assign valM=ram_rdat;  //从RAM读出来的值写到valM端口
	assign ram_rd_ = (`ins==`LD) ? 1'b0 : 1'b1;				//LD命令，rd_信号有效
	assign ram_wr_ = (`ins==`ST) ? 1'b0 : 1'b1;	 
	//写回阶段:
	assign dstM = (`ins==`LD) ? `rB : 3'o0; //代替写使能信号，不是LD的话全写0，表示不写入寄存器
	assign dstE = (`ins==`OPR) ? `rC :
				  (`ins==`OPI) ? `rB : 3'o0;
				  //其他指令不应该修改寄存器内容		  
	assign new_pc= (
					(`ins == `JXX && `fun == `JMP)||
					(`ins == `JXX && `fun == `BEQ &&  cc[1:1])||
					(`ins == `JXX && `fun == `BNE && ~cc[1:1])||
					(`ins == `JXX && `fun == `BLT && ~cc[1:1] && ~cc[0:0])||
					(`ins == `JXX && `fun == `BGT && ~cc[1:1] &&  cc[0:0]))? valC :valP;
					//如果成功转移则为valC,不转移则为下一条指令valP
			
endmodule