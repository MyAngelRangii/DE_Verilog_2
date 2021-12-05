module Key_debounce ( Sys_CLK, Key_In, Key_Out, Div_CLK );
/* In EELAB's board, the system clock frequecy is 50MHz */
/* The Div_CLK will be 1kHz */
input Sys_CLK ;
input [1:0]Key_In;
output [1:0]Key_Out;
output Div_CLK ;

reg [15:0]Div_Cnt;
reg Div_CLK;

reg [11:0]Key_Temp[1:0];

initial
begin
	Div_CLK = 1'd0;
	Div_Cnt = 16'd0;
end

always@(posedge Sys_CLK)
begin
	if(Div_Cnt == 16'd25000)  // 0.5ms
	begin
		Div_Cnt = 16'd0;
		Div_CLK = ~Div_CLK;
	end
	else
		Div_Cnt = Div_Cnt + 1'd1;
end

always@(posedge Div_CLK)
begin
	Key_Temp[0] <= (Key_Temp[0] << 1) + Key_In[0];
	Key_Temp[1] <= (Key_Temp[1] << 1) + Key_In[1];
end

assign Key_Out[0] = &Key_Temp[0];
assign Key_Out[1] = &Key_Temp[1];

endmodule