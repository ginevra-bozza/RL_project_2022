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
    type state_type is (RST, START, R_NUM, START_READ, DONE, WRITE_FIRST, DIV_WORD, WRITE_SECOND, SET_ADD_RREAD, SET_ADD_WREAD, SET_REG, SET_DONE, zero_zero, zero_one, one_zero, one_one); --FSM da specifica

    --signal current_state: state_type;
    signal next_state: state_type;
    signal cur_fsm_state: state_type;
    signal next_fsm_state: state_type;
    --signal program_state: set_program_state;
    
    --segnali su cui lavoriamo, che vengono modificati
    signal current_address_read: std_logic_vector(15 downto 0);
    signal current_address_write: std_logic_vector(15 downto 0);
    signal next_address_read: std_logic_vector(15 downto 0);
    signal next_address_write: std_logic_vector(15 downto 0); 
    signal num_of_word: integer;
    --signal now_counter: integer;
    signal first_o_data_done: boolean;
    signal check_errors: boolean;
    signal check_done: boolean;
    signal check_written_word: boolean;
    signal check_read: boolean;
    --signal check_errors_signals_process: boolean:= false;
    


    signal i_data_elab: std_logic_vector(1 downto 0);
    --signal counter_i_data: integer;
    --signal counter_i_data_for_signals: integer := 0 ;
    signal current_word : std_logic_vector(0 to 7);
    signal R0,R1,R2,R3,R4,R5,R6,R7 : std_logic_vector(0 to 1); 

    
    
   begin
    process(i_clk,i_rst,i_start,current_address_read,current_address_write,
    check_errors,num_of_word,first_o_data_done,i_data_elab,current_word,--rst_address_read,rst_address_write,
    cur_fsm_state,next_state,check_written_word,check_done,check_errors)
    variable counter_i_data : natural range 0 to 8 := 0;
    variable now_counter : natural := 0;
    begin
        --counter_i_data := 0;
        if(i_rst = '1') then
                next_state <= RST;
        end if;
                
        if(rising_edge(i_clk)) then
            case next_state is
                when RST =>
                    --
                    current_address_read <= "0000000000000000";
                    current_address_write <= "0000001111101000";
                    next_address_read <= "0000000000000000";
                    next_address_write <= "0000001111101000";
                    o_en <= '0';
                    o_we <= '0';
                    o_data <= "00000000";
                    o_done <= '0';
                    o_address <=  "0000000000000000";--std_logic_vector(unsigned(rst_address_read));
                    now_counter := 0;
                    num_of_word <= 0;
                    counter_i_data := 0;
                    first_o_data_done <= false;
                    check_errors <= false;
                    check_done <= false;
                    check_written_word <= false;
                    check_read <= false;
                    current_word <= "00000000";
                    R0 <= "00";R1<="00";R2<= "00";R3<= "00";R4<= "00";R5<= "00";R6<= "00";R7<= "00";
                    --
                    if(i_start = '1') then 
                        next_state <= START;
                        cur_fsm_state <= zero_zero;    
                    else
                        next_state <= RST;
                    end if;

                    
                when START =>
                    next_state <= R_NUM;
                    --
                    o_en <= '1';
                    o_we <= '0';
                    o_address <= std_logic_vector(unsigned(current_address_read));
                    --
                                   
                when R_NUM =>
                    o_en <= '0';
                    o_we <= '0';
                    --
                    num_of_word <= TO_INTEGER(unsigned(i_data));
                    next_address_read <= std_logic_vector(unsigned(current_address_read) + 1);
                    if(check_read) then
                        next_state <= SET_ADD_RREAD;
                        check_read <= false;
                    else 
                        next_state <= R_NUM;
                        check_read <= true;
                    end if;
                    --
                when SET_ADD_RREAD =>
                    o_en <= '1';
                    o_we <= '0';
                    o_address <= std_logic_vector(unsigned(next_address_read));
                    current_address_read <= std_logic_vector(unsigned(next_address_read));

                    next_state <= START_READ;

                when START_READ =>
                    o_en <= '0';
                    o_we <= '0';
                    --
                    current_word <= i_data;
                    next_address_read <= std_logic_vector(unsigned(current_address_read) + 1 );
                    if(check_read) then
                        next_state <= cur_fsm_state;
                        check_read <= false;
                    else 
                        next_state <= START_READ;
                        check_read <= true;
                    end if;
                    --
                
                when zero_zero => 
                    cur_fsm_state <= zero_zero;
                    
                    if(current_word(counter_i_data) = '0') then
                            next_fsm_state <= zero_zero;
                            i_data_elab <= "00";
                        elsif(current_word(counter_i_data) = '1') then
                            next_fsm_state <= one_zero;
                            i_data_elab <= "11";
                        else
                            next_state <= zero_zero;
                        end if;
                        next_state <= SET_REG;
                    if(counter_i_data = 7) then
                        counter_i_data := 0;
                        now_counter := now_counter + 1; 
                        next_state <= SET_ADD_WREAD;
                    else
                        
                    end if;
                    counter_i_data := counter_i_data + 1;

                    
                when one_zero => 
                    cur_fsm_state <= one_zero;

                    if(current_word(counter_i_data) = '0') then
                        next_fsm_state <= zero_one;
                        i_data_elab <= "01";
                        next_state <= SET_REG;
                    elsif(current_word(counter_i_data) = '1') then
                        next_fsm_state <= one_one;
                        i_data_elab <= "10";
                        next_state <= SET_REG;
                    else
                    next_state <= one_zero;
                    end if;
                    counter_i_data := counter_i_data + 1;
                
                when one_one => 
                    cur_fsm_state <= one_one;

                    
                    if(current_word(counter_i_data) = '0') then
                        next_fsm_state <= zero_one;
                        i_data_elab <= "10";
                        next_state <= SET_REG;
                    elsif(current_word(counter_i_data) = '1') then
                        next_fsm_state <= one_one;
                        i_data_elab <= "01";
                        next_state <= SET_REG;
                    else
                        next_state <= one_one;
                    end if;
                        
                    counter_i_data := counter_i_data + 1;
                
                when zero_one => 
                    cur_fsm_state <= zero_one;

                    
                    if(current_word(counter_i_data) = '0') then
                        next_fsm_state <= zero_zero;
                        i_data_elab <= "11";
                        next_state <= SET_REG;
                    elsif(current_word(counter_i_data) = '1') then
                        next_fsm_state <= one_zero;
                        i_data_elab <= "00";
                        next_state <= SET_REG;
                    else
                        next_state <= zero_one;
                    end if;
                        
                    counter_i_data := counter_i_data + 1; 
               
                when  SET_REG=>
                    
                    next_state <= next_fsm_state;
                    
                    case counter_i_data is
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
                            counter_i_data := 0;
                            now_counter := now_counter + 1; 
                            next_state <= SET_ADD_WREAD;
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
                    
                            
                
                when SET_ADD_WREAD =>
                    o_we <= '1';
                    o_en <= '1';
                    o_address <= current_address_write;
                    next_state <= DIV_WORD;
                    next_address_write <= std_logic_vector(unsigned(current_address_write) + 1);

                
                when DIV_WORD =>
                if(not first_o_data_done) then
                    o_data <= R0 & R1 & R2 & R3;
                    first_o_data_done <= true;
                    next_state <= SET_ADD_WREAD;
                else   
                    o_data <= R4 & R5 & R6 & R7 ;
                    first_o_data_done <= false;
                    check_written_word <= true;
                end if;
                current_address_write <= next_address_write;

                if(now_counter = num_of_word and check_written_word) then
                    next_state <= SET_DONE;
                elsif(check_written_word) then
                    next_state <= SET_ADD_RREAD;                        
                end if;

                when SET_DONE =>
                    o_en <= '0';
                    o_we <= '0';
                    o_done <= '1';
                    next_state <= DONE;
                
                when DONE =>
                    
                    if(i_start = '0') then
                        next_state <= DONE;
                        o_done <= '0';
                        check_done <= true;    
                    elsif(i_start = '0' and check_done) then
                        next_state <= START;
                        check_done <= false;
                    else 
                        next_state <= DONE;
                    end if;
                
                
                when others =>
                    if(check_errors = false) then
                        check_errors <= true;
                    else
                        check_errors <= false;
                    end if;
                end case;
                --current_state <= next_state;

        end if;



    end process;
            
end behavioural;