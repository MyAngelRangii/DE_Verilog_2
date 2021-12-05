
module FSM(sys_clk,rst_n,x,y);
  input sys_clk,rst_n,x;
  output y;
  reg y;//LED输出
  localparam S0=0;
  localparam S1=1;
  localparam S2=2;
  reg state;
  reg next_state; 
  always @ ( posedge sys_clk or posedge rst_n )    
  if( rst_n ) state <= S0 ; 
  else state <= next_state ;
    
  always@( state or x )  
  case( state )
     
   S0 : if( x ) next_state = S1 ; 
	      
   else    next_state = S0 ; 
      
   S1 : if( x ) next_state = S2 ;
           
   else    next_state = S1 ; 
  
   S2 : if( x ) next_state = S0 ;
   else    next_state = S0 ;
   endcase

   
  always@( state or x )    
   case( state )   
       
   S0 :	y = 0;
   S1 : y = 1;
   S2 : y = 2;     
   endcase
   endmodule   
  