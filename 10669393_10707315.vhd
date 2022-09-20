library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity project_reti_logiche is
    port (
    i_clk : in std_logic;                           --i_clk è il segnale di CLOCK in ingresso generato dal TestBench;
    i_rst : in std_logic;                           --i_rst è il segnale di RESET che inizializza la macchina pronta per ricevere il primo segnale di START;
    i_start : in std_logic;                         --i_start è il segnale di START generato dal Test Bench;
    i_data : in std_logic_vector(7 downto 0);       --i_data è il segnale (vettore) che arriva dalla memoria in seguito ad una richiesta di lettura;
    o_address : out std_logic_vector(15 downto 0);  --o_address è il segnale (vettore) di uscita che manda l’indirizzo alla memoria;
    o_done : out std_logic;                         --è il segnale di uscita che comunica la fine dell’elaborazione e il dato di uscita scritto in memoria;
    o_en : out std_logic;                           --o_en è il segnale di ENABLE da dover mandare alla memoria per poter comunicare (sia in lettura che in scrittura);
    o_we : out std_logic;                           --o_we è il segnale di WRITE ENABLE da dover mandare alla memoria (=1) per poter scriverci. Per leggere da memoria esso deve essere 0;
    o_data : out std_logic_vector (7 downto 0)      --o_data è il segnale (vettore) di uscita dal componente verso la memoria.
    );
    end project_reti_logiche;

    architecture behaviour of project_reti_logiche is
        type state_type is (zero_zero, zero_one, one_zero, one_one); --FSM da specifica
        type set_program_state is (not_started, computation_terminated, done_reset,do_not_restart) --Nostra FSM per gestire done e reset

        signal current_state,next_state: state_type;
        signal program_state: set_program_state;
        signal current_i_data: std_logic_vector(7 downto 0)         := "00000000";
        signal current_y_data: std_logic_vector(15 downto 0)        := "0000000000000000";
        signal current_address_read: std_logic_vector(15 downto 0)  := "0000000000000000";
        signal current_address_write: std_logic_vector(15 downto 0) := "0000001111101000"; 

        begin
            sync_start: process( i_clk, i_start, o_done, i_rst )
            begin
                if (i_rst = '1' and o_done = '0') then
                    program_state <= not_started;
                elsif(i-rst = '1' and o_done = '1') then
                    program_state <= computation_terminated;
                elsif(i-rst = '0' and o_done = '1') then
                    program_state <= do_not_restart;
                --non gestita perchè non fa nulla
            end sync_start;

            convolutore: process(current_state, next_state, current_i_data, current_y_data)
            begin
                for k in 7 downto 0 loop
                    case current_state is
                        when zero_zero => 
                            if(current_i_data(k) = '0') then
                                next_state <= zero_zero;
                                if(k mod 2 = '0') then 
                                    current_y_data(k + k) <= '0';
                                    current_y_data(k + k + 2) <= '0';
                                else
                                    current_y_data(k + k - 1) <= '0';
                                    current_y_data(k + k + 1) <= '0';
                                
                            elsif(current_i_data(k) = '1') then
                                next_state = one_zero;
                                if(k mod 2 = '0') then 
                                    current_y_data(k + k) <= '1';
                                    current_y_data(k + k + 2) <= '1';
                                else
                                    current_y_data(k + k - 1) <= '1';
                                    current_y_data(k + k + 1) <= '1';
                                
                        when one_zero => 
                            if(current_i_data(k) = '0') then
                                next_state <= zero_one;
                                if(k mod 2 = '0') then 
                                    current_y_data(k + k) <= '0';
                                    current_y_data(k + k + 2) <= '1';
                                else
                                    current_y_data(k + k - 1) <= '0';
                                    current_y_data(k + k + 1) <= '1';
                                
                            elsif(current_i_data(k) = '1') then
                                next_state = one_one;
                                if(k mod 2 = '0') then 
                                    current_y_data(k + k) <= '1';
                                    current_y_data(k + k + 2) <= '0';
                                else
                                    current_y_data(k + k - 1) <= '1';
                                    current_y_data(k + k + 1) <= '0';

                        when one_one => 
                            if(current_i_data(k) = '0') then
                                next_state <= zero_one;
                                if(k mod 2 = '0') then 
                                    current_y_data(k + k) <= '1';
                                    current_y_data(k + k + 2) <= '0';
                                else
                                    current_y_data(k + k - 1) <= '1';
                                    current_y_data(k + k + 1) <= '0';
                                
                            elsif(current_i_data(k) = '1') then
                                next_state = one_one;
                                if(k mod 2 = '0') then 
                                    current_y_data(k + k) <= '0';
                                    current_y_data(k + k + 2) <= '1';
                                else
                                    current_y_data(k + k - 1) <= '0';
                                    current_y_data(k + k + 1) <= '1';

                        when zero_one => 
                            if(current_i_data(k) = '0') then
                                next_state <= zero_zero;
                                if(k mod 2 = '0') then 
                                    current_y_data(k + k) <= '1';
                                    current_y_data(k + k + 2) <= '1';
                                else
                                    current_y_data(k + k - 1) <= '1';
                                    current_y_data(k + k + 1) <= '1';
                                
                            elsif(current_i_data(k) = '1') then
                                next_state = one_zero;
                                if(k mod 2 = '0') then 
                                    current_y_data(k + k) <= '0';
                                    current_y_data(k + k + 2) <= '0';
                                else
                                    current_y_data(k + k - 1) <= '0';
                                    current_y_data(k + k + 1) <= '0';
            end convolutore;
        end behaviour;