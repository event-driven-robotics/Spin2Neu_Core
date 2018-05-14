-------------------------------------------------------------------------------
-- Neuserial_AxiStream
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;


--****************************
--   PORT DECLARATION
--****************************

entity spinn_axistream_if is
    generic (
        C_NUMBER_OF_INPUT_WORDS : natural := 2048
    );
    port (
        Clk                    : in  std_logic;
        nRst                   : in  std_logic;
        --                    
        EnableAxistreamIf_i    : in  std_logic;
        DmaLength_i            : in  std_logic_vector(10 downto 0);
        RearmDma_i             : in  std_logic;
        -- From Fifo to core/dma
        FifoCoreDat_i          : in  std_logic_vector(31 downto 0);
        FifoCoreRead_o         : out std_logic;
        FifoCoreEmpty_i        : in  std_logic;
        FifoCoreBurstReady_i   : in  std_logic;
        -- From core/dma to Fifo
        CoreFifoDat_o          : out std_logic_vector(31 downto 0);
        CoreFifoWrite_o        : out std_logic;
        CoreFifoFull_i         : in  std_logic;
        -- Axi Stream I/f
        S_AXIS_TREADY          : out std_logic;
        S_AXIS_TDATA           : in  std_logic_vector(31 downto 0);
        S_AXIS_TLAST           : in  std_logic;
        S_AXIS_TVALID          : in  std_logic;
        M_AXIS_TVALID          : out std_logic;
        M_AXIS_TDATA           : out std_logic_vector(31 downto 0);
        M_AXIS_TLAST           : out std_logic;
        M_AXIS_TREADY          : in  std_logic
    );
end entity spinn_axistream_if;

architecture rtl of spinn_axistream_if is

    signal i_nrOfWrites    : natural range 0 to C_NUMBER_OF_INPUT_WORDS - 1;

    signal i_readFifo      : std_logic;
    signal i_M_AXIS_TLAST  : std_logic;
    signal i_enBurst       : std_logic;
    signal i_enableRearm   : std_logic;

begin

    -- Master I/f

    p_counter : process (Clk) is
    begin
        if (rising_edge(Clk)) then
            if (nRst = '0') then               -- Synchronous reset (active low)
                i_nrOfWrites  <= to_integer(unsigned(DmaLength_i)) - 1;
            else
                if (EnableAxistreamIf_i = '0') then
                    i_nrOfWrites  <= to_integer(unsigned(DmaLength_i)) - 1;
                else
                    if (i_nrOfWrites = 0) then
                        i_nrOfWrites  <= to_integer(unsigned(DmaLength_i)) - 1;
                    else
                        if (i_readFifo = '1') then
                            i_nrOfWrites  <= i_nrOfWrites - 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process p_counter;


    i_M_AXIS_TLAST    <= ('1' and EnableAxistreamIf_i) when (i_nrOfWrites = 0) else
                         '0';

    p_dma_ctrl : process (Clk) is
        begin
        if (rising_edge(Clk)) then
            if (nRst = '0') then
                i_enBurst <= '0';
                i_enableRearm <='0';
            else
                if (i_M_AXIS_TLAST = '1') then
                    i_enBurst <= '0';
                elsif (FifoCoreBurstReady_i = '1' and FifoCoreEmpty_i= '0') then
                    i_enBurst <= '1';
                end if;
                
                if (i_M_AXIS_TLAST = '1') then
                    i_enableRearm <= '0';
                elsif (RearmDma_i = '1') then
                    i_enableRearm <= '1';
                end if;
            end if;
        end if;
    end process p_dma_ctrl;

    i_readFifo  <= i_enBurst and M_AXIS_TREADY and EnableAxistreamIf_i and i_enableRearm;

    FifoCoreRead_o    <= i_readFifo;
    M_AXIS_TVALID     <= i_enBurst and EnableAxistreamIf_i and i_enableRearm;
    M_AXIS_TLAST      <= i_M_AXIS_TLAST;
    M_AXIS_TDATA      <= FifoCoreDat_i;

    -- Slave I/f

    S_AXIS_TREADY     <= not(CoreFifoFull_i) and EnableAxistreamIf_i;
    CoreFifoDat_o     <= S_AXIS_TDATA;
    CoreFifoWrite_o   <= (not(CoreFifoFull_i) and S_AXIS_TVALID) and EnableAxistreamIf_i;


end architecture rtl;
-------------------------------------------------------------------------------
