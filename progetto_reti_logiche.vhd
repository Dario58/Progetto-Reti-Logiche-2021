----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.03.2021 19:35:28
-- Design Name: 
-- Module Name: progetto_reti_logiche - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package constants is
    constant sixteen_bit_zero: std_logic_vector := "0000000000000000";
    constant eight_bit_zero: std_logic_vector := "00000000";
end constants;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_arith;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use work.constants.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity datapath is
    port (
        -- entrate principali
        i_clk: in std_logic;
        i_res: in std_logic;
        i_data: in std_logic_vector (7 downto 0); -- entra nel circuito
        in_load: in std_logic; -- registro in entrata
        d_sel: in std_logic_vector (1 downto 0); -- instradamento ingresso
        i_we: in std_logic;
        -- modulo dimensione
        mux_dim_sel: in std_logic; -- seleziona il secondo operando da moltiplicare
        dim_load: in std_logic; -- load del registro dim
        mux_cont_sel: in std_logic; -- decide cosa far passare prima del sottrattore
        cont_load: in std_logic; -- load del registro cont
        -- modulo pc
        mux_pc_sel: in std_logic; -- seleziona quale indirizzo inserire nel pc
        pc_load: in std_logic; -- load del registro pc
        mux_addr_sel: in std_logic; -- decide che indirizzo mandare in memoria
        pc_iniz_load: in std_logic; -- load del registro pc iniziale
        -- modulo min max
        mux_compare_sel: in std_logic; -- seleziona quale numero confrontare
        -- modulo shift level
        delta_load: in std_logic; -- load del registro delta
        shift_lvl_load: in std_logic; -- load del registro shift_lvl
        -- modulo new value
        temp_load: in std_logic; -- load registro temp
        new_value_load: in std_logic; -- load registro new value
        -- uscite
        o_data : out std_logic_vector (7 downto 0); -- esce per andare in memoria
        o_address: out std_logic_vector(15 downto 0); -- indirizzo attuale
        o_zero: out std_logic; -- =1 <==> il contatore raggiunge lo 0
        o_done : out std_logic
    );
end datapath;

architecture Behavioral of datapath is
    -- registri
    signal in_reg: std_logic_vector(7 downto 0);
    signal pc_reg: std_logic_vector(15 downto 0);
    signal pc_iniz_reg: std_logic_vector(15 downto 0);
    signal dim_reg: std_logic_vector(15 downto 0);
    signal counter_reg: std_logic_vector(15 downto 0);
    signal max_reg: std_logic_vector(7 downto 0);
    signal min_reg: std_logic_vector(7 downto 0);
    signal delta_reg: std_logic_vector(7 downto 0);
    signal shift_lvl_reg: std_logic_vector(3 downto 0);
    signal temp_reg: std_logic_vector(15 downto 0);
    signal new_value_reg: std_logic_vector(7 downto 0);
    signal sign_extension: std_logic_vector(15 downto 0);
    signal log_value: std_logic_vector(3 downto 0);
    
begin

    process(i_clk, i_res)
    begin
    
        if(i_res = '1') then
            
            in_reg <= eight_bit_zero;
            pc_reg <= sixteen_bit_zero;
            pc_iniz_reg <= sixteen_bit_zero;
            dim_reg <= sixteen_bit_zero;
            counter_reg <= sixteen_bit_zero;
            max_reg <= eight_bit_zero;
            min_reg <= eight_bit_zero;
            delta_reg <= eight_bit_zero;
            shift_lvl_reg <= "0000";
            temp_reg <= eight_bit_zero;
            new_value_reg <= eight_bit_zero; 
             
        elsif(i_clk'event and i_clk='1') then
            
            -- gestione pc
            if(pc_load = '1') then
                if(mux_pc_sel = '1') then
                    pc_reg <= pc_iniz_reg;
                elsif(mux_pc_sel = '0') then
                    pc_reg <= pc_reg + 1;
                end if;
            end if;
            
            if(pc_iniz_load = '1') then
                pc_iniz_reg <= pc_reg;
            end if;
            
            -- carico registro iniziale
            if(in_load = '1') then
                in_reg <= i_data;
            end if;
            
            -- carico contatore
            if(cont_load = '1') then
                if(mux_cont_sel = '1') then
                    counter_reg <= counter_reg - 1;
                elsif(mux_cont_sel = '0') then
                    counter_reg <= dim_reg - 1;
                end if;
            end if;
            
            -- segnale zero
            if(counter_reg = sixteen_bit_zero) then
                o_zero <= '1';
            end if;
            
            --------------------- uscite demux ----------------------------
            if(d_sel = "00") then -- CASO 00
                if(dim_load = '1') then
                    if(mux_dim_sel = '0') then
                        dim_reg <= in_reg;
                    elsif(mux_dim_sel = '1') then
                        dim_reg <= std_logic_vector(unsigned(i_data) * unsigned(dim_reg));
                    end if; 
                end if;
            -- 
            --   
            elsif(d_sel = "01") then -- CASO 01
                if(mux_compare_sel = '0') then
                    if(in_reg > 0) then
                        max_reg <= in_reg;
                    end if;
                    if(in_reg <= 255) then
                        min_reg <= in_reg;
                    end if;
                    
                elsif(mux_compare_sel = '1') then
                    if(in_reg > max_reg) then
                        max_reg <= in_reg;
                    end if;
                    if(in_reg <= min_reg) then
                        min_reg <= in_reg;
                    end if;
                end if;
            --
            --    
            elsif(d_sel = "10") then -- CASO 10
                sign_extension <= "00000000" & (in_reg - min_reg); 
            end if;
            ---------------------------------------------------------------
            
            --shift level
            if(delta_load = '1') then
                delta_reg <= max_reg - min_reg;
            end if;
            
            if(delta_reg = 0) then
                log_value <= "0000";
            elsif(delta_reg = 1 or delta_reg = 2) then
                log_value <= "0001";
            elsif(delta_reg > 2 and delta_reg < 7) then
                log_value <= "0010";
            elsif(delta_reg > 6 and delta_reg < 15) then
                log_value <= "0011";
            elsif(delta_reg > 14 and delta_reg  < 31) then
                log_value <= "0100";
            elsif(delta_reg > 30 and delta_reg  < 63) then
                log_value <= "0101";
            elsif(delta_reg > 62 and delta_reg  < 127) then
                log_value <= "0110";
            elsif(delta_reg > 126 and delta_reg  < 255) then
                log_value <= "0111";
            elsif(delta_reg = 255) then
                log_value <= "1000";
            end if;
 
            if(shift_lvl_load = '1') then
                shift_lvl_reg <= 8 - log_value;
            end if;
            
            -- creazione di temp
            if(temp_load = '1') then
                temp_reg <= std_logic_vector(shift_left(unsigned(sign_extension), to_integer(unsigned(shift_lvl_reg))));
            end if;
            
            -- new value
            if(new_value_load = '1') then
                if(temp_reg > "0000000011111111") then
                    new_value_reg <= "11111111";
                else new_value_reg <= temp_reg(7 downto 0);
                end if;
            end if;
            
            if(i_we = '1') then
                o_address <= pc_reg + dim_reg;
            elsif(i_we = '0') then
                o_address <= pc_reg;
            end if;
            
        end if;    
    end process;
    
    o_data <= new_value_reg;
    
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith;
use work.constants.all;

entity progetto_reti_logiche is
    port ( 
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    );
end progetto_reti_logiche;

architecture Behavioral of progetto_reti_logiche is
        
    component datapath is
        port (
            -- entrate principali
            i_clk: in std_logic;
            i_res: in std_logic;
            i_data: in std_logic_vector (7 downto 0);
            in_load: in std_logic;
            d_sel: in std_logic_vector (1 downto 0);
            i_we: in std_logic;
            -- modulo dimensione
            mux_dim_sel: in std_logic;
            dim_load: in std_logic;
            mux_cont_sel: in std_logic;
            cont_load: in std_logic;
            -- modulo pc
            mux_pc_sel: in std_logic;
            pc_load: in std_logic;
            mux_addr_sel: in std_logic;
            pc_iniz_load: in std_logic;
            -- modulo min max
            mux_compare_sel: in std_logic;
            -- modulo shift level
            delta_load: in std_logic;
            shift_lvl_load: in std_logic;
            -- modulo new value
            temp_load: in std_logic;
            new_value_load: in std_logic;
            -- uscite
            o_data : out std_logic_vector (7 downto 0); 
            o_address: out std_logic_vector(15 downto 0);
            o_zero: out std_logic;
            o_done : out std_logic
        );
    end component;
    
    type S is (RESET_STATE, S1, S2, S3, S4, S5, S6, S7, S8, 
               S9, S10, S11, S12, S13, S14);
    
    signal current_state: S; -- stato corrente
    signal next_state: S; -- stato successivo
    signal in_load: std_logic;
    signal d_sel: std_logic_vector(1 downto 0);
    signal i_we: std_logic;
    signal mux_dim_sel: std_logic;
    signal dim_load: std_logic;
    signal mux_cont_sel: std_logic;
    signal cont_load: std_logic;
    signal mux_pc_sel: std_logic;
    signal pc_load: std_logic;
    signal mux_addr_sel: std_logic;
    signal pc_iniz_load: std_logic;
    signal mux_compare_sel: std_logic;
    signal delta_load: std_logic;
    signal shift_lvl_load: std_logic;
    signal temp_load: std_logic;
    signal new_value_load: std_logic;
    signal o_zero: std_logic;

begin
    
    DATAPATH0: datapath port map(     -- mappa i segnali con i nomi originali
        i_clk,
        i_rst,
        i_data,
        in_load,
        d_sel,
        i_we,
        mux_dim_sel,
        dim_load,
        mux_cont_sel,
        cont_load,
        mux_pc_sel,
        pc_load,
        mux_addr_sel,
        pc_iniz_load,
        mux_compare_sel,
        delta_load,
        shift_lvl_load,
        temp_load,
        new_value_load,
        o_data,
        o_address,
        o_zero,
        o_done
    );

    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            current_state <= RESET_STATE;
        elsif rising_edge(i_clk) then       -- commuta sul fronte di salita
            current_state <= next_state;
        end if;
    end process;

    process(current_state, i_start, o_done)
    begin
        next_state <= current_state;
        case current_state is
            when RESET_STATE =>
                if i_start = '1' then
                    next_state <= S1;
                end if;
            when S1 =>
                next_state <= S2;
            when S2 =>
                next_state <= S3;
            when S3 =>
                next_state <= S4;
            when S4 =>                  -- inizio scansione per trovare MIN e MAX
                if o_zero = '1' then    -- caso DIM=1
                    next_state <= S7;
                else                    -- caso DIM>1
                    next_state <= S5;
                end if;
            when S5 =>
                if o_zero = '1' then    -- fine scansione
                    next_state <= S6;
                else                    -- scansione ancora in corso
                    next_state <= S5;
                end if;
            when S6 =>                  -- scansione completata, MAX e MIN trovati, calcolo DELTA
                next_state <= S7;
            when S7 =>
                next_state <= S8;
            when S8 =>
                next_state <= S9;
            when S9 =>
                next_state <= S10;
            when S10 =>
                next_state <= S11;
            when S11 =>
                if o_zero = '1' then    -- computazione e scrittura completata per ogni pixel
                    next_state <= S13;
                else                    -- passa al pixel successivo
                    next_state <= S12;
                end if;
            when S12 =>
                next_state <= S9;
            when S13 =>                 
                next_state <= S14;   
            when S14 =>              -- stato finale in attesa di nuovo start
                if start = '1' then
                    next_state <= S1    -- non torna in RESET_STATE perchè il PC non deve essere resettato all'indirizzo 0
                else
                    next_state <= S14;
                end if;
        end case;
    end process;
            
    process(current_state)      -- gestisce i segnali degli stati della fsm
            begin
                -- inizializzazione dei segnali
                pc_load <= '1';
                pc0_load <= '0';
                in_load <= '0';
                dim_load <= '0';
                cont_load <= '0';
                -- delta_load <= '0';   --  inutile
                sl_load <= '0';
                temp_load <= '0';
                nv_load <= '0';
                d_sel <= '00';
                mdim_sel <= '0';
                mcont_sel <= '0';
                minmax_sel <= '0';
                mpc_sel <= '00'
                en <= '0';
                we <= '0';
                o_done <= '0';
                
                case current_state is
                    when RESET_STATE =>     -- non cambio nulla, tutto è già stato inizializzato
                    when S1 =>              -- leggo da memoria il primo byte
                        en <= '1';
                        mpc_sel <= '01';
                        pc_load <= '1';
                        in_load <= '1';
                        dim_load <= '1';    -- DIM=1 temporaneamente
                    when S2 =>              -- leggo da memoria il secondo byte
                        mdim_sel <= '1';
                    when S3 =>              -- calcolo la dimensione, leggo il primo pixel di cui salvo l'indirizzo in PC0
                        pc0_load <= '1';
                        pc_load <= '0';
                    when S4 =>              -- indirizzo il primo byte letto nel modulo MIN/MAX e inizializzo il contatore
                        en <= '0';
                        in_load <= '0';
                        pc0_load <= '0';
                        pc_load <= '1';
                        cont_load <= '1';
                        d_sel <= '01';
                    when S5 =>              -- leggo e confronto i valori di tutti i pixel rimanenti
                        en <= '1';
                        in_load <= '1';
                        mm_sel <= '1';
                        mcont_sel <= '1';
                    when S6 =>              -- lascio che nel modulo MAX/MIN venga confrontato anche l'ultimo pixel
                        en <= '0';
                        in_load <= '0';
                        cont_load <= '0';
                    when S7 =>              -- carico nel PC l'indirizzo PC0 del primo pixel
                        mpc_sel <= '10';
                        pc_load <= '1';
                        sl_load <= '1';
                        cont_load <= '0';
                    when S8 =>              -- resetto il contatore a DIM
                        en <= '1';
                        in_load <= '1';
                        pc_load <= '0';
                        sl_load <= '0';
                        mcont_sel <= '0';
                    when S9 =>              -- calcolo il valore temporaneo
                        en <= '0';
                        in_load <= '1';
                        temp_load <= '1';
                        cont_load <= '0';
                    when S10 =>             -- definisco il valore finale da scrivere
                        temp_load <= '0';
                        nv_load <= '1';
                    when S11 =>             -- scrivo in memoria il valore calcolato all'indirizzo di memoria a distanza DIM da quello del pixel letto
                        en <= '1';
                        we <= '1';
                        mpc_sel <= '01';
                        pc_load <= '1';
                        nv_load <= '0';
                    when S12 =>             -- leggo il byte successivo e aggiorno il contatore
                        we <= '0';
                        in_load <= '1';
                        pc_load <= '0';
                        mcont_sel <= '1';
                        cont_load <= '1';
                    when S13 =>             -- resetto tutti i segnali e alzo il segnale DONE. PC è già l'indirizzo del primo byte della prossima immagine
                        en <= '0';
                        we <= '0';
                        in_load <= '0';
                        pc_load <= '0';
                        sl_load <= '0';
                        pc0_load <= '0';
                        temp_load <= '0';
                        nv_load <= '0';
                        cont_load <= '0';
                        o_done <= '1';
                    when S14 =>             -- quando si abbassa START posso riabbassare DONE
                        o_done <= '0';
                end case;
    end process;
                
end Behavioral;
