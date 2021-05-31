module ALU(
	input wire [7:0] A,
	input wire [7:0] B,
	input wire [3:0] op,	//功能码，选择运算类型(预留4位，实际1位就行)
	output wire [7:0] E,
	output wire [1:0] cc	//编码两个操作数，左边用于标识AB是否相等，相等的话为1.
							//右边用于标识A是否大于B，1表示A大于B，0表示A小于B

);
	assign E = ( op == 4'h0 )? A+B :
		   		(op == 4'h1) ? A-B : 8'hxx;
		   		
	assign cc =  {A==B,A>B} 	;  //拼接运算符

endmodule

//OP=0000 加法 A+B
//OP=0001 减法 A-B
//否则：不定值，以后扩充运算符
