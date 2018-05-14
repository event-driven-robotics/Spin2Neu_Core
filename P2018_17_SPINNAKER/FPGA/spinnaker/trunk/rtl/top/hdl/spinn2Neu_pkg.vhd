library ieee;
    use ieee.std_logic_1164.all;
    
    
package SpinnComponents_pkg is

    component spinn_neu_if is
        port (
            rst                          : in  std_logic;
            clk_32                       : in  std_logic;
            -- status interface
            dump_mode                    : out std_logic;
            parity_err                   : out std_logic;
            rx_err                       : out std_logic;
            -- input SpiNNaker link interface
            data_2of7_from_spinnaker     : in  std_logic_vector(6 downto 0);
            ack_to_spinnaker             : out std_logic;
            -- output SpiNNaker link interface
            data_2of7_to_spinnaker       : out std_logic_vector(6 downto 0);
            ack_from_spinnaker           : in  std_logic;
            -- input AER device interface
            iaer_addr                    : in  std_logic_vector(31 downto 0);
            iaer_vld                     : in  std_logic;
            iaer_rdy                     : out std_logic;
            -- output AER device interface
            oaer_addr                    : out std_logic_vector(31 downto 0);
            oaer_vld                     : out std_logic;
            oaer_rdy                     : in  std_logic;
            
            dbg_rxstate                  : out std_logic_vector(2 downto 0);
            dbg_txstate                  : out std_logic_vector(1 downto 0);
            dbg_ipkt_vld                 : out std_logic;
            dbg_ipkt_rdy                 : out std_logic;
            dbg_opkt_vld                 : out std_logic;
            dbg_opkt_rdy                 : out std_logic
        );
    end component spinn_neu_if;

        
    component CoreMonSeqRR is
        generic (
            TestEnableSequencerNoWait            : boolean;
            TestEnableSequencerToMonitorLoopback : boolean;
            EnableMonitorControlsSequencerToo    : boolean
        );
        port (
            Reset_xRBI              : in  std_logic;
            CoreClk_xCI             : in  std_logic;
            --
            FlushFifos_xSI          : in  std_logic;
            --ChipType_xSI            : in  std_logic;
            DmaLength_xDI           : in  std_logic_vector(10 downto 0);
            --
            MonInAddr_xDI           : in  std_logic_vector(31 downto 0);
            MonInSrcRdy_xSI         : in  std_logic;
            MonInDstRdy_xSO         : out std_logic;
            --
            SeqOutAddr_xDO          : out std_logic_vector(31 downto 0);
            SeqOutSrcRdy_xSO        : out std_logic;
            SeqOutDstRdy_xSI        : in  std_logic;
            -- Time stamper         :
            CleanTimer_xSI          : in  std_logic;
            WrapDetected_xSO        : out std_logic;
            --
            EnableMonitor_xSI       : in  std_logic;
            CoreReady_xSI           : in  std_logic;
            --
            FifoCoreDat_xDO         : out std_logic_vector(31 downto 0);
            FifoCoreRead_xSI        : in  std_logic;
            FifoCoreEmpty_xSO       : out std_logic;
            FifoCoreAlmostEmpty_xSO : out std_logic;
            FifoCoreBurstReady_xSO  : out std_logic;
            FifoCoreFull_xSO        : out std_logic;
            --
            CoreFifoDat_xDI         : in  std_logic_vector(31 downto 0);
            CoreFifoWrite_xSI       : in  std_logic;
            CoreFifoFull_xSO        : out std_logic;
            CoreFifoAlmostFull_xSO  : out std_logic;
            CoreFifoEmpty_xSO       : out std_logic
            --
        );
    end component CoreMonSeqRR;
    
        
    component spinn_axilite_if is
        generic (
            C_DATA_WIDTH : integer range 16 to 32 := 32;            -- works only when  C_DATA_WIDTH = 32 !!!
            C_ADDR_WIDTH : integer range  5 to 32;
            C_SLV_DWIDTH : integer                := 32             -- works only when  C_SLV_DWIDTH = 32 !!!
        );
        port (
            -- ADD USER PORTS BELOW THIS LINE ------------------

            -- Loopback default values (set by external pin)
            LpbkDefault_i                  : in  std_logic_vector(2 downto 0);
        
            -- Interrupt
            -------------------------
            InterruptLine_o                : out std_logic;

            -- RX Buffer Reg
            -------------------------
            ReadRxBuffer_o                 : out std_logic;
            RxDataBuffer_i                 : in  std_logic_vector(31 downto 0);
            RxTimeBuffer_i                 : in  std_logic_vector(31 downto 0);
            -- Tx Buffer Reg
            -------------------------
            WriteTxBuffer_o                : out std_logic;
            TxDataBuffer_o                 : out std_logic_vector(31 downto 0);


            -- Controls
            -------------------------
            EnableDmaIf_o                  : out std_logic;
            RearmDma_o                     : out std_logic;
            DmaLength_o                    : out std_logic_vector(10 downto 0);

            CleanTimer_o                   : out std_logic;
            FlushFifos_o                   : out std_logic;

            -- Configurations
            -------------------------
            RemoteLoopback_o               : out std_logic;
            LocalLoopback_o                : out std_logic;
            LocFarLoopback_o               : out std_logic;
            --EnableIp_o                     : out std_logic;
            
            -- Status
            -------------------------
            WrapDetected_i                 : in  std_logic;
            TxDumpMode_i                   : in  std_logic;
            RxParityErr_i                  : in  std_logic;
            RxModemErr_i                   : in  std_logic;
            RxBufferReady_i                : in  std_logic;
            TxBufferFull_i                 : in  std_logic;
            TxBufferAlmostFull_i           : in  std_logic;
            TxBufferEmpty_i                : in  std_logic;
            RxBufferFull_i                 : in  std_logic;
            RxBufferAlmostEmpty_i          : in  std_logic;
            RxBufferEmpty_i                : in  std_logic;


            -- ADD USER PORTS ABOVE THIS LINE ------------------

            -- DO NOT EDIT BELOW THIS LINE ---------------------
            -- Bus protocol ports, do not add to or delete
            -- Axi lite I-f
            S_AXI_ACLK                     : in  std_logic;
            S_AXI_ARESETN                  : in  std_logic;
            S_AXI_AWADDR                   : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
            S_AXI_AWVALID                  : in  std_logic;
            S_AXI_WDATA                    : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
            S_AXI_WSTRB                    : in  std_logic_vector(3 downto 0);
            S_AXI_WVALID                   : in  std_logic;
            S_AXI_BREADY                   : in  std_logic;
            S_AXI_ARADDR                   : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
            S_AXI_ARVALID                  : in  std_logic;
            S_AXI_RREADY                   : in  std_logic;
            S_AXI_ARREADY                  : out std_logic;
            S_AXI_RDATA                    : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
            S_AXI_RRESP                    : out std_logic_vector(1 downto 0);
            S_AXI_RVALID                   : out std_logic;
            S_AXI_WREADY                   : out std_logic;
            S_AXI_BRESP                    : out std_logic_vector(1 downto 0);
            S_AXI_BVALID                   : out std_logic;
            S_AXI_AWREADY                  : out std_logic
            -- DO NOT EDIT ABOVE THIS LINE ---------------------
        );
    end component spinn_axilite_if;

        
    component spinn_axistream_if is
        generic (
            C_NUMBER_OF_INPUT_WORDS : natural := 2048
        );
        port (
            Clk                            : in  std_logic;
            nRst                           : in  std_logic;
            --
            EnableAxistreamIf_i            : in  std_logic;
            DmaLength_i                    : in  std_logic_vector(10 downto 0);
            RearmDma_i                     : in  std_logic;
            -- From Fifo to core/dma
            FifoCoreDat_i                  : in  std_logic_vector(31 downto 0);
            FifoCoreRead_o                 : out std_logic;
            FifoCoreEmpty_i                : in  std_logic;
            FifoCoreBurstReady_i           : in  std_logic;
            -- From core/dma to Fifo
            CoreFifoDat_o                  : out std_logic_vector(31 downto 0);
            CoreFifoWrite_o                : out std_logic;
            CoreFifoFull_i                 : in  std_logic;
            -- Axi Stream I/f
            S_AXIS_TREADY                  : out std_logic;
            S_AXIS_TDATA                   : in  std_logic_vector(31 downto 0);
            S_AXIS_TLAST                   : in  std_logic;
            S_AXIS_TVALID                  : in  std_logic;
            M_AXIS_TVALID                  : out std_logic;
            M_AXIS_TDATA                   : out std_logic_vector(31 downto 0);
            M_AXIS_TLAST                   : out std_logic;
            M_AXIS_TREADY                  : in  std_logic
        );
    end component spinn_axistream_if;

end package SpinnComponents_pkg;
