`timescale 10ns/1ns

module little_test;
	reg [7:0] A,B;
	reg [3:0] op;
	wire [7:0] E;
	wire [1:0] cc;
	reg clk;  
	
	ALU alu(.A(A),.B(B),.op(op),.E(E),.cc(cc));
	
	always #5 clk <= ~clk; 
	
	initial begin
		clk = 1'b1;
	#6
		A = 1;
		B = 2;
		op = 0;
	#20
		$finish;
		end
		
	initial begin
		$dumpfile("little_test.vcd");
		$dumpvars(0,alu);
		$dumpvars(0,clk);
		end
endmodule
