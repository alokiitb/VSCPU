library ieee ; use ieee.std_logic_1164.all ;

entity vscputb is end entity ;
architecture stim of vscputb is 

  constant INSTR_add : std_logic_vector( 7 downto 0 ) := "00000000" ;
  constant INSTR_and : std_logic_vector( 7 downto 0 ) := "00000001" ;
  constant INSTR_jmp : std_logic_vector( 7 downto 0 ) := "00000010" ;
  constant INSTR_inc : std_logic_vector( 7 downto 0 ) := "00000011" ;
  constant INSTR_store : std_logic_vector( 7 downto 0 ) := "00000100" ;
  constant INSTR_sub : std_logic_vector( 7 downto 0 ) := "00000101" ;
  constant INSTR_mul : std_logic_vector( 7 downto 0 ) := "00000110" ;
  constant INSTR_load : std_logic_vector( 7 downto 0 ) := "00000111" ;
  constant INSTR_decr : std_logic_vector( 7 downto 0 ) := "00001000" ;
  


  constant A_WIDTH : integer := 8 ; 
  constant D_WIDTH : integer := 16 ;
  
  signal clk , reset , start , write_en : std_logic:='0' ;
  signal addr : std_logic_vector( A_WIDTH-1 downto 0 ) ; 
  signal data : std_logic_vector ( D_WIDTH-1 downto 0 ) ;
  --signal status : std_logic ;

  procedure do_synch_active_high_half_pulse ( 
      signal formal_p_clk : in std_logic ; 
      signal formal_p_sig : out std_logic 
    ) is
  begin
    wait until formal_p_clk='0' ;  formal_p_sig <= '1' ;
    wait until formal_p_clk='1' ;  formal_p_sig <= '0' ;
  end procedure ;

  procedure do_program ( 
      signal formal_p_clk : in std_logic ; 
      signal formal_p_write_en : out std_logic ; 
      signal formal_p_addr_out , formal_p_data_out : out std_logic_vector ;
      formal_p_ADDRESS_in , formal_p_DATA_in : in std_logic_vector     
    ) is
  begin
    wait until formal_p_clk='0' ;  formal_p_write_en <= '1' ;
    formal_p_addr_out <= formal_p_ADDRESS_in ; 
    formal_p_data_out <= formal_p_DATA_in ;
    wait until formal_p_clk='1' ;  formal_p_write_en <='0' ;
  end procedure ;

begin

  dut_vscpu : entity work.vscpu( behav )
      port map ( clk => clk , reset => reset , start => start ,
             write1 => write_en , addr => addr  , data => data ) ;
             
  process begin
    clk <= '0' ;
    for i in 0 to 99 loop 
      wait for 1 ns ; clk <= '1' ;  wait for 1 ns ; clk <= '0';
    end loop ;
    wait;
  end process ;

  
  process begin
    reset <= '0' ;  start <= '0' ; write_en <= '0' ;
    addr <= "00000000" ;  data <= "0000000000000000" ;
    do_synch_active_high_half_pulse ( clk, reset ) ; -- acc=0
	 do_program ( clk, write_en, addr, data, "00000001" , INSTR_load & "00" & "010000"  ) ; 
    -- acc<=mem[16]
    do_program ( clk, write_en, addr, data, "00000010" , INSTR_add & "00" & "010001"  ) ; 
   -- LABEL1 acc += mem [ 17 ]
    do_program ( clk, write_en, addr, data, "00000011" , INSTR_store & "00" & "010010"  ) ; 
    -- store to mem[18]
    do_program ( clk, write_en, addr, data, "00000100" , INSTR_and & "00" & "010011"  ) ; 
--    -- acc &= mem [ 19 ]
    do_program ( clk, write_en, addr, data, "00000101" , INSTR_inc & "00" & "010100"  ) ; 
--    -- acc += 1  
    do_program ( clk, write_en, addr, data, "00000110" , INSTR_sub & "00" & "010110"  ) ; 
--    -- acc-= mem[22]
	 do_program ( clk, write_en, addr, data, "00000111" , INSTR_mul & "00" & "010111"  ) ; 
--    -- acc=* mem[23]
	 do_program ( clk, write_en, addr, data, "00001000" , INSTR_decr & "00" & "011000"  ) ; 
--    -- acc -= 1
	 do_program ( clk, write_en, addr, data, "00001001" , INSTR_jmp & "00" & "010101"  ) ; 
--    -- jmp to ADDRESS-HEX[00010101]= 15
	 do_program ( clk, write_en, addr, data, "00010000" , X"0016"  ) ; -- mem[ 16 ]
    do_program ( clk, write_en, addr, data, "00010001" , X"0039"  ) ; -- mem[ 17 ]
	 do_program ( clk, write_en, addr, data, "00010011" , X"0002"  ) ; -- mem[ 19 ]
--	 do_program ( clk, write_en, addr, data, "00010101" , X"0055"  ) ; -- mem[ 21 ]
	 do_program ( clk, write_en, addr, data, "00010110" , X"0001"  ) ; -- mem[ 22 ]
	 do_program ( clk, write_en, addr, data, "00010111" , X"0016"  ) ; -- mem[ 23 ]


    do_synch_active_high_half_pulse ( clk, start ) ; 
    wait ;
  end process ;
end architecture ;