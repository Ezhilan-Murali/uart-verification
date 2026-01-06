\# UART Design and Verification (SystemVerilog)



\## Overview



This project demonstrates the design and functional verification of a \*\*UART (Universal Asynchronous Receiver/Transmitter)\*\* using \*\*SystemVerilog\*\*.



The RTL includes both \*\*UART Transmitter (TX)\*\* and \*\*UART Receiver (RX)\*\* modules and is verified using a \*\*self-checking, class-based verification environment\*\* simulated in \*\*Vivado XSim\*\*.



The verification methodology follows industry-standard concepts such as \*\*Generator, Driver, Monitor, Scoreboard, and Environment\*\*, implemented without UVM.



---



\## Design Details



\- \*\*Top Module:\*\* `top`

\- \*\*Submodules:\*\*

&nbsp; - `uarttx` – UART Transmitter

&nbsp; - `uartrx` – UART Receiver

\- \*\*Protocol:\*\* UART (8-bit data)

\- \*\*Baud Rate:\*\* Parameterized

\- \*\*Reset:\*\* Active-high synchronous reset



\### Supported Features

\- Configurable clock frequency and baud rate

\- Serial data transmission (TX)

\- Serial data reception (RX)

\- `donetx` and `donerx` status flags

\- Internal baud clock generation



---



\## RTL Source  

\*\*Location:\*\* `src/uart.sv`



```systemverilog

module top #(

&nbsp;   parameter clk\_freq  = 1000000,

&nbsp;   parameter baud\_rate = 9600

)(

&nbsp;   input  clk,

&nbsp;   input  rst,

&nbsp;   input  rx,

&nbsp;   input  newd,

&nbsp;   input  \[7:0] dintx,

&nbsp;   output donerx,

&nbsp;   output \[7:0] doutrx,

&nbsp;   output donetx,

&nbsp;   output tx

);



&nbsp;   uarttx #(clk\_freq, baud\_rate) utx (

&nbsp;       clk, rst, newd, dintx, tx, donetx

&nbsp;   );



&nbsp;   uartrx #(clk\_freq, baud\_rate) urx (

&nbsp;       clk, rst, rx, donerx, doutrx

&nbsp;   );



endmodule



