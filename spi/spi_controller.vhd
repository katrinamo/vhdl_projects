-- File: spi_controller.vhd
-- Description: A simple implementation of a SPI controller. Defaults to a 50 MHz input clock and 1 MHz serial clock.
--              While adjustable, please note clock division assumes MHz.
-- Author: Katie Long

-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity spi_controller is
generic(
  DATA_WIDTH  : integer := 8;
  CLK_IN_MHZ  : integer := 50;
  CLK_OUT_MHZ : integer := 1
);
port(
    clk     : in std_logic;
    rst_n   : in std_logic;
    data    : in std_logic_vector(DATA_WIDTH-1 downto 0);
    miso    : in std_logic;     -- Master in, slave out
    tx_en   : in std_logic;     -- Start transmission
    tx_done : out std_logic;    -- signal TX is done
    mosi    : out std_logic;    -- Master out, slave in    
    cs_n    : out std_logic;    -- Chip select (active low)
    sclk    : out std_logic     -- Serial clock
);
end entity spi_controller;

architecture behavioral of spi_controller is
    -- Clock signals
    constant spulse_width : integer := CLK_IN_MHZ / CLK_OUT_MHZ;
    signal ctr : integer range 0 to spulse_width/2 - 1;    
    signal sclk_en : std_logic := '0';
    
    -- TX FSM signals
    type tx_state is (TX_IDLE, TX_BIT, TX_END);
    signal cur_state : tx_state;
    signal bit : integer range 0 to DATA_WIDTH - 1;
    
begin
    
    -- Simple clock divider. Generates a 50% duty cycle clock.
    sclk_gen : process(clk, rst_n)
    begin
        if (rst_n = '0') then
            sclk <= '0';
        elsif rising_edge(clk)then
            if (sclk_en = '1')  then
                if (ctr = spulse_width/2 - 1) then
                    sclk <= not sclk;
                    ctr <= 0;
                else
                    ctr <= ctr+1;
                end if;
            end if;
        end if;   
    end process sclk_gen;
    

    spi_proc : process(clk, rst_n, sclk)
    begin
        if (rst_n = '0') then
            mosi <= '0';
            sclk_en <= '0';
            cur_state <= TX_IDLE;
            bit <= DATA_WIDTH-1;
        elsif(rising_edge(clk) or falling_edge(sclk)) then
            case cur_state is
                
                -- If we receive an enable, start transmission
                when TX_IDLE =>
                    tx_done <= '0';
                    
                    if (tx_en = '1') then
                        sclk_en <= '1';
                        cur_state <= TX_BIT;
                    else
                        sclk_en <= '0';
                        cur_state <= TX_IDLE;
                    end if;
                
                -- Send all bits
                when TX_BIT =>
                    mosi <= data(bit);                        
                    
                    if (falling_edge(sclk)) and (bit > 0) then
                        cur_state <= TX_BIT;                    
                        bit <= bit-1;
                    elsif (falling_edge(sclk)) and (bit = 0) then
                        cur_state <= TX_END;
                        bit <= DATA_WIDTH-1;
                    else
                        cur_state <= TX_BIT;
                    end if;
                    
                -- Hold last bit and then go to idle
                when TX_END =>
                    if (ctr = spulse_width/4 - 1) then
                        sclk_en <= '0';
                        tx_done <= '1';            
                        cur_state <= TX_IDLE;
                    else
                        cur_state <= TX_END;
                    end if;
                                     
             end case;
        end if;
    end process spi_proc;
    
    -- Just do chip 1 for now
    cs_n <= '1';
        
end architecture behavioral;