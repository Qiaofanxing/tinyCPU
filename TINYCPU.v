`include "tinyCPU.h"

`define ins rom_data[23:20]   	// -> icode (ROM中高四位)
`define fun rom_data[19:16]		// -> ifun (ROM中低四位)，功能码，不需要的地方功能码为0
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

	wire [7:0] valA,valB,valC,valP,valE,valM,aluA,aluB,new_pc;
	wire [1:0] cc;
	wire [2:0] dstE, dstM;
	wire [2:0] val_rA, val_rB;
//取指阶段	
	PC pc( .new_pc(new_pc),.pc(rom_addr),.clk(clk),.rst_(rst_)); //实例化一个PC寄存器

	//valC在其他指令中是第三个字节，在JMP中是第二个字节:
	assign valC = ((`ins==`JXX && `fun==`JMP)||`ins==`CALL)? rom_data[15:8]: rom_data[7:0];  //如果取出来了一个无条件转移指令，输出第二个字节，否则其他的是第三个字节
	//指令大部分为3字节指令,HLT和NOP是单字节，JMP是2字节。HLT为停机指令，不再增加。
	assign valP = rom_addr + ((`ins==`HLT )? 0:
						 (`ins==`NOP||`ins==`RET)? 1: 
						 ((`ins==`JXX && `fun==`JMP)||`ins==`CALL)? 2: 3);  //下一条指令的地址
//译码阶段(从REGFILE中读操作数rA,rB，读出来的值传到valA和valB中)
	assign val_rA = (`ins==`POP)? `rB:
					(`ins==`RET)? 3'o7: `rA;
	assign val_rB = (`ins==`CALL||`ins==`RET)? 3'o7: `rB;
	
	//当`ins==`CALL时，regfile读出寄存器Ra的值赋值给valA,读出寄存器7的值赋值给valB
	//当`ins==`RET时，regfile读出寄存器7的值赋值给valA和valB
	//当`ins==`PUSH时，regfile读出寄存器Ra(操作数，存放进栈数据)的值赋值给valA,读出Rb(当前的栈顶指针)的值赋值给valB
	//当`ins==`POP时，regfile读出寄存器Rb(当前的栈顶指针)的值赋值给valA和valB

	REGFILE regfile(.srcA(val_rA),.srcB(val_rB),.A(valA),.B(valB),.dstM(dstM),.dstE(dstE),.M(valM),.E(valE),.clk(clk)	);  
	//实例化译码器，虽然全部读出来了但是不一定都用(比如JMP就不用rB；比如LD中虽然有rA,rB，但是rB不是源操作数，应该是读出来的值应该写入的内存地址，即destM)，这样可以简化电路
	//源操作数：用rA来选择A寄存器，rB来选择B寄存器
	//输出：A端口输出的信号为valA，B端口输出的信号为valB

//执行阶段
	assign aluA = (`ins==`PUSH||`ins==`POP||`ins==`CALL||`ins==`RET)? valB:valA;
	//如果是堆栈操作相关，传递进去栈顶指针
	assign aluB = (`ins==`LD||`ins==`ST||`ins==`OPI)? valC: 
				  (`ins==`PUSH||`ins==`POP||`ins==`CALL||`ins==`RET)? 8'b00000001: valB;	//第二个操作数为常数(不为valB)的情况传入valC
	//如果为堆栈指令，执行栈顶指针加减1操作，如果是进栈fun为1，执行减一，否则加一
	ALU alu(.A(aluA),.B(aluB),.op(`fun),.E(valE),.cc(cc));   //实例化一个运算器
	//错误的代码(比如转移指令)也会使用ALU并计算出一个错误的结果，但是不会使用到，只有运算指令才会使用到ALU的结果
//访存阶段(读写RAM):
	//只有LD和ST指令需要访存
	assign ram_addr=(`ins==`POP||`ins==`RET)? valA: valE; //地址就是运算器输出的结果	
	assign valM=ram_rdat ;  //从RAM读出来的值写到valM端口
	assign ram_rd_ = (`ins==`LD||`ins==`POP||`ins==`RET)? 1'b0: 1'b1;			//读控信号，LD命令，rd_信号有效
	assign ram_wr_ = (`ins==`ST||`ins==`PUSH||`ins==`CALL)? 1'b0: 1'b1;				//写控信号，ST命令，wr_信号有效 
//写回阶段:
	assign ram_wdat= (`ins==`PUSH)? valA:
					 (`ins==`CALL)? valP: valB;  //如果是写指令(ST)
	assign dstM = (`ins==`LD) ? `rB : 
				  (`ins==`POP)? `rA : 3'o0; //代替写使能信号，不是LD的话全写0，表示不写入寄存器
	assign dstE = (`ins==`OPR)? `rC :
				  (`ins==`OPI) ? `rB :
				  (`ins==`PUSH||`ins==`POP)? `rB:
				  (`ins==`CALL||`ins==`RET)? 3'b111: 3'o0;
				  //其他指令不应该修改寄存器内容		  
//更新PC阶段：
	assign new_pc= (
					(`ins==`CALL)||
					(`ins == `JXX && `fun == `JMP)||
					(`ins == `JXX && `fun == `BEQ &&  cc[1:1])||
					(`ins == `JXX && `fun == `BNE && ~cc[1:1])||
					(`ins == `JXX && `fun == `BLT && ~cc[1:1] && ~cc[0:0])||
					(`ins == `JXX && `fun == `BGT && ~cc[1:1] &&  cc[0:0]))? valC :
					(`ins==`RET)? valM:valP;
					//如果成功转移则为valC,不转移则为下一条指令valP
			
endmodule