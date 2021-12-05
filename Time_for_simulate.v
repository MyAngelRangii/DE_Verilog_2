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
  reg [7:0] max = 8'd6;
  reg [7:0] max2 = 8'd6;
  localparam TIMER_HW_PASS=8'd9;
  localparam TIMER_HW_WARN=8'd3;
  localparam TIMER_CR_PASS=8'd6;
  wire [7:0] Ten;
  wire [7:0] One;
  localparam DIV_FACTOR = 32'd250000 ;//提了十倍频，加快仿真
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
       else if(max2 - 1 <= count)//注意这里是max2
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
  assign num_for_display = max2 - count;
  
  to u3(.num(num_for_display),.Ten(Ten),.One(One));

  wire [7:0] SEG_L;
  wire [7:0] SEG_H;
  Double_nixietube_by_segments display_gen(.Sys_CLK(Sys_CLK) , .COM(COM), .SEG(SEG), .SEG_H(SEG_L), .SEG_L(SEG_H), .en(1));
  Symbol_to_SEG display1( .symbol(Ten), .dp(1), .SEG(SEG_H) ); 
  Symbol_to_SEG display2( .symbol(One), .dp(0), .SEG(SEG_L) );
  
  reg extend = 0;
  reg completed = 0;
  reg [1:0] usedcount = 0;
  wire [1:0] Key_Out;
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
		case ( max ) //不能用max2，因为按下按钮max2不再与三个常量相匹配
         TIMER_HW_PASS : begin LED <= 4'b0011; if(x) begin max2 <= TIMER_HW_WARN; max <= TIMER_HW_WARN; end else if(extend) begin max2 <= TIMER_HW_WARN + count; max <= TIMER_HW_WARN; usedcount <= usedcount + 1;end end
         TIMER_HW_WARN : begin LED <= 4'b0110; if(x) begin max2 <= TIMER_CR_PASS; max <= TIMER_CR_PASS; end end
         TIMER_CR_PASS : begin LED <= 4'b1001; if(x) begin max2 <= TIMER_HW_PASS; max <= TIMER_HW_PASS; usedcount <= 0;end else if(extend && (usedcount < 2'b11) ) begin max2 <= max2 + 30; usedcount <= usedcount + 1;end end
       endcase
	end
	
	always@(posedge div_clk)begin
		
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



module test();
  
  reg sys_clk = 0;
  reg rst;
  
  always #10 sys_clk = ~sys_clk;
  reg [1:0] Key;
  initial begin
    Key = 0;
    rst = 1;
    #500000
    rst = 0;
    #1000000
    rst = 1;
    #10000000
    Key[0] = 1;
    #30000000//一般手按下Key的保持时间大于div_clk
    Key[0] = 0;
    #10000000
    Key[0] = 1;
    #30000000//
    Key[0] = 0;
    #10000000
    Key[0] = 1;
    #30000000//
    Key[0] = 0;
    #10000000
    Key[0] = 1;
    #30000000//
    Key[0] = 0;
    //加时4次
  end
  Time t1(.Sys_CLK(sys_clk),.Sys_RST(rst),.Key(Key));

endmodule

module test2();
  
  reg sys_clk = 0;
  reg rst;
  
  always #10 sys_clk = ~sys_clk;
  reg [1:0] Key;
  initial begin
    Key = 0;
    rst = 1;
    #500000
    rst = 0;
    #1000000
    rst = 1;
    #60000000//等6个周期到行车状态
    Key[0] = 1;
    #10000000
    Key[0] = 0;
    #10000000
    Key[0] = 1;//警告状态按下按钮
    #30000000//
    Key[0] = 0;
    #10000000
    Key[0] = 1;
    #30000000//
    Key[0] = 0;
    #10000000
    Key[0] = 1;
    #30000000//
    Key[0] = 0;
    #10000000
    Key[0] = 1;
    #30000000//
    Key[0] = 0;
    //加时三次
  end
  Time t1(.Sys_CLK(sys_clk),.Sys_RST(rst),.Key(Key));

endmodule
