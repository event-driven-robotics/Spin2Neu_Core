----------------------------------------------------------------------
----                                                              ----
---- AXI Lite NeuSerial Interface IP Core                         ----
----                                                              ----
----                                                              ----
---- To Do:                                                       ----
---- -                                                            ----
----                                                              ----
---- Author(s):                                                   ----
---- - Francesco Diotalevi, Istituto Italiano di Tecnologia       ----
---- - Gaetano de Robertis, Istituto Italiano di Tecnologia       ----
----                                                              ----
----------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
--    use ieee.std_logic_unsigned.all;

--library common_lib;
--    use common_lib.utilities_pkg.all;


--****************************
--   PORT DECLARATION
--****************************

entity spinn_axilite_if is
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

    attribute MAX_FANOUT : string;
    attribute SIGIS : string;
    attribute MAX_FANOUT of S_AXI_ACLK     : signal is "10000";
    attribute MAX_FANOUT of S_AXI_ARESETN  : signal is "10000";
    attribute SIGIS of S_AXI_ACLK          : signal is "Clk";
    attribute SIGIS of S_AXI_ARESETN       : signal is "Rst";

end entity spinn_axilite_if;


--****************************
--   IMPLEMENTATION
--****************************

architecture rtl of spinn_axilite_if is

    constant cVer   : string(3 downto 1) := "S2N";
    constant cMAJOR : std_logic_vector(3 downto 0) :="0001";
    constant cMINOR : std_logic_vector(3 downto 0) :="0000";

    constant c_zero_vect : std_logic_vector(31 downto 0) := (others => '0');


    ----------------------------------------------------------------------------
    -- AXI4 Lite internal signals
    ----------------------------------------------------------------------------

    ---------------------------------
    -- read response
    signal  axi_rresp : std_logic_vector(1 downto 0);
    ---------------------------------
    -- write response
    signal  axi_bresp : std_logic_vector(1 downto 0);
    ---------------------------------
    -- write address acceptance
    signal  axi_awready : std_logic;
    ---------------------------------
    -- write data acceptance
    signal  axi_wready : std_logic;
    ---------------------------------
    -- write response valid
    signal  axi_bvalid : std_logic;
    ---------------------------------
    -- read data valid
    signal  axi_rvalid : std_logic;
    ---------------------------------
    -- write address
    signal  axi_awaddr : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    ---------------------------------
    -- read address valid
    signal  axi_araddr : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    ---------------------------------
    -- read data
    signal  axi_rdata : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    ---------------------------------
    -- read address acceptance
    signal  axi_arready : std_logic;

    ----------------------------------------------------------------------------
    -- Slave register read enable
    signal  slvRegRden : std_logic;
    ----------------------------------------------------------------------------
    -- Slave register write enable
    signal  slvRegWren : std_logic;
    ----------------------------------------------------------------------------
    -- register read data
    signal  regDataOut : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    ----------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    -- Signals for user logic slave model s/w accessible register
    ----------------------------------------------------------------------------
    signal  i_CTRL_reg            : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    -- signal  i_RXData_reg          : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    -- signal  i_RXTime_reg          : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_TXData_reg          : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_DMA_reg             : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    -- signal  i_RAWSTAT_reg         : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_IRQ_reg             : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_MSK_reg             : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_WRAPTime_reg        : unsigned(C_SLV_DWIDTH-1 downto 0);

    signal  i_CTRL_rd             : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_RXData_rd           : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_RXTime_rd           : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_TXData_rd           : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_DMA_rd              : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_RAWSTAT_rd          : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_IRQ_rd              : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_MSK_rd              : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_WRAPTime_rd         : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal  i_ID_rd               : std_logic_vector(C_SLV_DWIDTH-1 downto 0);


    signal i_rxBufferNotEmpty     : std_logic;
    signal i_rawInterrupt         : std_logic_vector(15 downto 0);

    signal  i_LocFarLoopback      : std_logic;
    signal  i_LocalLoopback       : std_logic;
    signal  i_RemoteLoopback      : std_logic;
    signal  i_RearmDma            : std_logic;
    signal  i_FlushFifos          : std_logic;
    -- signal  i_EnableLoopBack      : std_logic;
    signal  i_interruptEnable     : std_logic;
    signal  i_EnableDmaIf         : std_logic;
    -- signal  i_EnableIp            : std_logic;
    signal  i_TxDataBuffer        : std_logic_vector(31 downto 0);
    signal  i_DmaLength           : std_logic_vector(10 downto 0);
    signal  i_cleanTimer          : std_logic;

begin


    ReadRxBuffer_o <= axi_arready when (unsigned(axi_araddr(C_ADDR_WIDTH-1 downto 2)) = 2 or unsigned(axi_araddr(C_ADDR_WIDTH-1 downto 2)) = 3) else
                    '0';

    i_rxBufferNotEmpty <= not(RxBufferEmpty_i);

    i_rawInterrupt <=  '0'                      &
                       RxModemErr_i             &
                       RxParityErr_i            &
                       TxDumpMode_i             &
                       "00"                     &
                       i_rxBufferNotEmpty       &
                       RxBufferReady_i          &
                       WrapDetected_i           &
                       '0'                      &
                       TxBufferFull_i           &
                       TxBufferAlmostFull_i     &
                       TxBufferEmpty_i          &
                       RxBufferFull_i           &
                       RxBufferAlmostEmpty_i    &
                       RxBufferEmpty_i          ;


    ----------------------------------------------------------------------------
    --I/O Connections assignments

    ----------------------------------------------------------------------------
    --Write Address Ready (AWREADY)
    S_AXI_AWREADY <= axi_awready;

    ----------------------------------------------------------------------------
    --Write Data Ready(WREADY)
    S_AXI_WREADY  <= axi_wready;

    ----------------------------------------------------------------------------
    --Write Response (BResp)and response valid (BVALID)
    S_AXI_BRESP   <= axi_bresp;
    S_AXI_BVALID  <= axi_bvalid;

    ----------------------------------------------------------------------------
    --Read Address Ready(AREADY)
    S_AXI_ARREADY <= axi_arready;

    ----------------------------------------------------------------------------
    --Read and Read Data (RDATA), Read Valid (RVALID) and Response (RRESP)
    S_AXI_RDATA   <= axi_rdata;
    S_AXI_RVALID  <= axi_rvalid;
    S_AXI_RRESP   <= axi_rresp;


    ----------------------------------------------------------------------------
    -- Implement axi_awready generation
    --
    --  axi_awready is asserted for one S_AXI_ACLK clock cycle when both
    --  S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
    --  de-asserted when reset is low.
    p_awready_gen : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_awready <= '0';
            else
                if (axi_awready='0' and S_AXI_AWVALID='1' and S_AXI_WVALID='1') then
                    axi_awready <= '1';
                else
                    axi_awready <= '0';
                end if;
            end if;
        end if;
    end process p_awready_gen;


    ----------------------------------------------------------------------------
    -- Implement axi_awaddr latching
    --
    --  This process is used to latch the address when both
    --  S_AXI_AWVALID and S_AXI_WVALID are valid.

    p_awaddr_latch : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_awaddr <= (others => '0');
            else
                if (axi_awready='0' and S_AXI_AWVALID='1' and S_AXI_WVALID='1') then
                    axi_awaddr <= S_AXI_AWADDR;
                end if;
            end if;
        end if;
    end process p_awaddr_latch;


    ----------------------------------------------------------------------------
    -- Implement axi_wready generation
    --
    --  axi_wready is asserted for one S_AXI_ACLK clock cycle when both
    --  S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
    --  de-asserted when reset is low.

    p_wready_gen : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_wready <= '0';
            else
                if (axi_wready='0' and S_AXI_AWVALID='1' and S_AXI_WVALID='1') then
                    ----------------------------------------------------------------------------
                    -- slave is ready to accept write data when
                    -- there is a valid write address and write data
                    -- on the write address and data bus. This design
                    -- expects no outstanding transactions.
                    axi_wready <= '1';
                else
                    axi_wready <= '0';

                end if;
            end if;
        end if;
    end process p_wready_gen;



    ----------------------------------------------------------------------------
    -- Implement memory mapped register select and write logic generation
    --
    -- The write data is accepted and written to memory mapped
    -- registers (CTRL_reg, slv_reg1, RXData_reg, RXTime_reg) when axi_wready,
    -- S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    -- select byte enables of slave registers while writing.
    -- These registers are cleared when reset (active low) is applied.
    --
    -- Slave register write enable is asserted when valid address and data are available
    -- and the slave is ready to accept the write address and write data.

    slvRegWren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID;

    p_write : process (S_AXI_ACLK)
        variable v_IRQ_reg           : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
        variable v_HSSAER_RX_ERR_reg : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                i_CTRL_reg          <= (26 => LpbkDefault_i(2),
                                        25 => LpbkDefault_i(1),
                                        24 => LpbkDefault_i(0),
                                         8 => '1',
                                        others => '0');
                -- i_RXData_reg        <= (others => '0');          -- (RO  - Read only register)
                -- i_RXTime_reg        <= (others => '0');          -- (RO  - Read only register)
                i_TXData_reg        <= (others => '0');
                i_DMA_reg           <= (8 => '1', others => '0');
                -- i_RAWSTAT_reg       <= (others => '0');          -- (RO  - Read only register)
                i_IRQ_reg           <= (others => '0');             -- (RWC - Clear-On-Write register)
                i_MSK_reg           <= (others => '0');
                i_WRAPTime_reg      <= (others => '0');             -- (RWC - Clear-On-Write register)

                WriteTxBuffer_o <= '0';
                i_cleanTimer  <= '0';

            else
                WriteTxBuffer_o <= '0';

                -- Wrapping counter register
                if (WrapDetected_i = '1') then
                    --i_WRAPTime_reg <= std_logic_vector(to_unsigned(to_integer(unsigned(i_WRAPTime_reg))+1,32));
                    i_WRAPTime_reg <= i_WRAPTime_reg+1;
                end if;
                i_cleanTimer <= '0';     -- i_WRAPTime_reg cleared on write

                -- Ctrl register
                i_CTRL_reg( 4) <= '0';   -- FlushFifos_o            (WO: monostable)
                i_CTRL_reg(12) <= '0';   -- RearmDma_o              (WO: monostable)

                -- IRQ Register
                -- Update the value of the IRQ
                v_IRQ_reg := i_IRQ_reg;
                for i in 15 downto 0 loop
                    v_IRQ_reg(i) := v_IRQ_reg(i) or (i_rawInterrupt(i) and i_MSK_reg(i));
                end loop;

                if (slvRegWren = '1') then
                    case (to_integer(unsigned(axi_awaddr(C_ADDR_WIDTH-1 downto 2)))) is
                        when  0 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_CTRL_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                     -- when  2 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_RXData_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;
                     -- when  3 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_RXTime_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;
                        when  4 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_TXData_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                    WriteTxBuffer_o <= '1';
                                end if;
                            end loop;
                        when  5 =>
                            -- DMA_reg can be written only if CTRL_reg(1)='0', i.e. if the DMAIf is disabled
                            if (i_CTRL_reg(1)='0') then
                                for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                    if (S_AXI_WSTRB(byte_index) = '1') then
                                        i_DMA_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                    end if;
                                end loop;
                            end if;
                     -- when  6 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_RAWSTAT_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;
                        when  7 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    v_IRQ_reg(byte_index*8+7 downto byte_index*8) := v_IRQ_reg(byte_index*8+7 downto byte_index*8) and (not(S_AXI_WDATA(byte_index*8+7 downto byte_index*8)));
                                end if;
                            end loop;
                        when  8 =>
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_MSK_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                                end if;
                            end loop;
                        when 10 =>
                            -- Any writing actvity clear the WRAPTime_reg
                            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                                if (S_AXI_WSTRB(byte_index) = '1') then
                                    i_WRAPTime_reg <= (others => '0');
                                    i_cleanTimer <= '1';
                                end if;
                            end loop;
                     -- when 23 =>
                     --     for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
                     --         if (S_AXI_WSTRB(byte_index) = '1') then
                     --             i_ID_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                     --         end if;
                     --     end loop;

                        when others => null;

                    end case;
                end if;
                i_IRQ_reg <= v_IRQ_reg;
            end if;
        end if;
    end process p_write;


    ----------------------------------------------------------------------------
    -- Implement write response logic generation
    --
    --  The write response and response valid signals are asserted by the slave
    --  when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
    --  This marks the acceptance of address and indicates the status of
    --  write transaction.

    p_bresp_gen : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_bvalid  <= '0';
                axi_bresp   <= "00";
            else
                if (axi_awready='1' and S_AXI_AWVALID='1' and axi_bvalid='0' and axi_wready='1' and S_AXI_WVALID='1') then
                    -- indicates a valid write response is available
                    axi_bvalid <= '1';
                    axi_bresp  <= "00"; -- 'OKAY' response
                else
                    if (S_AXI_BREADY='1' and axi_bvalid='1') then
                        --check if bready is asserted while bvalid is high)
                        --(there is a possibility that bready is always asserted high)
                        axi_bvalid <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process p_bresp_gen;


    ----------------------------------------------------------------------------
    -- Implement axi_arready generation
    --
    --  axi_arready is asserted for one S_AXI_ACLK clock cycle when
    --  S_AXI_ARVALID is asserted. axi_awready is
    --  de-asserted when reset (active low) is asserted.
    --  The read address is also latched when S_AXI_ARVALID is
    --  asserted. axi_araddr is reset to zero on reset assertion.

    p_arready_gen : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_arready <= '0';
                axi_araddr  <= (others => '0');
            else
                if (axi_arready='0' and S_AXI_ARVALID='1') then
                    -- indicates that the slave has acceped the valid read address
                    axi_arready <= '1';
                    axi_araddr  <= S_AXI_ARADDR;
                else
                    axi_arready <= '0';
                end if;
            end if;
        end if;
    end process p_arready_gen;


    ----------------------------------------------------------------------------
    -- Implement memory mapped register select and read logic generation
    --
    --  axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
    --  S_AXI_ARVALID and axi_arready are asserted. The slave registers
    --  data are available on the axi_rdata bus at this instance. The
    --  assertion of axi_rvalid marks the validity of read data on the
    --  bus and axi_rresp indicates the status of read transaction.axi_rvalid
    --  is deasserted on reset (active low). axi_rresp and axi_rdata are
    --  cleared to zero on reset (active low).

    p_rresp_gen : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_rvalid <= '0';
                axi_rresp  <= (others => '0');
            else
                if (axi_arready='1' and S_AXI_ARVALID='1' and axi_rvalid='0') then
                    -- Valid read data is available at the read data bus
                    axi_rvalid <= '1';
                    axi_rresp  <= (others => '0'); -- 'OKAY' response
                elsif (axi_rvalid='1' and S_AXI_RREADY='1') then
                    -- Read data is accepted by the master
                    axi_rvalid <= '0';
                end if;
            end if;
        end if;
    end process p_rresp_gen;

    ----------------------------------------------------------------------------
    -- Slave register read enable is asserted when valid address is available
    -- and the slave is ready to accept the read address.
    slvRegRden <= axi_arready and S_AXI_ARVALID and not(axi_rvalid);

    p_read_mux : process (S_AXI_ARESETN, axi_araddr,
                          i_CTRL_rd, i_RXData_rd, i_RXTime_rd, i_TXData_rd, i_DMA_rd, i_RAWSTAT_rd,
                          i_IRQ_rd, i_MSK_rd,
                          i_WRAPTime_rd,
                          i_ID_rd)
    begin
        if (S_AXI_ARESETN = '0') then
            regDataOut <= (others => '0');
        else
            case (to_integer(unsigned(axi_araddr(C_ADDR_WIDTH-1 downto 2)))) is
                when  0 => regDataOut  <= i_CTRL_rd;
                when  2 => regDataOut  <= i_RXData_rd;
                when  3 => regDataOut  <= i_RXTime_rd;
                when  4 => regDataOut  <= i_TXData_rd;
                when  5 => regDataOut  <= i_DMA_rd;
                when  6 => regDataOut  <= i_RAWSTAT_rd;
                when  7 => regDataOut  <= i_IRQ_rd;
                when  8 => regDataOut  <= i_MSK_rd;
                when 10 => regDataOut  <= i_WRAPTime_rd;
                when 23 => regDataOut  <= i_ID_rd;
                when others  => regDataOut  <= (others => '0');
            end case;
        end if;
    end process p_read_mux;



    p_read_data : process (S_AXI_ACLK)
    begin
        if (rising_edge(S_AXI_ACLK)) then
            if (S_AXI_ARESETN = '0') then
                axi_rdata <= (others => '0');
            else
                ----------------------------------------------------------------------------
                -- When there is a valid read address (S_AXI_ARVALID) with
                -- acceptance of read address by the slave (axi_arready),
                -- output the read dada
                if (axi_arready='1' and S_AXI_ARVALID= '1' and axi_rvalid='0') then
                    axi_rdata <= regDataOut;     -- register read data
                end if;
            end if;
        end if;
    end process p_read_data;


    -- ------------------------------------------------------------------------
    -- Control register
    -- ------------------------------------------------------------------------
    -- CTRL_reg - R/W
    --

    i_LocFarLoopback       <= i_CTRL_reg(26);
    i_LocalLoopback        <= i_CTRL_reg(25);
    i_RemoteLoopback       <= i_CTRL_reg(24);

    i_RearmDma             <= i_CTRL_reg(12);

    i_FlushFifos           <= i_CTRL_reg(4);
 -- i_EnableLoopBack       <= i_CTRL_reg(3);                   -- Reserved for back compatibility with neuelab
    i_interruptEnable      <= i_CTRL_reg(2);
    i_EnableDmaIf          <= i_CTRL_reg(1);
 -- i_EnableIp             <= i_CTRL_reg(0);                   -- Reserved for back compatibility with neuelab

    i_CTRL_rd <=    c_zero_vect(31 downto 27) &
                    i_LocFarLoopback          &
                    i_LocalLoopback           &
                    i_RemoteLoopback          &
                    c_zero_vect(23 downto 13) &
                    i_RearmDma                &
                    c_zero_vect(11 downto  5) &
                    i_FlushFifos              &
                    c_zero_vect(3)            &
                    i_interruptEnable         &
                    i_EnableDmaIf             &
                    c_zero_vect(0)            ;

    LocFarLoopback_o       <= i_LocFarLoopback;
    LocalLoopback_o        <= i_LocalLoopback;
    RemoteLoopback_o       <= i_RemoteLoopback;
    RearmDma_o             <= i_RearmDma;
    FlushFifos_o           <= i_FlushFifos;
 -- EnableLoopBack_o       <= i_EnableLoopBack;                -- Reserved for back compatibility with neuelab
    EnableDmaIf_o          <= i_EnableDmaIf;
 -- EnableIp_o             <= i_EnableIp;                      -- Reserved for back compatibility with neuelab


    -- ------------------------------------------------------------------------
    -- RX Buffer
    -- ------------------------------------------------------------------------
    -- RXData_reg - Data Buffer R/O
    --

    i_RXData_rd <= RxDataBuffer_i;


    -- RXTime_reg - Time Buffer R/O
    --

    i_RXTime_rd <= RxTimeBuffer_i;


    -- ------------------------------------------------------------------------
    -- TX Buffer
    -- ------------------------------------------------------------------------
    -- TXData_reg - Data Buffer R/W
    --

    i_TxDataBuffer <= i_TXData_reg;

    i_TXData_rd <= i_TxDataBuffer;

    TxDataBuffer_o <= i_TxDataBuffer;


    -- ------------------------------------------------------------------------
    -- DMA I/f
    -- ------------------------------------------------------------------------
    -- DMA_reg - DMA Interface register R/W
    --

    i_DmaLength <= i_DMA_reg(10 downto 0);

    i_DMA_rd <= c_zero_vect(31 downto 11) &
                i_DmaLength;

    DmaLength_o <= i_DmaLength;


    -- ------------------------------------------------------------------------
    -- RAW Status register
    -- ------------------------------------------------------------------------
    -- RAWSTAT_reg - Raw Int reg R/O
    --

    i_RAWSTAT_rd <= c_zero_vect(31 downto 16)     &
                    i_rawInterrupt                ;



    -- ------------------------------------------------------------------------
    -- IRQ Interrupt register
    -- ------------------------------------------------------------------------
    -- IRQ_reg - Irq reg R/WC
    --

    i_IRQ_rd <= c_zero_vect(31 downto 16)        &
                i_IRQ_reg(15 downto  0)          ;

    p_intr_gen : process (i_IRQ_rd, i_interruptEnable)
        variable v_intr : std_logic;
    begin
        v_intr := '0';
        for i in 0 to 15 loop
            v_intr := v_intr or i_IRQ_rd(i);
        end loop;
        InterruptLine_o <= v_intr and i_interruptEnable;
    end process p_intr_gen;


    -- ------------------------------------------------------------------------
    -- IMASK Interrupt Mask register
    -- ------------------------------------------------------------------------
    -- MSK_reg - Interrupt Mask register R/W
    --

    i_MSK_rd <= i_MSK_reg;


    -- ------------------------------------------------------------------------
    -- WRAPCounter_REG  Timestamp wrapping counter
    -- ------------------------------------------------------------------------
    -- WRAPTime_reg - Timestamp wrapping counter R/WC
    --

    i_WRAPTime_rd <= std_logic_vector(i_WRAPTime_reg);
    CleanTimer_o <= i_cleanTimer;


    -- ------------------------------------------------------------------------
    -- ID Register
    -- ------------------------------------------------------------------------
    -- ID_rd - R/O

    i_ID_rd <= std_logic_vector(to_unsigned(natural(character'pos(cVer(3))), 8)) &
               std_logic_vector(to_unsigned(natural(character'pos(cVer(2))), 8)) &
               std_logic_vector(to_unsigned(natural(character'pos(cVer(1))), 8)) &
               cMAJOR                                                            &
               cMINOR                                                            ;



end architecture rtl;

----------------------------------------------------------------------
