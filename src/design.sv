// Code your design here
// Code your design here
///////// Transfer UART


module top#(

parameter clk_freq = 1000000,

parameter baud_rate = 9600

)

  (

input clk,rst,rx,

input newd,

  input [7:0] dintx,

  output donerx,

  output [7:0] doutrx,

  output donetx, tx

);

  //wire uclk;

  uarttx #(clk_freq, baud_rate) utx (clk, rst, newd, dintx, tx, donetx);

  

  uartrx #(clk_freq, baud_rate) urx (clk, rst, rx, donerx, doutrx);

  
endmodule





module uarttx

  #(

parameter clk_freq=1000000,

    parameter baud_rate=9600

)

  (

  input clk, rst, newd,

  input [7:0] tx_data,

  output reg tx, donetx

);

  enum bit [1:0] {ideal=2'b00, start=2'b01, transfer=2'b10, done=2'b11} state;

  //state_type state=ideal;
  

  int countc=0;
  
	reg uclk = 0;
  
  localparam clkcount=(clk_freq/baud_rate); //clk cycles req to send a bit 
  
  
  
  always @(posedge clk) begin

	if(countc < clkcount/2) begin

      	countc<=countc+1;

    end

    else

      begin

        countc<=0;

        uclk<=~uclk;

      end

  end

  

    reg [7:0] temp;

  int count=0;

  

  always @(posedge uclk) begin

    if(rst==1) begin

      state<=ideal;

      //temp<=0;

      //tx_data<=0;

      //count<=0;

      //donetx<=0;

    end

    else

      begin

        case(state)

          ideal:

            begin

              count<=0;

              tx<=1;

              donetx<=0;

              

              if(newd == 1)  begin

      			state<=transfer;

                temp<=tx_data;

                tx<=0;
              end


    

    		  else 

              begin

      			state<=ideal;
              end
              

          end

          

          transfer:

            begin

              if(count<=7) begin

                tx<=temp[count] ;

                count<=count+1;

                state<=transfer;

              end

              else

                begin

                  donetx<=1;

                  state<=ideal;

                  count<=0;

                  tx<=1;

                end

            end

          default: state<=ideal;

        endcase

      end

  end

endmodule



///////////Receiver UART



module uartrx
  #(
parameter clk_freq = 1000000, //MHz
parameter baud_rate = 9600
    )

  (

    input clk, rst, rx,

    output reg donerx, 

    output reg [7:0] rxdata

  );

  localparam clkcount = (clk_freq/baud_rate);

  enum bit [1:0] {ideal=2'b00, start=2'b01} state;

    

  int count=0;
  int countc=0;

  //reg [7:0] dout;
  reg uclk = 0;

   always@(posedge clk)
    begin
      if(countc < clkcount/2)
        countc <= countc + 1;
      else begin
        countc <= 0;
        uclk <= ~uclk;
      end 
    end
  
  

  always @(posedge uclk) begin

    if(rst==1) begin

      donerx<=0;

      rxdata<=0;

      count<=0;

    end

    else

      begin

        case(state)

          ideal:

            begin

              rxdata<=0;

              count<=0;

              donerx<=0;
              

      		  if(rx==1)

              begin

        		state<=ideal;

        		//donerx<=0;

      	 	  end

              else if(rx==0) begin

      			state<=start;

              end

            end

          start:

            begin

              if(count<=7) begin

                rxdata<={rx, rxdata[7:1]};

                count<=count+1;

                //state<=transfer;

              end

              else

                begin

                  count<=0;

                  state<=ideal;

                  donerx<=1;

                end

            end

          default: state<=ideal;

        endcase

      end

  end

endmodule



interface uart_if;

  logic clk;

  logic uclktx;
  logic uclkrx;

  logic rst;

  logic rx;

  logic [7:0] dintx;

  logic newd;

  logic tx;

  logic [7:0] doutrx;

  logic donetx;

  logic donerx;

  

endinterface