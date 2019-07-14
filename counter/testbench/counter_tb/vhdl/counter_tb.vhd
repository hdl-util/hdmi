----------------------------------------------------------
-- Design  : Simple testbench for an 8-bit VHDL counter
-- Author  : Javier D. Garcia-Lasheras
----------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;			 

entity counter_tb is			-- entity declaration
end counter_tb;

-----------------------------------------------------------------------

architecture testbench of counter_tb is

    component counter
    generic(
	    cycles_per_second: integer
    );
    port(   
	    clock:	in std_logic;
	    clear:	in std_logic;
	    count:	in std_logic;
	    Q:		out std_logic_vector(7 downto 0)
    );
    end component;

    signal t_clock:     std_logic;
    signal t_clear:     std_logic;
    signal t_count:     std_logic;
    signal t_Q:         std_logic_vector(7 downto 0);

begin
    
    U_counter: counter
        generic map (cycles_per_second => 10)
        port map (t_clock, t_clear, t_count, t_Q);
	
    process				 
    begin
	t_clock <= '0';			-- clock cycle is 10 ns
	wait for 5 ns;
	t_clock <= '1';
	wait for 5 ns;
    end process;
	
    process
    begin								
			
	t_clear <= '1';			-- clear counter
	t_count <= '0';
	wait for 50 ns;	
		
	t_clear <= '0';			-- release clear
	wait for 200 ns;

	t_count <= '1';
	wait for 1000 ns;		-- start counting
	
	report "Testbench of Adder completed successfully!" 
	severity note; 
	wait;
		
    end process;

end testbench;

----------------------------------------------------------------
