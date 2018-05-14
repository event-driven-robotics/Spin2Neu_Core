

library ieee;
    use ieee.std_logic_1164.all;
    
    
library work;
    use work.SpinnComponents_pkg.all;


entity Spinn2Neu_core is
    generic (
        -- DO NOT EDIT BELOW THIS LINE ---------------------
        -- Bus protocol parameters, do not add to or delete
        C_S_AXI_DATA_WIDTH             : integer              := 32;
        C_S_AXI_ADDR_WIDTH             : integer              := 7;
        C_S_AXI_MIN_SIZE               : std_logic_vector     := X"000001FF";
        C_USE_WSTRB                    : integer              := 1;
        C_DPHASE_TIMEOUT               : integer              := 8;
        C_BASEADDR                     : std_logic_vector     := X"FFFFFFFF";
        C_HIGHADDR                     : std_logic_vector     := X"00000000";
        C_FAMILY                       : string               := "virtex7";
        C_NUM_REG                      : integer              := 24;
        C_NUM_MEM                      : integer              := 1;
        C_SLV_AWIDTH                   : integer              := 32;
        C_SLV_DWIDTH                   : integer              := 32;
        C_DEBUG                        : integer              :=0
        -- DO NOT EDIT ABOVE THIS LINE ---------------------
    );
    port (
        nRst        : in  std_logic;
        Clk_Spinn   : in  std_logic;
        Clk_Core    : in  std_logic;
        
        Interrupt_o : out std_logic;
        
        LpbkDefault_i : in  std_logic_vector(2 downto 0);


        -- input SpiNNaker link interface
        data_2of7_from_spinnaker       : in  std_logic_vector(6 downto 0);
        ack_to_spinnaker               : out std_logic;
        -- output SpiNNaker link interface
        data_2of7_to_spinnaker         : out std_logic_vector(6 downto 0);
        ack_from_spinnaker             : in  std_logic;
        
        -- Debug signals
        dbg_dt_2of7_from_spin : out std_logic_vector(6 downto 0);
        dbg_ack_to_spin       : out std_logic;

        dbg_dt_2of7_to_spin   : out std_logic_vector(6 downto 0);
        dbg_ack_from_spin     : out std_logic;
        
        dbg_txSeqData    : out std_logic_vector(31 downto 0);
        dbg_txSeqSrcRdy  : out std_logic;
        dbg_txSeqDstRdy  : out std_logic;

        dbg_rxMonData    : out std_logic_vector(31 downto 0);
        dbg_rxMonSrcRdy  : out std_logic;
        dbg_rxMonDstRdy  : out std_logic;
        
        dbg_rxstate      : out std_logic_vector(2 downto 0);
        dbg_txstate      : out std_logic_vector(1 downto 0);
        dbg_ipkt_vld     : out std_logic;
        dbg_ipkt_rdy     : out std_logic;
        dbg_opkt_vld     : out std_logic;
        dbg_opkt_rdy     : out std_logic;


        -- ADD USER PORTS ABOVE THIS LINE ------------------

        -- DO NOT EDIT BELOW THIS LINE ---------------------
        -- Bus protocol ports, do not add to or delete
        -- Axi lite I-f
        S_AXI_ACLK                     : in  std_logic;
        S_AXI_ARESETN                  : in  std_logic;
        S_AXI_AWADDR                   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWVALID                  : in  std_logic;
        S_AXI_WDATA                    : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB                    : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        S_AXI_WVALID                   : in  std_logic;
        S_AXI_BREADY                   : in  std_logic;
        S_AXI_ARADDR                   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARVALID                  : in  std_logic;
        S_AXI_RREADY                   : in  std_logic;
        S_AXI_ARREADY                  : out std_logic;
        S_AXI_RDATA                    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP                    : out std_logic_vector(1 downto 0);
        S_AXI_RVALID                   : out std_logic;
        S_AXI_WREADY                   : out std_logic;
        S_AXI_BRESP                    : out std_logic_vector(1 downto 0);
        S_AXI_BVALID                   : out std_logic;
        S_AXI_AWREADY                  : out std_logic;
        -- Axi Stream I/f
        S_AXIS_TREADY                  : out std_logic;
        S_AXIS_TDATA                   : in  std_logic_vector(31 downto 0);
        S_AXIS_TLAST                   : in  std_logic;
        S_AXIS_TVALID                  : in  std_logic;
        M_AXIS_TVALID                  : out std_logic;
        M_AXIS_TDATA                   : out std_logic_vector(31 downto 0);
        M_AXIS_TLAST                   : out std_logic;
        M_AXIS_TREADY                  : in  std_logic
        -- DO NOT EDIT ABOVE THIS LINE ---------------------
    );
    attribute MAX_FANOUT  : string;
    attribute SIGIS       : string;

    attribute MAX_FANOUT of S_AXI_ACLK     : signal is "10000";
    attribute MAX_FANOUT of S_AXI_ARESETN  : signal is "10000";
    attribute SIGIS      of S_AXI_ACLK     : signal is "Clk";
    attribute SIGIS      of S_AXI_ARESETN  : signal is "Rst";
    attribute SIGIS      of Interrupt_o    : signal is "Interrupt";

end entity Spinn2Neu_core;







architecture str of Spinn2Neu_core is

    signal rst              : std_logic;

    signal i_txDumpMode     : std_logic;
    signal i_rxParityErr    : std_logic;
    signal i_rxModemErr     : std_logic;
    signal i_wrapDetected   : std_logic;

    signal i_locFarLoopback : std_logic;
    signal i_localLoopback  : std_logic;
    signal i_remoteLoopback : std_logic;
    signal i_dmaLength      : std_logic_vector(10 downto 0);
    signal i_flushFifos     : std_logic;
    signal i_cleanTimer     : std_logic;
    signal i_enableDmaIf    : std_logic;
    signal i_rearmDma       : std_logic;

    signal i_txSeqData      : std_logic_vector(31 downto 0);
    signal i_txSeqSrcRdy    : std_logic;
    signal i_txSeqDstRdy    : std_logic;
    signal i_rxMonData      : std_logic_vector(31 downto 0);
    signal i_rxMonSrcRdy    : std_logic;
    signal i_rxMonDstRdy    : std_logic;

    signal i_monData        : std_logic_vector(31 downto 0);
    signal i_monSrcRdy      : std_logic;
    signal i_monDstRdy      : std_logic;
    signal i_seqData        : std_logic_vector(31 downto 0);
    signal i_seqSrcRdy      : std_logic;
    signal i_seqDstRdy      : std_logic;


    signal i_dma_readRxBuffer    : std_logic;
    signal i_dma_writeTxBuffer   : std_logic;
    signal i_dma_rxDataBuffer    : std_logic_vector(31 downto 0);
    signal i_dma_txDataBuffer    : std_logic_vector(31 downto 0);
    signal i_dma_rxBufferEmpty   : std_logic;
    signal i_dma_rxBufferReady   : std_logic;
    signal i_dma_txBufferFull    : std_logic;

    signal i_uP_readRxBuffer     : std_logic;
    signal i_uP_writeTxBuffer    : std_logic;
    signal i_uP_rxDataBuffer     : std_logic_vector(31 downto 0);
    signal i_uP_rxTimeBuffer     : std_logic_vector(31 downto 0);
    signal i_uP_txDataBuffer     : std_logic_vector(31 downto 0);

    signal i_uP_rxBufferReady       : std_logic;
    signal i_uP_txBufferFull        : std_logic;
    signal i_uP_txBufferAlmostFull  : std_logic;
    signal i_uP_txBufferEmpty       : std_logic;
    signal i_uP_rxBufferFull        : std_logic;
    signal i_uP_rxBufferAlmostEmpty : std_logic;
    signal i_uP_rxBufferEmpty       : std_logic;

    signal i_fifoCoreDat         : std_logic_vector(31 downto 0);
    signal i_fifoCoreRead        : std_logic;
    signal i_fifoCoreEmpty       : std_logic;
    signal i_fifoCoreAlmostEmpty : std_logic;
    signal i_fifoCoreBurstReady  : std_logic;
    signal i_fifoCoreFull        : std_logic;
    signal i_coreFifoDat         : std_logic_vector(31 downto 0);
    signal i_coreFifoWrite       : std_logic;
    signal i_coreFifoFull        : std_logic;
    signal i_coreFifoAlmostFull  : std_logic;
    signal i_coreFifoEmpty       : std_logic;

    signal i_ack_to_spinnaker           : std_logic;
    signal i_data_2of7_to_spinnaker     : std_logic_vector(6 downto 0);
    signal i_ack_from_spinnaker         : std_logic;
    signal i_data_2of7_from_spinnaker   : std_logic_vector(6 downto 0);
    
    constant c_TestEnableSequencerNoWait            : boolean  := false;
    constant c_TestEnableSequencerToMonitorLoopback : boolean  := false;
    constant c_EnableMonitorControlsSequencerToo    : boolean  := false;

begin

    rst <= not nRst;

    u_spinn_neu_if : spinn_neu_if
        port map (
            rst                          => rst,                       -- in  std_logic;
            clk_32                       => Clk_Spinn,                 -- in  std_logic;
            -- status interface
            dump_mode                    => i_txDumpMode,              -- out std_logic;
            parity_err                   => i_rxParityErr,             -- out std_logic;
            rx_err                       => i_rxModemErr,              -- out std_logic;
            -- input SpiNNaker link interface
            data_2of7_from_spinnaker     => i_data_2of7_from_spinnaker,-- in  std_logic_vector(6 downto 0);
            ack_to_spinnaker             => i_ack_to_spinnaker,        -- out std_logic;
            -- output SpiNNaker link interface
            data_2of7_to_spinnaker       => i_data_2of7_to_spinnaker,  -- out std_logic_vector(6 downto 0);
            ack_from_spinnaker           => i_ack_from_spinnaker,      -- in  std_logic;
            -- input AER device interface
            iaer_addr                    => i_txSeqData,               -- in  std_logic_vector(31 downto 0);
            iaer_vld                     => i_txSeqSrcRdy,             -- in  std_logic;
            iaer_rdy                     => i_txSeqDstRdy,             -- out std_logic;
            -- output AER device interface
            oaer_addr                    => i_rxMonData,               -- out std_logic_vector(31 downto 0);
            oaer_vld                     => i_rxMonSrcRdy,             -- out std_logic;
            oaer_rdy                     => i_rxMonDstRdy,             -- in  std_logic
            
            dbg_rxstate                  => dbg_rxstate,
            dbg_txstate                  => dbg_txstate,
            dbg_ipkt_vld                 => dbg_ipkt_vld,
            dbg_ipkt_rdy                 => dbg_ipkt_rdy,
            dbg_opkt_vld                 => dbg_opkt_vld,
            dbg_opkt_rdy                 => dbg_opkt_rdy
        );
        
    dbg_dt_2of7_from_spin <= i_data_2of7_from_spinnaker;
    dbg_ack_to_spin       <= i_ack_to_spinnaker;
    
    dbg_dt_2of7_to_spin   <= i_data_2of7_to_spinnaker;
    dbg_ack_from_spin     <= i_ack_from_spinnaker;
    
    dbg_txSeqData    <= i_txSeqData; 
    dbg_txSeqSrcRdy  <= i_txSeqSrcRdy;
    dbg_txSeqDstRdy  <= i_txSeqDstRdy;

    dbg_rxMonData    <= i_rxMonData;  
    dbg_rxMonSrcRdy  <= i_rxMonSrcRdy;
    dbg_rxMonDstRdy  <= i_rxMonDstRdy;
    

    ---------------------
    -- Loopbacks
    ---------------------

    -- Local Near and Remote Loopback

    i_monData   <= i_seqData   when i_localLoopback = '1' else
                   i_rxMonData;
    i_monSrcRdy <= i_seqSrcRdy when i_localLoopback = '1' else
                   i_rxMonSrcRdy;

    i_rxMonDstRdy <= i_txSeqDstRdy when i_remoteLoopback = '1' else
                     '1'           when i_localLoopback  = '1' else
                     i_monDstRdy;


    i_txSeqData   <= i_rxMonData   when i_remoteLoopback = '1' else
                     i_seqData;
    i_txSeqSrcRdy <= i_rxMonSrcRdy when i_remoteLoopback = '1' else
                     i_seqSrcRdy;

    i_seqDstRdy <= i_monDstRdy when i_localLoopback  = '1' else
                   '1'         when i_remoteLoopback = '1' else
                   i_txSeqDstRdy;


    -- Local Far Loopback
    data_2of7_to_spinnaker <= (others => '0') when i_locFarLoopback = '1' else i_data_2of7_to_spinnaker;
    ack_to_spinnaker       <=             '0' when i_locFarLoopback = '1' else i_ack_to_spinnaker;
    
    i_ack_from_spinnaker       <= i_ack_to_spinnaker       when i_locFarLoopback = '1' else ack_from_spinnaker;
    i_data_2of7_from_spinnaker <= i_data_2of7_to_spinnaker when i_locFarLoopback = '1' else data_2of7_from_spinnaker;

    -------------------------------
    -- Sequencer & Monitor core
    -------------------------------

    u_CoreMonSeqRR : CoreMonSeqRR
        generic map (
            TestEnableSequencerNoWait            => c_TestEnableSequencerNoWait,
            TestEnableSequencerToMonitorLoopback => c_TestEnableSequencerToMonitorLoopback,
            EnableMonitorControlsSequencerToo    => c_EnableMonitorControlsSequencerToo
        )
        port map (
            Reset_xRBI              => nRst,                     -- in  std_logic;
            CoreClk_xCI             => Clk_Core,                 -- in  std_logic;
            --
            FlushFifos_xSI          => i_flushFifos,             -- in  std_logic;
            --ChipType_xSI            => ChipType,               -- in  std_logic;
            DmaLength_xDI           => i_dmaLength,              -- in  std_logic_vector(10 downto 0);
            --
            MonInAddr_xDI           => i_monData,                -- in  std_logic_vector(31 downto 0);
            MonInSrcRdy_xSI         => i_monSrcRdy,              -- in  std_logic;
            MonInDstRdy_xSO         => i_monDstRdy,              -- out std_logic;
            --
            SeqOutAddr_xDO          => i_seqData,                -- out std_logic_vector(31 downto 0);
            SeqOutSrcRdy_xSO        => i_seqSrcRdy,              -- out std_logic;
            SeqOutDstRdy_xSI        => i_seqDstRdy,              -- in  std_logic;
            -- Time stamper
            CleanTimer_xSI          => i_cleanTimer,             -- in  std_logic;
            WrapDetected_xSO        => i_wrapDetected,           -- out std_logic;
            --
            EnableMonitor_xSI       => '1',                      -- in  std_logic;
            CoreReady_xSI           => '1',                      -- in  std_logic;
            --
            FifoCoreDat_xDO         => i_fifoCoreDat,            -- out std_logic_vector(31 downto 0);
            FifoCoreRead_xSI        => i_fifoCoreRead,           -- in  std_logic;
            FifoCoreEmpty_xSO       => i_fifoCoreEmpty,          -- out std_logic;
            FifoCoreAlmostEmpty_xSO => i_fifoCoreAlmostEmpty,    -- out std_logic;
            FifoCoreBurstReady_xSO  => i_fifoCoreBurstReady,     -- out std_logic;
            FifoCoreFull_xSO        => i_fifoCoreFull,           -- out std_logic;
            --
            CoreFifoDat_xDI         => i_coreFifoDat,            -- in  std_logic_vector(31 downto 0);
            CoreFifoWrite_xSI       => i_coreFifoWrite,          -- in  std_logic;
            CoreFifoFull_xSO        => i_coreFifoFull,           -- out std_logic;
            CoreFifoAlmostFull_xSO  => i_coreFifoAlmostFull,     -- out std_logic;
            CoreFifoEmpty_xSO       => i_coreFifoEmpty           -- out std_logic
            --
        );



    u_axilite_if : spinn_axilite_if
        generic map (
            C_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
            C_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH
        )
        port map (
            -- ADD USER PORTS BELOW THIS LINE ------------------
            
            -- Loopback default values (set by external pin)
            LpbkDefault_i                  => LpbkDefault_i,                               -- in  std_logic_vector(2 downto 0);
            
            -- Interrupt
            -------------------------
            InterruptLine_o                => Interrupt_o,                                 -- out std_logic;

            -- RX Buffer Reg
            -------------------------
            ReadRxBuffer_o                 => i_uP_readRxBuffer,                           -- out std_logic;
            RxDataBuffer_i                 => i_uP_rxDataBuffer,                           -- in  std_logic_vector(31 downto 0);
            RxTimeBuffer_i                 => i_uP_rxTimeBuffer,                           -- in  std_logic_vector(31 downto 0);
            -- Tx Buffer Reg
            -------------------------
            WriteTxBuffer_o                => i_uP_writeTxBuffer,                          -- out std_logic;
            TxDataBuffer_o                 => i_uP_txDataBuffer,                           -- out std_logic_vector(31 downto 0);

            -- Controls
            -------------------------
            EnableDmaIf_o                  => i_enableDmaIf,                               -- out std_logic;
            RearmDma_o                     => i_rearmDma,                                  -- out std_logic;
            DmaLength_o                    => i_dmaLength,                                 -- out std_logic_vector(10 downto 0);

            CleanTimer_o                   => i_cleanTimer,                                -- out std_logic;
            FlushFifos_o                   => i_flushFifos,                                -- out std_logic;

            -- Configurations
            -------------------------
            RemoteLoopback_o               => i_remoteLoopback,                            -- out std_logic;
            LocalLoopback_o                => i_localLoopback,                             -- out std_logic;
            LocFarLoopback_o               => i_locFarLoopback,                            -- out std_logic;
            --EnableIp_o                     =>                                              -- out std_logic;

            -- Status
            -------------------------
            WrapDetected_i                 => i_wrapDetected,                              -- in  std_logic;
            TxDumpMode_i                   => i_txDumpMode,                                -- in  std_logic;
            RxParityErr_i                  => i_rxParityErr,                               -- in  std_logic;
            RxModemErr_i                   => i_rxModemErr,                                -- in  std_logic;
            RxBufferReady_i                => i_uP_rxBufferReady,                          -- in  std_logic;
            TxBufferFull_i                 => i_uP_txBufferFull,                           -- in  std_logic;
            TxBufferAlmostFull_i           => i_uP_txBufferAlmostFull,                     -- in  std_logic;
            TxBufferEmpty_i                => i_uP_txBufferEmpty,                          -- in  std_logic;
            RxBufferFull_i                 => i_uP_rxBufferFull,                           -- in  std_logic;
            RxBufferAlmostEmpty_i          => i_uP_rxBufferAlmostEmpty,                    -- in  std_logic;
            RxBufferEmpty_i                => i_uP_rxBufferEmpty,                          -- in  std_logic;


            -- ADD USER PORTS ABOVE THIS LINE ------------------

            -- DO NOT EDIT BELOW THIS LINE ---------------------
            -- Bus protocol ports, do not add to or delete
            -- Axi lite I-f
            S_AXI_ACLK                     => S_AXI_ACLK,                                  -- in  std_logic;
            S_AXI_ARESETN                  => S_AXI_ARESETN,                               -- in  std_logic;
            S_AXI_AWADDR                   => S_AXI_AWADDR,                                -- in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
            S_AXI_AWVALID                  => S_AXI_AWVALID,                               -- in  std_logic;
            S_AXI_WDATA                    => S_AXI_WDATA,                                 -- in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
            S_AXI_WSTRB                    => S_AXI_WSTRB,                                 -- in  std_logic_vector(3 downto 0);
            S_AXI_WVALID                   => S_AXI_WVALID,                                -- in  std_logic;
            S_AXI_BREADY                   => S_AXI_BREADY,                                -- in  std_logic;
            S_AXI_ARADDR                   => S_AXI_ARADDR,                                -- in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
            S_AXI_ARVALID                  => S_AXI_ARVALID,                               -- in  std_logic;
            S_AXI_RREADY                   => S_AXI_RREADY,                                -- in  std_logic;
            S_AXI_ARREADY                  => S_AXI_ARREADY,                               -- out std_logic;
            S_AXI_RDATA                    => S_AXI_RDATA,                                 -- out std_logic_vector(C_DATA_WIDTH-1 downto 0);
            S_AXI_RRESP                    => S_AXI_RRESP,                                 -- out std_logic_vector(1 downto 0);
            S_AXI_RVALID                   => S_AXI_RVALID,                                -- out std_logic;
            S_AXI_WREADY                   => S_AXI_WREADY,                                -- out std_logic;
            S_AXI_BRESP                    => S_AXI_BRESP,                                 -- out std_logic_vector(1 downto 0);
            S_AXI_BVALID                   => S_AXI_BVALID,                                -- out std_logic;
            S_AXI_AWREADY                  => S_AXI_AWREADY                                -- out std_logic
            -- DO NOT EDIT ABOVE THIS LINE ---------------------
        );



    u_axistream_if : spinn_axistream_if
        port map (
            Clk                            => S_AXI_ACLK,                                  -- in  std_logic;
            nRst                           => nRst,                                        -- in  std_logic;
            --                            
            EnableAxistreamIf_i            => i_enableDmaIf,                               -- in  std_logic;
            DmaLength_i                    => i_dmaLength,                                 -- in  std_logic_vector(10 downto 0);
            RearmDma_i                     => i_rearmDma,                                  -- in  std_logic;
            -- From Fifo to core/dma
            FifoCoreDat_i                  => i_dma_rxDataBuffer,                          -- in  std_logic_vector(31 downto 0);
            FifoCoreRead_o                 => i_dma_readRxBuffer,                          -- out std_logic;
            FifoCoreEmpty_i                => i_dma_rxBufferEmpty,                         -- in  std_logic;
            FifoCoreBurstReady_i           => i_dma_rxBufferReady,                         -- in  std_logic;
            -- From core/dma to Fifo
            CoreFifoDat_o                  => i_dma_txDataBuffer,                          -- out std_logic_vector(31 downto 0);
            CoreFifoWrite_o                => i_dma_writeTxBuffer,                         -- out std_logic;
            CoreFifoFull_i                 => i_dma_txBufferFull,                          -- in  std_logic;
            -- Axi Stream I/f              
            S_AXIS_TREADY                  => S_AXIS_TREADY,                               -- out std_logic;
            S_AXIS_TDATA                   => S_AXIS_TDATA,                                -- in  std_logic_vector(31 downto 0);
            S_AXIS_TLAST                   => S_AXIS_TLAST,                                -- in  std_logic;
            S_AXIS_TVALID                  => S_AXIS_TVALID,                               -- in  std_logic;
            M_AXIS_TVALID                  => M_AXIS_TVALID,                               -- out std_logic;
            M_AXIS_TDATA                   => M_AXIS_TDATA,                                -- out std_logic_vector(31 downto 0);
            M_AXIS_TLAST                   => M_AXIS_TLAST,                                -- out std_logic;
            M_AXIS_TREADY                  => M_AXIS_TREADY                                -- in  std_logic
        );


    -- Muxing AXI-Lite and AXI-Stream Fifo interfaces --
    ----------------------------------------------------

    i_uP_rxDataBuffer        <= i_fifoCoreDat;
    i_uP_rxTimeBuffer        <= i_fifoCoreDat;
    i_uP_rxBufferReady       <= i_fifoCoreBurstReady;
    i_uP_rxBufferEmpty       <= i_fifoCoreEmpty;
    i_uP_rxBufferAlmostEmpty <= i_fifoCoreAlmostEmpty;
    i_uP_rxBufferFull        <= i_fifoCoreFull;
                             
    i_dma_rxDataBuffer       <= i_fifoCoreDat;
    i_dma_rxBufferReady      <= i_fifoCoreBurstReady;
    i_dma_rxBufferEmpty      <= i_fifoCoreEmpty;
                             
    i_fifoCoreRead           <= i_dma_readRxBuffer  when (i_enableDmaIf='1') else
                                i_uP_readRxBuffer;
                             
                             
    i_uP_txBufferEmpty       <= i_coreFifoEmpty;
    i_uP_txBufferAlmostFull  <= i_coreFifoAlmostFull;
    i_uP_txBufferFull        <= i_coreFifoFull;
                             
    i_dma_txBufferFull       <= i_coreFifoFull;
                             
    i_coreFifoDat            <= i_dma_txDataBuffer  when (i_enableDmaIf='1') else
                                i_uP_txDataBuffer;
    i_coreFifoWrite          <= i_dma_writeTxBuffer when (i_enableDmaIf='1') else
                                i_uP_writeTxBuffer;
                             


end architecture str;
