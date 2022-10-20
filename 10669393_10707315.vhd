library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
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
        type state_type is (RST, START, R_NUM, START_READ, DONE, WRITE_FIRST, DIV_WORD, WRITE_SECOND, zero_zero, zero_one, one_zero, one_one); --FSM da specifica

        signal current_state: state_type;
        signal next_state: state_type;
        signal cur_fsm_state: state_type;
        --signal program_state: set_program_state;
        
        --segnali su cui lavoriamo, che vengono modificati
        signal current_address_read: std_logic_vector(15 downto 0) :=  "0000000000000000";
        signal current_address_write: std_logic_vector(15 downto 0) := "0000001111101000"; 
        signal num_of_word: integer := 0;
        signal now_counter: integer := 0;
        signal first_o_data_done: boolean:= false;
        signal check_errors: boolean:= false;
        signal check_errors_signals_process: boolean:= false;
        


        signal i_data_elab: std_logic_vector(1 downto 0);
        signal counter_i_data: integer := 0 ;
        signal counter_i_data_for_signals: integer := 0 ;
        signal current_word : std_logic_vector(0 to 7):= "00000000";
        signal R0,R1,R2,R3,R4,R5,R6,R7 : std_logic_vector(0 to 1) := "00"; 
        
        --reset segnali di lettura e scrittura
        signal rst_address_read: std_logic_vector(15 downto 0)  := "0000000000000000";
        signal rst_address_write: std_logic_vector(15 downto 0) := "0000001111101000"; 

        
        begin
            
            logical_process: process(i_rst,i_start,current_address_read,current_address_write,
            check_errors,num_of_word,now_counter,first_o_data_done,i_data_elab,counter_i_data,current_word,current_state,rst_address_read,rst_address_write)
            begin
                case current_state is
                    when RST =>
                        if(i_start = '1') then 
                            next_state <= START;
                            cur_fsm_state <= zero_zero;
                        else
                            next_state <= current_state;
                        end if;
                    when START =>
                        next_state <= R_NUM;
                   
                    when R_NUM =>
                        next_state <= START_READ;

                    when START_READ =>
                    next_state <= cur_fsm_state;
                    
                    when zero_zero => 
                        cur_fsm_state <= zero_zero;
                        
                        if(counter_i_data = 8) then
                            next_state <= DIV_WORD;
                        elsif(current_word(counter_i_data) = '0') then
                            next_state <= zero_zero;
                        elsif(current_word(counter_i_data) = '1') then
                            next_state <= one_zero;
                        else
                            next_state <= current_state;
                        end if;

                        

                    when one_zero => 
                        cur_fsm_state <= one_zero;

                        counter_i_data <= counter_i_data + 1;
                        if(counter_i_data = 8) then
                            next_state <= DIV_WORD;
                        elsif(current_word(counter_i_data) = '0') then
                            next_state <= zero_one;
                        elsif(current_word(counter_i_data) = '1') then
                            next_state <= one_one;
                        else
                        next_state <= current_state;
                        end if;
                    
                    when one_one => 
                        cur_fsm_state <= one_one;

                        if(counter_i_data = 8) then
                            next_state <= DIV_WORD;
                        elsif(current_word(counter_i_data) = '0') then
                            next_state <= zero_one;
                        elsif(current_word(counter_i_data) = '1') then
                            next_state <= one_one;
                        else
                        next_state <= current_state;
                        end if;


                    when zero_one => 
                        cur_fsm_state <= zero_one;

                        if(counter_i_data = 8) then
                        next_state <= DIV_WORD;
                        elsif(current_word(counter_i_data) = '0') then
                            next_state <= zero_zero;
                        elsif(current_word(counter_i_data) = '1') then
                            next_state <= one_zero;
                        else
                        next_state <= current_state;
                        end if;
                    
                    when DIV_WORD =>
                        if(now_counter = num_of_word) then
                            next_state <= DONE;
                        else
                            next_state <= START_READ;                        
                        end if;
                    
                    when DONE =>
                            if(i_start = '1') then
                                next_state <= START;
                            elsif(i_rst = '1') then
                                next_state <= RST;
                            else 
                                next_state <= current_state;
                            end if;
                    when others =>
                        if(check_errors = false) then
                            check_errors <= true;
                        else
                            check_errors <= false;
                        end if;
                    end case;
            end process;
            

            signal_process: process(i_data,i_rst,i_start,current_address_read,current_address_write,
            check_errors,num_of_word,now_counter,first_o_data_done,i_data_elab,counter_i_data,current_word)
            begin

                
                case current_state is
                    when RST =>
                        current_address_read <= rst_address_read;
                        current_address_write <= rst_address_write;
                        o_en <= '0';
                        o_we <= '0';
                        o_data <= "00000000";
                        o_done <= '0';
                        o_address <= rst_address_read;
                        now_counter <= 0;
                        
                    
                    when START =>
                        current_address_read <= current_address_read;
                        current_address_write <= current_address_write;
                        o_en <= '1';
                        o_we <= '0';
                        o_data <= "00000000";
                        o_done <= '0';
                        o_address <= current_address_read;
                       

                    when R_NUM =>
                        num_of_word <= TO_INTEGER(unsigned(i_data));
                        current_address_read <= std_logic_vector(unsigned(current_address_read + "1000"));
                        o_address <= current_address_read;
                        
                        
                    when START_READ =>
                        current_word <= i_data;
                        current_address_read <= std_logic_vector(unsigned(current_address_read + "1000") );

                    when zero_zero => 
                        o_en <= '0';
                        
                        counter_i_data_for_signals <= counter_i_data_for_signals + 1;
                            if(counter_i_data_for_signals = 8) then
                                counter_i_data_for_signals <= 0;
                                now_counter <= now_counter + 1; 
                            end if;

                        if(current_word(counter_i_data_for_signals) = '0') then
                            i_data_elab <= "00";
                        elsif(current_word(counter_i_data_for_signals) = '1') then
                            i_data_elab <= "11";
                        end if;

                        

                when one_zero => 
                    o_en <= '0';

                    counter_i_data_for_signals <= counter_i_data_for_signals + 1;
                    if(counter_i_data_for_signals = 8) then
                        counter_i_data_for_signals <= 0;
                        now_counter <= now_counter + 1; 
                    end if;


                    if(current_word(counter_i_data_for_signals) = '0') then
                        i_data_elab <= "01";
                    elsif(current_word(counter_i_data_for_signals) = '1') then
                        i_data_elab <= "10";
                    end if;
                
                when one_one => 

                o_en <= '0';

                counter_i_data_for_signals <= counter_i_data_for_signals + 1;
                if(counter_i_data_for_signals = 8) then
                    counter_i_data_for_signals <= 0;
                    now_counter <= now_counter + 1; 
                end if;

                    if(current_word(counter_i_data_for_signals) = '0') then
                        i_data_elab <= "10";
                    elsif(current_word(counter_i_data_for_signals) = '1') then
                        i_data_elab <= "01";
                    end if;


                when zero_one => 


                counter_i_data_for_signals <= counter_i_data_for_signals + 1;
                if(counter_i_data_for_signals = 8) then
                    counter_i_data_for_signals <= 0;
                    now_counter <= now_counter + 1; 
                end if;

                    if(current_word(counter_i_data_for_signals) = '0') then
                        i_data_elab <= "11";
                    elsif(current_word(counter_i_data_for_signals) = '1') then
                        i_data_elab <= "00";
                    end if;
                when DIV_WORD =>
                        o_we <= '1';
                        o_en <= '1';
                    if(not first_o_data_done) then
                        o_address <= current_address_write;
                        o_data <= R0 & R1 & R2 & R3;
                        current_address_write <= std_logic_vector(unsigned(current_address_write + "1000") );
                        first_o_data_done <= true;
                    else   
                        o_address <= current_address_write;
                        o_data <= R4 & R5 & R6 & R7 ;
                        current_address_write <= std_logic_vector(unsigned(current_address_write + "1000"));
                        first_o_data_done <= false;
                    end if;
                    
                when DONE =>
                        o_done <= '1';
                        o_en <= '0';
                        
                when others =>
                    if(check_errors_signals_process = false) then
                        check_errors_signals_process <= true;
                    else
                    check_errors_signals_process <= false;
                    end if;
                end case;

                case counter_i_data_for_signals is
                    when 0 =>
                        R0 <= i_data_elab;
                    when 1 =>
                        R1 <= i_data_elab;
                    when 2 =>
                        R2 <= i_data_elab;
                    when 3 =>
                        R3 <= i_data_elab;
                    when 4 =>
                        R4 <= i_data_elab;
                    when 5 =>
                        R5 <= i_data_elab;
                    when 6 =>
                        R6 <= i_data_elab;
                    when 7 =>
                        R7 <= i_data_elab;
                    when others => 
                        R0 <= "00";
                        R1 <= "00";
                        R2 <= "00";
                        R3 <= "00";
                        R4 <= "00";
                        R5 <= "00";
                        R6 <= "00";
                        R7 <= "00";
                    end case;

                if(counter_i_data_for_signals = 7) then
                    now_counter <= now_counter + 1;
                else
                    counter_i_data_for_signals <= counter_i_data_for_signals;
                end if;
                
                
                
            end process;

    process(i_clk,i_rst,i_start)
    begin
        if(i_rst = '1') then
                current_state <= RST;
        end if;
                
        if(rising_edge(i_clk)) then
           current_state <= next_state;
        end if;

    end process;
            
    end behavioural;

       

    

