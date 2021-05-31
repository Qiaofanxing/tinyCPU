module RAM(
	input wire [7:0] addr,   //地址总线
	input wire [7:0] in,  //数据总线
	output wire [7:0] out,   //数据输出
	input wire rd_, //控制读信号(低电平有效)
	input wire wr_, //控制写信号(低电平有效)
	input wire clk
);
	reg [7:0] mem [0:255];   //存储单元，共256个，每一个8位
		
	assign out = (rd_==1'b0)? mem[addr] : 8'hxx;	//读数据

	always @(posedge clk) 
		if(wr_==1'b0)  //写信号有效时写入数据
			mem[addr] <= in;  //线网型尽可能连续赋值

endmodule