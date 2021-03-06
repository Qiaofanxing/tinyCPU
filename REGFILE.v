module REGFILE(
	input wire [2:0] srcA,
	input wire [2:0] srcB,
	output wire [7:0] A,
	output wire [7:0] B,
	input wire [2:0] dstM,   //M端口要写到哪个寄存器的地址
	input wire [2:0] dstE,   //E端口要写到哪个寄存器的地址
	input wire [7:0] M,			
	input wire [7:0] E,
	input wire clk	
);

	reg [7:0] rf [0:7];

//读电路：
	assign A = (srcA==3'b000)? 8'h00 : rf[srcA];  //如果srcA是0必须返回一个零值(寄存器的地址是R0的地址，取出一个0值)
	assign B = (srcB==3'o0)? 8'h00 : rf[srcB]; //同上
	
//写操作：
	always @(posedge clk) 
    begin
		if(dstM!=3'o0) //寄存器地址不能为0(不能往R0里面写)
            rf[dstM] <= M;					
		if(dstE!=3'o0 && dstE!=dstM)  //如果两个地址是同一个地址，需要有一个优先级(POP指令会涉及)，令M端口优先(栈顶的值存入EXP中)
            rf[dstE] <= E;		
	end
endmodule
