// ------------------------------------------------------------------------------ 
//  Project Name        : 
//  Design Name         : 
//  Starting date:      : 
//  Target Devices      : 
//  Tool versions       : 
//  Project Description : 
// ------------------------------------------------------------------------------
//  Company             : IIT - Italian Institute of Technology  
//  Engineer            : Maurizio Casti
// ------------------------------------------------------------------------------ 
// ==============================================================================
//  PRESENT REVISION
// ==============================================================================
//  File        : spinn_neu_if_tb.v
//  Revision    : 1.0
//  Author      : M. Casti
//  Date        : 
// ------------------------------------------------------------------------------
//  Description : Test Bench for "spinn_neu_if" interface (SpiNNlink-AER)
//     
// ==============================================================================
//  Revision history :
// ==============================================================================
// 
//  Revision 1.0:  07/16/2018
//  - Initial revision
//  (M. Casti - IIT)
// 
// ------------------------------------------------------------------------------

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//---------------------- spinn_neu_if_tb -----------------------
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
`timescale 1ns / 1ps
module spinn_neu_if_tb ();

//---------------------------------------------------------------
// constants
//---------------------------------------------------------------
localparam CLK_HPER  = (31.25 / 2);

// debouncer constants
localparam DBNCER_CONST = 20'h000ff;
localparam RST_DELAY    = (35 * DBNCER_CONST);
localparam INIT_DELAY   = (10 * CLK_HPER);


//---------------------------------------------------------------
// internal signals
//---------------------------------------------------------------
reg         nreset;
wire        reset;
reg         rst_tb;
reg         clk;

wire  [6:0] data_2of7_from_spinnaker;
wire        ack_to_spinnaker;

wire  [6:0] data_2of7_to_spinnaker;
wire        ack_from_spinnaker;

wire [31:0] data_from_device;
wire        vld_from_device;
wire        rdy_to_device;

wire [31:0] data_to_device;
wire        vld_to_device;
wire        rdy_from_device;



//--------------------------------------------------
// Unit Under Test: spinn_neu_if
//--------------------------------------------------

spinn_neu_if spinn_neu_if_i
    (
        .rst						(reset),
        .clk_32						(clk),
        
        .dump_mode					(),
        .parity_err  				(),
        .rx_err             		(),

        // input SpiNNaker link interface
        .data_2of7_from_spinnaker	(data_2of7_from_spinnaker),
        .ack_to_spinnaker			(ack_to_spinnaker),

        // output SpiNNaker link interface
        .data_2of7_to_spinnaker		(data_2of7_to_spinnaker),
        .ack_from_spinnaker 		(ack_from_spinnaker),

        // input AER device interface
        .iaer_addr					(data_from_device),
        .iaer_vld					(vld_from_device),
        .iaer_rdy					(rdy_to_device),

        // output AER device interface
        .oaer_addr					(data_to_device),
        .oaer_vld					(vld_to_device),
        .oaer_rdy					(rdy_from_device),
        
        .dbg_rxstate				(),
        .dbg_txstate				(),
        .dbg_ipkt_vld				(),
        .dbg_ipkt_rdy				(),
        .dbg_opkt_vld				(),
        .dbg_opkt_rdy				()
        
    );

	
//--------------------------------------------------
// SpiNNaker Emulator
//--------------------------------------------------	

SpiNNaker_Emulator SpiNNaker_Emulator_i
	(
	// SpiNNaker link asynchronous output interface
	.Lout(data_2of7_from_spinnaker),
	.LoutAck(ack_to_spinnaker),
	
	// SpiNNaker link asynchronous input interface
	.Lin(data_2of7_to_spinnaker),
	.LinAck(ack_from_spinnaker),
	
	// Control interface
	.rst(rst_tb)
	);
	
	
//--------------------------------------------------
// Data Flow Emulator
//--------------------------------------------------

Data_Engine Data_Engine_i
	(
	// AER Device asynchronous output interface
	.Dout	(data_from_device),
	.DoutVld	(vld_from_device),
	.DoutRdy	(rdy_to_device),

  // AER Device asynchronous input interface
	.Din		(data_to_device),
	.DinVld	(vld_to_device),
	.DinRdy	(rdy_from_device),
  
  // Control interface
	.clk		(clk),
	.rst		(rst_tb)
  );


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//---------------------------- control --------------------------
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
initial
begin
  nreset = 1'b1;
  rst_tb = 1'b1;

  // wait a few clock cycles before triggering nreset
  # INIT_DELAY
    nreset = 1'b0;

  # RST_DELAY
    nreset = 1'b1;

  # RST_DELAY 
    rst_tb = 1'b0;
end

assign reset = !nreset;

initial
begin
   clk = 1'b0;

  forever
  begin
    # CLK_HPER
      clk = ~clk;
   end
end
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
endmodule
