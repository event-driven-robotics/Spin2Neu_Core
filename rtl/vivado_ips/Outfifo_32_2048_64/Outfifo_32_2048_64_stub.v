// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4.1 (win64) Build 2117270 Tue Jan 30 15:32:00 MST 2018
// Date        : Fri Jul  6 18:18:50 2018
// Host        : IITICUBWS052 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/Projects/Repository/Spin2Neu_core/rtl/vivado_ips/Outfifo_32_2048_64/Outfifo_32_2048_64_stub.v
// Design      : Outfifo_32_2048_64
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_1,Vivado 2017.4.1" *)
module Outfifo_32_2048_64(rst, wr_clk, rd_clk, din, wr_en, rd_en, dout, full, 
  almost_full, overflow, empty, almost_empty, underflow)
/* synthesis syn_black_box black_box_pad_pin="rst,wr_clk,rd_clk,din[31:0],wr_en,rd_en,dout[63:0],full,almost_full,overflow,empty,almost_empty,underflow" */;
  input rst;
  input wr_clk;
  input rd_clk;
  input [31:0]din;
  input wr_en;
  input rd_en;
  output [63:0]dout;
  output full;
  output almost_full;
  output overflow;
  output empty;
  output almost_empty;
  output underflow;
endmodule
