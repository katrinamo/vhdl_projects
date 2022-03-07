-- File: simple_ram.vhd
-- Description: Simple 1 KB ram memory to use for test bench. Data changes
-- on the falling edge of the serial clock.
-- Author: Katie Long

-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TXT and IO libraries
use ieee.std_logic_textio.all;

use std.textio.all;

entity ram is
generic (
    DATA_WIDTH      : integer := 8;
    ADDRESS_LEN     : integer := 128
);
port (
    clk             : in std_logic;
    rst_n           : in std_logic;
    wdata           : in std_logic_vector(DATA_WIDTH-1 downto 0);
    waddr, raddr    : in std_logic_vector(DATA_WIDTH-1 downto 0);
    wren            : in std_logic; 
    data            : out std_logic_vector(DATA_WIDTH-1 downto 0)
);
end entity ram;

architecture RTL of ram is
    type ram_type is array(0 to ADDRESS_LEN-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
        
    -- For test bench, initialize the ram with some dummy values.
    -- This function is based off of:
    --     https://www.fpga4student.com/2018/08/how-to-read-image-in-vhdl.html
    impure function initram(filename : in string) return ram_type is
        file ram_file       : text open read_mode is filename;
        variable txt_line   : line;
        variable txt_bit    : bit_vector(DATA_WIDTH-1 downto 0);
        variable ram_out    : ram_type;
    begin
        for i in ram_type'range loop
            readline(ram_file, txt_line);
            read(txt_line, txt_bit);
            ram_out(i) := to_stdlogicvector(txt_bit);
        end loop;
        return ram_out;
    end function;
    
    signal ram : ram_type := initram("initram_bin.txt");
begin
    
    -- Main process
    main_proc : process(clk, rst_n)
    begin
        if (rst_n = '0') then
            data <= (others => '0');
        elsif (rising_edge(clk)) then
            if (wren = '1') then
                ram(to_integer(unsigned(waddr))) <= wdata;
            end if;
            data <= ram(to_integer(unsigned(raddr)));
        end if;        
    end process main_proc;    
end architecture RTL;
