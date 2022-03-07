-- File: spi_tb.vhd
-- Description: Test bench for simple SPI controller implementation
-- Author: Katie Long

-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.all;

entity spi_tb is
generic (
    DATA_WIDTH  : integer := 8;
    ADDRESS_LEN : integer := 128   
);
end entity spi_tb;

architecture tb of spi_tb is
    
    -- test bench signals
    signal clk_t : std_logic := '0';
    signal rst_t : std_logic := '0';
    signal clk_period : time := 20 ns;
    signal rcvd : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal capture_en : std_logic := '0';   -- used for TB: enable MOSI capture;
    
    -- RAM signals
    signal waddr_t, raddr_t, data_t, wdata_t : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal wren_t : std_logic := '0';
    
    -- SPI signals
    signal mosi, miso, tx_en, tx_done   : std_logic := '0';
    signal cs_n                         : std_logic := '1';
    signal sclk                         : std_logic := '0'; 
    
begin
    
    -- Generate a 50 MHz clock
    clk_gen : process
    begin
        clk_t <= not clk_t;
        wait for clk_period / 2;
    end process clk_gen;
   
    -- Very simple dual mode ram. See initram.txt/initram_bin.txt for contents.
    dut_ram : entity work.ram
    port map (
        clk => clk_t,
        rst_n => rst_t,
        wdata => wdata_t,
        waddr => waddr_t,
        raddr => raddr_t,
        wren => wren_t,
        data => data_t
    );
    
    -- SPI controller
    dut_spi : entity work.spi_controller
    port map(
        clk   => clk_t,
        rst_n => rst_t,
        data  => data_t,
        mosi  => mosi,
        miso  => miso,
        tx_en => tx_en,
        tx_done => tx_done,
        cs_n  => cs_n,
        sclk  => sclk
    );
    
    
    stim_proc : process
    begin
        
        wait for clk_period;
        rst_t <= '1';
        
        -- Test sending all data from RAM.
        for i in 0 to ADDRESS_LEN-1 loop
            raddr_t <= std_logic_vector(to_unsigned(i, raddr_t'length));
                
            wait for clk_period;
            capture_en <= '1';
            tx_en <= '1';
            
            wait for clk_period;
            tx_en <= '0';
        
            wait until rising_edge(tx_done);
            
            report "TX " & integer'image(i) & " is complete. Time: " & time'image(now) severity note; 
            if (rcvd /= data_t) then
                assert false report "ERROR: rcvd doesn't match expected." severity error;
            end if;
            
            -- reset the TB MOSI capture block
            capture_en <= '0'; 
        end loop;
         
        wait for 20 ns;
        assert false report "Sim complete" severity failure;        
        
    end process stim_proc;
    
    -- Capture the MOSI output for validation
    capture_proc : process(sclk, capture_en)
        variable bit : integer := DATA_WIDTH - 1;
    begin
        if (capture_en = '0') then
            bit := DATA_WIDTH - 1;
            rcvd <= (others => '0');
        elsif (rising_edge(sclk)) then
            rcvd(bit) <= mosi;
            bit := bit - 1;
        end if;
    end process capture_proc;
        
end architecture tb;