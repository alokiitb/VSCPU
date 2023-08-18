library ieee;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
entity vscpu is

generic (vscpu_add_width: integer:=8;vscpu_data_width:integer:=16;
			pc_starts_at:std_logic_vector (7 downto 0) :="00000001");

port(clk,reset,start,write1: in std_logic;
		addr: in std_logic_vector((vscpu_add_width)-1 downto 0);
		data:in std_logic_vector((vscpu_data_width)-1 downto 0));
		--status: out std_logic);
end vscpu;

architecture behav of vscpu is
type tan_t is array (0 to 15) of std_logic_vector(15 downto 0);

constant memsize:integer:=(2**(vscpu_add_width)-1);
constant instr_add: std_logic_vector(7 downto 0):= "00000000"; 
constant instr_and:std_logic_vector(7 downto 0):="00000001"; 
constant instr_jmp:std_logic_vector(7 downto 0):="00000010";
constant instr_inc:std_logic_vector(7 downto 0):="00000011";
constant instr_store:std_logic_vector(7 downto 0):="00000100";
constant instr_sub:std_logic_vector(7 downto 0):="00000101";
constant instr_mul:std_logic_vector(7 downto 0):="00000110";
constant instr_load:std_logic_vector(7 downto 0):="00000111";
constant instr_decr:std_logic_vector(7 downto 0):="00001000";
constant instr_cordic :std_logic_vector(7 downto 0):="00001001";
constant tan:tan_t:=("0011001001000100","0001110110101100","0000111110101110","0000011111110101","0000001111111111","0000001000000000","0000000100000000","0000000010000000","0000000001000000","0000000000100000","0000000000010000","0000000000001000","0000000000000100","0000000000000010","0000000000000001","0000000000000000");

--values for cordic calculation 


constant st_fetch1: std_logic_vector(7 downto 0):="00000001";
constant st_fetch2: std_logic_vector(7 downto 0):="00000010";
constant st_fetch3: std_logic_vector(7 downto 0):="00000011";
constant st_add1: std_logic_vector(7 downto 0):="00000100";
constant st_add2: std_logic_vector(7 downto 0):="00000101";
constant st_and1: std_logic_vector(7 downto 0):="00000110";
constant st_and2: std_logic_vector(7 downto 0):="00000111";
constant st_jmp1: std_logic_vector(7 downto 0):="00001000";
constant st_inc1: std_logic_vector(7 downto 0):="00001001";
constant st_store1: std_logic_vector(7 downto 0):="00001010";
constant st_halt: std_logic_vector(7 downto 0):="00111111";
constant st_sub1: std_logic_vector(7 downto 0):="00001011";
constant st_sub2: std_logic_vector(7 downto 0):="00001100";
constant st_mul1: std_logic_vector(7 downto 0):="00001110";
constant st_mul2: std_logic_vector(7 downto 0):="00001111";
constant st_load1:std_logic_vector(7 downto 0):="00010000";
constant st_decr1:std_logic_vector(7 downto 0):="00010001";

constant st_cord1:std_logic_vector(7 downto 0):="00010010";
constant st_cord2:std_logic_vector(7 downto 0):="00010011";



type t_mem is array (0 to memsize) of std_logic_vector((vscpu_data_width)-1 downto 0);
signal mem:t_mem;

signal read1,mem_write: std_logic; signal dbus: std_logic_vector((vscpu_data_width)-1 downto 0);
signal address,ar_ff,pc_ff,ar_ns,pc_ns: std_logic_vector((vscpu_add_width)-1 downto 0);
signal ac_ff,ac_ns: std_logic_vector(15 downto 0);
signal dr_ff,dr_ns:std_logic_vector((vscpu_data_width)-1 downto 0);
signal ir_ff,ir_ns,stvar_ff,stvar_ns:std_logic_vector(7 downto 0); 

signal start_cordic:std_logic:='0';
signal sine_cos:std_logic:='0'; --default sine is calculated
signal xr,yr,zr,s,c:std_logic_vector(15 downto 0):="0000000000000000";
signal count:integer:=0;
begin
process(clk,reset,ac_ns,pc_ns,ir_ns,dr_ns)
begin
	if(rising_edge(clk)) then 
		if(reset='1') then
			ar_ff<=(others=> '0');ac_ff<=(others=> '0');dr_ff<=(others=> '0');ir_ff<=(others=> '0');pc_ff<=pc_starts_at;
		else
			ar_ff<=ar_ns;ac_ff<=ac_ns;dr_ff<=dr_ns;ir_ff<=ir_ns;pc_ff<=pc_ns;
		end  if;
	end if;
end process;

process(clk)
begin
	if(rising_edge(clk)) then 
		if(reset='1') then
			stvar_ff<=st_halt;
		elsif(start='1') then
			stvar_ff<=st_fetch1;
		else stvar_ff<=stvar_ns;
		end if;
	end if;
end process;

process(stvar_ff,ir_ff)
begin
	stvar_ns<= stvar_ff;
	case(stvar_ff) is
		when st_halt=> stvar_ns<= st_halt;
		when st_fetch1=> stvar_ns<= st_fetch2;
		when st_fetch2=> stvar_ns<= st_fetch3;
		when st_fetch3 => 
			case(ir_ff) is
				when instr_add=> stvar_ns<=st_add1;
				when instr_and=> stvar_ns<=st_and1;
				when instr_jmp=> stvar_ns<=st_jmp1;
				when instr_inc=> stvar_ns<=st_inc1;
				when instr_store=> stvar_ns<=st_store1;
				when instr_mul=> stvar_ns<=st_mul1;
				when instr_sub=> stvar_ns<=st_sub1;
				when instr_load=> stvar_ns<=st_load1;
				when instr_decr=> stvar_ns<=st_decr1;
				when instr_cordic=>stvar_ns<=st_cord1;

				when others => null ;
			end case;
		when st_add1=>  stvar_ns<=st_add2;
		when st_and1=>  stvar_ns<=st_and2;
		when st_jmp1=>  stvar_ns<=st_fetch1;
		when st_inc1=>  stvar_ns<=st_fetch1;
		when st_store1=>  stvar_ns<=st_fetch1;
		when st_add2=>  stvar_ns<=st_fetch1;
		when st_and2=>  stvar_ns<=st_fetch1;
		when st_sub1=>  stvar_ns<=st_sub2;
		when st_sub2=>  stvar_ns<=st_fetch1;
		when st_mul1=>  stvar_ns<=st_mul2;
		when st_mul2=>  stvar_ns<=st_fetch1;
		when st_load1=>  stvar_ns<=st_fetch1;
		when st_decr1=>  stvar_ns<=st_fetch1;
		when st_cord1=>stvar_ns<=st_cord2;
		when others => null ;
	end case;
end process;


process(stvar_ff,ir_ff,ar_ff,pc_ff,dr_ff,ac_ff,dr_ns,dbus,mem_write)

begin
	ar_ns<=ar_ff;ac_ns<=ac_ff;dr_ns<=dr_ff;ir_ns<=ir_ff;pc_ns<=pc_ff;
	case(stvar_ff) is
		when st_fetch1=> ar_ns<=pc_ff;
		when st_fetch2=>
			pc_ns<= std_logic_vector(unsigned(pc_ff)+1);dr_ns<= dbus;
			ir_ns<= dr_ns((vscpu_data_width)-1 downto (vscpu_data_width)-8);
			ar_ns<= dr_ns((vscpu_data_width)-9 downto 0);
		when st_fetch3=>null;
			when (st_add1) => dr_ns<=dbus;
			when(st_add2) => ac_ns<= std_logic_vector(unsigned(ac_ff)+ unsigned(dr_ff));
			when(st_and1) => dr_ns<=dbus;
			when(st_and2) => ac_ns<= ac_ff and dr_ff;
			when(st_jmp1) => pc_ns<= dr_ff((vscpu_data_width)-9 downto 0);
			when(st_inc1) => ac_ns<=std_logic_vector(unsigned(ac_ff)+1);
			when(st_sub1) => dr_ns<= dbus;
			when(st_sub2) => ac_ns<=std_logic_vector(unsigned(ac_ff)-unsigned(dr_ff));
			when(st_mul1) => dr_ns<= dbus;
			when(st_mul2) => ac_ns<=std_logic_vector(unsigned(ac_ff(7 downto 0))*unsigned(dr_ff(7 downto 0)));
			when(st_load1) => ac_ns<=dbus ;
			when(st_decr1) => ac_ns<=std_logic_vector(unsigned(ac_ff)-1);
			when(st_cord1)=>dr_ns<=dbus;
								start_cordic<='1';
			when(st_cord2)=>
								if(start_cordic='1') then
									zr<=ac_ff;
									if(count<=15)then
										if(zr(15)='0')then
											xr<=std_logic_vector(signed(xr)-signed((shift_right(unsigned(yr),count))));
											yr<=std_logic_vector(signed(yr)+signed((shift_right(unsigned(xr),count))));
											zr<=std_logic_vector(signed(zr)-signed(tan(count)));
										else
											xr<=std_logic_vector(signed(xr)+signed((shift_right(unsigned(yr),count))));
											yr<=std_logic_vector(signed(yr)-signed((shift_right(unsigned(xr),count))));
											zr<=std_logic_vector(signed(zr)+signed(tan(count)));
										end if;
										count<=count+1;
									else
										s<=xr;
									end if;
								end if;
								ac_ns<=xr;
								start_cordic<='0';
									
			when others=> null;
	end case;
end process;

--Memory block--
address <= addr when (stvar_ff = st_halt ) else ar_ff ;
process(clk,reset,read1,write1)
begin
	if(rising_edge(clk)) then
	if(reset='1') then
	mem<=(others=>(others=>'0'));
	elsif ((write1 and (not read1))='1') then
		mem(to_integer(unsigned(address)))<=data;
	elsif (mem_write='1' and read1='0') then
		mem(to_integer(unsigned(address)))<=dbus;
	end if;
	end if;
end process;

dbus<= mem(to_integer(unsigned(address))) when ((read1 and (not write1))='1') 
else ac_ff when ((mem_write and (not read1))='1')
else (others=>'Z');

process(clk,reset,start)
begin
	if(rising_edge(clk)) then
		if(reset='1') then
			stvar_ff <= st_halt;
		elsif(start='1') then
			stvar_ff <= st_fetch1;
		else stvar_ff <= stvar_ns ;
		end if;
	end if;
end process;
--------------------------
---control path---
process(stvar_ff,pc_ff,ac_ff,dr_ff,ir_ff,ar_ff)
begin
if ( (stvar_ff= st_fetch2) or (stvar_ff=st_add1) or (stvar_ff=st_and1) or (stvar_ff=st_sub1) or(stvar_ff=st_mul1) or (stvar_ff=st_load1) ) then
 read1 <= '1' ;mem_write<='0';
 elsif(stvar_ff=st_store1) then mem_write<='1'; read1<='0';
 else read1 <= '0' ;mem_write<='0';
end if;
 end process;
 
 
 
end behav;