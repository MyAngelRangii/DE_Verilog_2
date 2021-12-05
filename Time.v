`timescale 1ns/1ns

module Time(Sys_CLK,x,SEG,COM,Key,Switch,Sys_RST,LED
	);
  input Sys_CLK;
  input [1:0] Switch;
  input [1:0] Key;
  output reg x;
  output [7:0] SEG;
  output [1:0] COM;
  output reg [3:0] LED;
  input Sys_RST;
  reg [7:0] max = 8'd66;
  reg [7:0] max2 = 8'd66;
  localparam TIMER_HW_PASS=8'd99;//车通行
  localparam TIMER_HW_WARN=8'd33;//警告
  localparam TIMER_CR_PASS=8'd66;//行人通行
  wire [7:0] Ten;
  wire [7:0] One;
  localparam DIV_FACTOR = 32'd2500000 ;
	reg div_clk = 0 ;			/* Sys_CLK = 50MHz, div_clk = 5kHz */
	reg [ 31:0 ] div_cnt = 32'd0 ;
	reg COM_cnt = 0;				/* toggle count for COM */
	
	/* procedual block to divide the Sys_CLK */
	always @( posedge Sys_CLK ) begin
		if( div_cnt < DIV_FACTOR ) div_cnt <= div_cnt + 32'd1 ;
		else begin
			div_clk <= ~div_clk ;
			div_cnt <= 32'd0 ;
		end
	end
  reg [7:0] count = 0;
  always @(posedge div_clk or negedge Sys_RST)
  begin
       if(~Sys_RST)begin
         count <= 0;
			x<=0;
			end
       else if(max2 - 1 <= count)//注意这里是max2，计满max2-1则置x为1
       begin
         count <= 0;
         x<=0;
       end
     else if(max2 - 2 == count)begin
       count <= count + 1;
       x <= 1;
     end
       else 
       begin
          count <= count + 1;
          x<=0;
       end
  end
  
  wire [7:0] num_for_display;
  assign num_for_display = max2 - count;//将count正计时转为显示倒计时
  
  to u3(.num(num_for_display),.Ten(Ten),.One(One));//拆分倒计时的十位和个位并输出，分别用于数码管显示

  wire [7:0] SEG_L;
  wire [7:0] SEG_H;
  //驱动数码管
  Double_nixietube_by_segments display_gen(.Sys_CLK(Sys_CLK) , .COM(COM), .SEG(SEG), .SEG_H(SEG_L), .SEG_L(SEG_H), .en(1));
  Symbol_to_SEG display1( .symbol(Ten), .dp(1), .SEG(SEG_H) ); //将数字转为数码管驱动符号
  Symbol_to_SEG display2( .symbol(One), .dp(0), .SEG(SEG_L) );//将数字转为数码管驱动符号
  
  reg extend = 0;//用于是否进行按键加时
  reg completed = 0;//是否在当前Key为1时已经加过时，用于处理Key跨越多个时钟的场合
  reg [1:0] usedcount = 0;//加时次数，用于判断是否大于3
  wire [1:0] Key_Out;//按键防抖处理后的信号
  wire Key_CLK;
  Key_debounce instance_name (
    .Sys_CLK(Sys_CLK), 
    .Key_In(Key), 
    .Key_Out(Key_Out), 
    .Div_CLK(Key_CLK)
    );
  
  always@(posedge div_clk or negedge Sys_RST)begin
  
    if(~Sys_RST) begin
		max2 <= TIMER_CR_PASS; max <= TIMER_CR_PASS;usedcount <= 0;
	 end
	 else
		case ( max ) //max相当于FSM的状态，max2相当于加时后的状态，max2用于倒计时计算而max只用于次状态判断
         TIMER_HW_PASS : begin LED <= 4'b0011; if(x) begin max2 <= TIMER_HW_WARN; max <= TIMER_HW_WARN; end else if(extend) begin max2 <= TIMER_HW_WARN + count; max <= TIMER_HW_WARN; usedcount <= usedcount + 1;end end
         TIMER_HW_WARN : begin LED <= 4'b0110; if(x) begin max2 <= TIMER_CR_PASS; max <= TIMER_CR_PASS; end end
         TIMER_CR_PASS : begin LED <= 4'b1001; if(x) begin max2 <= TIMER_HW_PASS; max <= TIMER_HW_PASS; usedcount <= 0;end else if(extend && (usedcount < 2'b11) ) begin max2 <= max2 + 30; usedcount <= usedcount + 1;end end
       endcase
	end
	
	always@(posedge div_clk)begin//处理Key慢脉冲
		
		if(Key[0])begin
			if(~completed)begin
				completed <= 1;
				extend <= 1;
			end
			else begin
				extend <= 0;
			end
		end
		else begin
			completed <= 0;
			extend <= 0;
		end
	end
endmodule