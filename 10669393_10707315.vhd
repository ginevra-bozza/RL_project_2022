library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity project_reti_logiche is
    port (
    i_clk : in std_logic;                           --i_clk � il segnale di CLOCK in ingresso generato dal TestBench;
    i_rst : in std_logic;                           --i_rst � il segnale di RESET che inizializza la macchina pronta per ricevere il primo segnale di START;
    i_start : in std_logic;                         --i_start � il segnale di START generato dal Test Bench;
    i_data : in std_logic_vector(7 downto 0);       --i_data � il segnale (vettore) che arriva dalla memoria in seguito ad una richiesta di lettura;
    o_address : out std_logic_vector(15 downto 0);  --o_address � il segnale (vettore) di uscita che manda l'indirizzo alla memoria;
    o_done : out std_logic;                         --� il segnale di uscita che comunica la fine dell'elaborazione e il dato di uscita scritto in memoria;
    o_en : out std_logic;                           --o_en � il segnale di ENABLE da dover mandare alla memoria per poter comunicare (sia in lettura che in scrittura);
    o_we : out std_logic;                           --o_we � il segnale di WRITE ENABLE da dover mandare alla memoria (=1) per poter scriverci. Per leggere da memoria esso deve essere 0;
    o_data : out std_logic_vector (7 downto 0)      --o_data � il segnale (vettore) di uscita dal componente verso la memoria.
    );
    end project_reti_logiche;

    architecture behavioural of project_reti_logiche is
        type state_type is (zero_zero, zero_one, one_zero, one_one); --FSM da specifica
        type set_program_state is (not_started, started, computation_terminated); --Nostra FSM per gestire done e reset

        signal current_state: state_type;
        signal next_state: state_type;
        signal program_state: set_program_state;
        
        --segnali su cui lavoriamo, che vengono modificati
        signal current_y_data: std_logic_vector(15 downto 0)        := "0000000000000000";
        signal current_address_read: std_logic_vector(15 downto 0);
        signal current_address_write: std_logic_vector(15 downto 0); 
        signal intermediate_o_data: std_logic_vector(7 downto 0);
        signal intermediate_o_done: std_logic;
        signal s: bit;
        signal k_scorr: integer;
        --reset segnali di lettura e scrittura
        signal rst_address_read: std_logic_vector(15 downto 0)  := "0000000000000000";
        signal rst_address_write: std_logic_vector(15 downto 0) := "0000001111101000"; 

         function is_even(num: integer) return boolean is
            variable even : boolean;
        begin
            if((num = 0) or (num = 2) or (num = 4) or (num = 6)) then
                even := true;
            else
                even := false;
            end if;
            return even;
            
        end function;
        
        begin
            process( i_clk, i_rst ,i_start)
            begin
                if(i_rst = '1') then
                    current_address_read <= rst_address_read;
                    current_address_write <= rst_address_write;
                    o_en <= '0';
                    o_we <= '0';
                    o_data <= "00000000";
                    o_done <= '0';
                    intermediate_o_done <= '0';

                    current_state <= zero_zero;
                    program_state <= not_started;
                elsif(RISING_EDGE(i_clk)) then
                    if(i_start = '1' and intermediate_o_done = '0') then
                        program_state <= started;
                        elsif(i_start = '1' and intermediate_o_done = '1') then
                        program_state <= computation_terminated;
                        elsif(i_start = '0' and intermediate_o_done = '0') then
                        program_state <= not_started;
                        current_state <= zero_zero;
                    end if;
                end if;    
        end process;

        process( i_clk, i_rst ,i_start)
        begin
            if(program_state = started) then
                o_en <= '1';
                current_address_read <= current_address_read + "0000000000001000";
                o_address <= current_address_read;
            elsif(program_state = computation_terminated) then
                o_en <= '1';
                o_we <= '1';
                current_address_write <= current_address_write + "0000000000001000";
                o_address <= current_address_write;
            elsif(program_state = not_started) then
                o_en <= '0';
                o_we <= '0';
            end if;
        end process;

            process(intermediate_o_done)
            begin
                if(program_state = started) then
                    if(current_state = zero_zero) then
                        next_state <= current_state;
                    end if;
                    for k in 7 downto 0 loop
                        case next_state is
                            when zero_zero => 
                                if(i_data(k) = '0') then
                                    next_state <= zero_zero;
                                elsif(i_data(k) = '1') then
                                    next_state <= one_zero;
                                end if;
                            when one_zero => 
                                if(i_data(k) = '0') then
                                    next_state <= zero_one;
                                elsif(i_data(k) = '1') then
                                    next_state <= one_one;
                                end if;
                            when one_one => 
                                if(i_data(k) = '0') then
                                    next_state <= zero_one;
                                elsif(i_data(k) = '1') then
                                    next_state <= one_one;
                                end if;
                            when zero_one => 
                                if(i_data(k) = '0') then
                                    next_state <= zero_zero;
                                elsif(i_data(k) = '1') then
                                    next_state <= one_zero;
                            end if;     
                       end case;
                       k_scorr  <= k;
                    end loop;
                    intermediate_o_done <= '0';
                    o_done <= '1';
                end if;
            end process;

            process
            begin
                case next_state is
                    when zero_zero => 
                        if(i_data(k_scorr) = '0') then
                            if(is_even(k_scorr)) then 
                                current_y_data(k_scorr + k_scorr) <= '0';
                                current_y_data(k_scorr + k_scorr + 2) <= '0';
                            else
                                current_y_data(k_scorr + k_scorr - 1) <= '0';
                                current_y_data(k_scorr + k_scorr + 1) <= '0';
                                end if;
                        elsif(i_data(k_scorr) = '1') then
                            if(is_even(k_scorr)) then 
                                current_y_data(k_scorr + k_scorr) <= '1';
                                current_y_data(k_scorr + k_scorr + 2) <= '1';
                            else
                                current_y_data(k_scorr + k_scorr - 1) <= '1';
                                current_y_data(k_scorr + k_scorr + 1) <= '1';
                                end if;
                        end if;
                    when one_zero => 
                        if(i_data(k_scorr) = '0') then
                            if(is_even(k_scorr)) then 
                                current_y_data(k_scorr + k_scorr) <= '0';
                                current_y_data(k_scorr + k_scorr + 2) <= '1';
                            else
                                current_y_data(k_scorr + k_scorr - 1) <= '0';
                                current_y_data(k_scorr + k_scorr + 1) <= '1';
                            end if;
                        elsif(i_data(k_scorr) = '1') then
                            if(is_even(k_scorr)) then 
                                current_y_data(k_scorr + k_scorr) <= '1';
                                current_y_data(k_scorr + k_scorr + 2) <= '0';
                            else
                                current_y_data(k_scorr + k_scorr - 1) <= '1';
                                current_y_data(k_scorr + k_scorr + 1) <= '0';
                            end if;
                        end if;
                    when one_one => 
                        if(i_data(k_scorr) = '0') then
                            if(is_even(k_scorr)) then 
                                current_y_data(k_scorr + k_scorr) <= '1';
                                current_y_data(k_scorr + k_scorr + 2) <= '0';
                            else
                                current_y_data(k_scorr + k_scorr - 1) <= '1';
                                current_y_data(k_scorr + k_scorr + 1) <= '0';
                            end if;
                        elsif(i_data(k_scorr) = '1') then
                            if(is_even(k_scorr)) then 
                                current_y_data(k_scorr + k_scorr) <= '0';
                                current_y_data(k_scorr + k_scorr + 2) <= '1';
                            else
                                current_y_data(k_scorr + k_scorr - 1) <= '0';
                                current_y_data(k_scorr + k_scorr + 1) <= '1';
                            end if;
                        end if;
                    when zero_one => 
                        if(i_data(k_scorr) = '0') then
                            if(is_even(k_scorr)) then 
                                current_y_data(k_scorr + k_scorr) <= '1';
                                current_y_data(k_scorr + k_scorr + 2) <= '1';
                            else
                                current_y_data(k_scorr + k_scorr - 1) <= '1';
                                current_y_data(k_scorr + k_scorr + 1) <= '1';
                            end if;
                        elsif(i_data(k_scorr) = '1') then
                            if(is_even(k_scorr)) then 
                                current_y_data(k_scorr + k_scorr) <= '0';
                                current_y_data(k_scorr + k_scorr + 2) <= '0';
                            else
                                current_y_data(k_scorr + k_scorr - 1) <= '0';
                                current_y_data(k_scorr + k_scorr + 1) <= '0';
                            end if;
                    end if;     
               end case;
                end process;

            process(intermediate_o_done)
            begin
                if(program_state = computation_terminated and intermediate_o_data = "00000000") then
                    s <= '0';
                    end if;
                if(s = '0') then
                    for k in 7 downto 0 loop
                        intermediate_o_data(k) <= current_y_data(k);
                        end loop;
                o_data <= intermediate_o_data;
                elsif(s = '1') then
                    for k in 7 downto 0 loop
                        intermediate_o_data(k) <= current_y_data(k + 8);
                        end loop;
                o_data <= intermediate_o_data;  
                end if;
                if(s = '1') then
                    s <= '0';
                else
                    s <= '1';
                end if;

                o_done <= '0';
                intermediate_o_done <= '0';

            end process;
            
        end behavioural;

       

    

