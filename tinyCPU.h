//定义指令类型码，高4位
`define LD		4'h1
`define ST		4'h2
`define OPR		4'h3 	//对寄存器操作
`define OPI 	4'h4	//对立即数操作
`define JXX		4'h5    //转移指令，到时候通过功能码区分详细指令
`define HLT		4'hf    //4'hf—>1111，停机指令
`define NOP     4'h0	//0000 空指令

//下面是低四位表示指令功能码

//OPR与ORI功能码定义
`define ADD		4'h0  //加法
`define SUB		4'h1  //减法

//JXX功能码定义
`define JMP		4'h0		//无条件转移
`define BEQ		4'h1		// = 转移
`define BNE		4'h2		// != 转移
`define BLT   	4'h3		//小于转移
`define BGT		4'h4		//大于转移
