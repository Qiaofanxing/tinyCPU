module ROM(
	input wire [7:0] addr,   //8位地址输入
	output wire [23 :0] out   //需要输出一整条指令，需要三个字节24位
);

	reg [7:0] mem [0:255];  //存储单元
	
	assign out = {mem[addr],mem[addr+1],mem[addr+2]};   //连续输出三个字节
	
	initial
		$readmemh("rom.txt",mem,0,255); //利用系统任务读入
	
endmodule