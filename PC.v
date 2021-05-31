//用于给出指令在指令储存器中的地址
//在时钟信号的上升沿更新，而且需要一个控制信号，在控制信号为0的时候初始化PC寄存器
module PC(
	input wire [7:0] new_pc,  //目标地址，可能是跳转地址或者是下一条指令的地址
	output reg [7:0] pc, //指令地址，输出信号
	input wire clk,  //时钟周期
	input wire rst_  
);
	always @(posedge clk or negedge rst_) 
	begin
		if(rst_==1'b0)
			begin
			pc<=0;
			end
	 	else    //返回指令地址
			begin
			pc<=new_pc;
			end
	end
		
endmodule
