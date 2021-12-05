
module to(input [7:0] num,output reg [7:0] Ten,output reg [7:0] One);
  integer i;
  reg [7:0] ten;
  reg [7:0] num2;
  always@(num)begin
    num2 = num;
    ten = 0;
    for (i=0; i<10 ;i=i+1)begin
      if(num >= 10)begin
        ten = ten + 1;
        num2 = num2 - 10;
      end
    end
    Ten = ten;
    One = num2;
  end
  
endmodule