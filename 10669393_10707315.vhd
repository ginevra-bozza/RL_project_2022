library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

--Co-autori 
--Emanuele Cimino 10669393
--Ginevra Bozza 10707315

entity project_reti_logiche is
    port (
    i_clk : in std_logic;                           --i_clk è il segnale di CLOCK in ingresso generato dal TestBench;
    i_rst : in std_logic;                           --i_rst è il segnale di RESET che inizializza la macchina pronta per ricevere il primo segnale di START;
    i_start : in std_logic;                         --i_start è il segnale di START generato dal Test Bench;
    i_data : in std_logic_vector(7 downto 0);       --i_data è il segnale (vettore) che arriva dalla memoria in seguito ad una richiesta di lettura;
    o_address : out std_logic_vector(15 downto 0);  --o_address è il segnale (vettore) di uscita che manda l'indirizzo alla memoria;
    o_done : out std_logic;                         --o_done è il segnale di uscita che comunica la fine dell'elaborazione e il dato di uscita scritto in memoria;
    o_en : out std_logic;                           --o_en è il segnale di ENABLE da dover mandare alla memoria per poter comunicare (sia in lettura che in scrittura);
    o_we : out std_logic;                           --o_we è il segnale di WRITE ENABLE da dover mandare alla memoria (=1) per poter scriverci. Per leggere da memoria esso deve essere 0;
    o_data : out std_logic_vector (7 downto 0)      --o_data è il segnale (vettore) di uscita dal componente verso la memoria.
    );
    end project_reti_logiche;

architecture behavioural of project_reti_logiche is
    type state_type is (RST, START, R_NUM, START_READ, DONE, WRITE_FIRST, DIV_WORD_ONE, DIV_WORD_TWO, WRITE_SECOND, SET_ADD_R, SET_ADD_W, SET_REG, SET_DONE, zero_zero, zero_one, one_zero, one_one); --FSM da specifica

    signal next_state: state_type; 
    signal cur_fsm_state: state_type;
    signal next_fsm_state: state_type;
    
    --segnali su cui lavoriamo, che vengono modificati
    signal current_address_read: std_logic_vector(15 downto 0);
    signal current_address_write: std_logic_vector(15 downto 0);
    signal next_address_read: std_logic_vector(15 downto 0);
    signal next_address_write: std_logic_vector(15 downto 0); 
    signal num_of_word: integer;                               --numero di parole letto da memoria
    signal i_data_elab: std_logic_vector(1 downto 0);          --risultato dell'elaborazione del singolo bit
    signal current_word : std_logic_vector(0 to 7);            --parola da elaborare
    signal R0,R1,R2,R3,R4,R5,R6,R7 : std_logic_vector(0 to 1); --registri in cui viene salvato il risultato dell'elaborazione

    --segnali di controllo
    signal first_o_data_done: boolean;
    signal check_errors: boolean;
    signal check_read: boolean;    
 
   begin
    process(i_clk,i_rst,i_start,current_address_read,current_address_write,check_errors,num_of_word,
            first_o_data_done,i_data_elab,current_word,cur_fsm_state,next_state,check_errors)

    variable counter_i_data : natural range 0 to 8 := 0; --contatore dei singoli bit della parola in ingresso
    variable now_counter : natural := 0;                 --contatore delle parole elaborate

    begin
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
                    o_address <=  "0000000000000000";
                    now_counter := 0;
                    num_of_word <= 0;
                    counter_i_data := 0;
                    first_o_data_done <= false;
                    check_errors <= false;
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
                    --
                    if(check_read) then
                        next_state <= SET_ADD_R;
                        check_read <= false;
                    else 
                        next_state <= R_NUM;
                        check_read <= true;
                    end if;
                    --

                when SET_ADD_R =>
                    o_en <= '1';
                    o_we <= '0';
                    --
                    o_address <= std_logic_vector(unsigned(next_address_read));
                    current_address_read <= std_logic_vector(unsigned(next_address_read));
                    --
                    if(num_of_word = 0) then
                        next_state <= SET_DONE;
                    else
                        next_state <= START_READ;
                    end if;
                    --

                when START_READ =>
                    o_en <= '0';
                    o_we <= '0';
                    --
                    current_word <= i_data;
                    next_address_read <= std_logic_vector(unsigned(current_address_read) + 1 );
                    --
                    if(check_read) then
                        next_state <= cur_fsm_state;
                        check_read <= false;
                    else 
                        next_state <= START_READ;
                        check_read <= true;
                    end if;
                    --
                
                when zero_zero => 

                    if(current_word(counter_i_data) = '0') then
                            next_fsm_state <= zero_zero;
                            i_data_elab <= "00";
                            next_state <= SET_REG;
                    elsif(current_word(counter_i_data) = '1') then
                        next_fsm_state <= one_zero;
                        i_data_elab <= "11";
                        next_state <= SET_REG;
                    else
                        next_state <= zero_zero;
                    end if;

                when one_zero => 

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

                when one_one => 
                    
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
                        
                when zero_one => 
                    
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
                        
                when  SET_REG=>
                    next_state <= next_fsm_state;
                    --
                    case counter_i_data is
                        when 0 =>
                            R0 <= i_data_elab;
                            counter_i_data := counter_i_data + 1; 
                        when 1 =>
                            R1 <= i_data_elab;
                            counter_i_data := counter_i_data + 1; 
                        when 2 =>
                            R2 <= i_data_elab;
                            counter_i_data := counter_i_data + 1; 
                        when 3 =>
                            R3 <= i_data_elab;
                            counter_i_data := counter_i_data + 1;                             
                        when 4 =>
                            R4 <= i_data_elab;
                            counter_i_data := counter_i_data + 1; 
                        when 5 =>
                            R5 <= i_data_elab;
                            counter_i_data := counter_i_data + 1;                            
                        when 6 =>
                            R6 <= i_data_elab;
                            counter_i_data := counter_i_data + 1;                             
                        when 7 =>
                            R7 <= i_data_elab;
                            counter_i_data := 0;
                            now_counter := now_counter + 1; 
                            next_state <= SET_ADD_W;
                            
                            cur_fsm_state <= next_fsm_state;
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
                        --
                    
                when SET_ADD_W =>
                    o_we <= '1';
                    o_en <= '1';
                    --
                    o_address <= current_address_write;

                    if(not first_o_data_done) then
                        next_state <= DIV_WORD_ONE;
                        first_o_data_done <= true;
                    else 
                        next_state <= DIV_WORD_TWO;
                        first_o_data_done <= false;
                    end if;

                    next_address_write <= std_logic_vector(unsigned(current_address_write) + 1);
                    --
                
                when DIV_WORD_ONE =>
                    o_data <= R0 & R1 & R2 & R3;
                    current_address_write <= next_address_write;
                    --
                    next_state <= SET_ADD_W;
                    --

                when DIV_WORD_TWO =>
                    o_data <= R4 & R5 & R6 & R7 ;
                    current_address_write <= next_address_write;
                    --
                    if(now_counter = num_of_word) then
                        next_state <= SET_DONE;
                        now_counter := 0;
                    else
                        next_state <= SET_ADD_R; 
                    end if;
                    --

                when SET_DONE =>
                    o_en <= '0';
                    o_we <= '0';
                    --
                    o_done <= '1';
                    next_state <= DONE;
                    --
                when DONE =>
                    
                    if(i_start = '0') then
                        next_state <= RST;
                        o_done <= '0';
                        current_address_read <= "0000000000000000";
                        current_address_write <= "0000001111101000";
                        next_address_read <= "0000000000000000";
                        next_address_write <= "0000001111101000";    
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

        end if;

    end process;
            
end behavioural;