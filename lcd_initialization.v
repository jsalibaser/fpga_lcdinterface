`timescale 1ns / 1ps

module lcd_initialization(
    input clk,
    input nrst,
    output reg en,
    output reg rs,
    output reg db7,
    output reg db6,
    output reg db5,
    output reg db4
);

    reg [5:0] state;
    reg [32:0] delay_counter; 
    reg [3:0] outData;      
    reg task_done;          
    reg [32:0] max_counter; 

    always @(*) begin
        db7 = outData[3];
        db6 = outData[2];
        db5 = outData[1];
        db4 = outData[0];
    end

    task execute_sequence;
        input [3:0] data; // Command data
        output reg finished; // Completion flag
        begin
            if (delay_counter < 30) begin
                delay_counter <= delay_counter + 1;
                en <= 1;
                if (delay_counter == 29)
                    outData <= data;
            end else if (delay_counter < 50) begin
                delay_counter <= delay_counter + 1;
                if (delay_counter == 49)
                    en <= 0;
            end else begin
                delay_counter <= delay_counter + 1;
                if (delay_counter == max_counter) begin
                    delay_counter <= 0;
                    finished <= 1;
                end else
                    finished <= 0;
            end
        end
    endtask

    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            outData <= 4'b0000;
            max_counter <= 1_500_000; 
            state <= 0;
            delay_counter <= 0;
            en <= 0;
            rs <= 0;
        end else begin
            case (state)
                // Step 0: Wait for power stabilization (>15 ms)
                0: begin
                    en <= 0;
                    rs <= 0;
                    if (delay_counter < max_counter)
                        delay_counter <= delay_counter + 1;
                    else begin
                        delay_counter <= 0;
                        max_counter <= 5000; // Next state delay
                        state <= 1;
                    end
                end

                // Function Set Command: (8-Bit interface)
                1: begin
                    execute_sequence(4'b0011, task_done);
                    if (task_done) begin
                        max_counter <= 410_000;
                        state <= 2;
                    end
                end

                2: begin
                    en <= 0;
                    if (delay_counter < max_counter)
                        delay_counter <= delay_counter + 1;
                    else begin
                        delay_counter <= 0;
                        max_counter <= 5000; // Next state delay
                        state <= 3;
                    end
                end

                3: begin
                    execute_sequence(4'b0011, task_done);
                    if (task_done) begin
                        max_counter <= 10_000; // Delay for 100 µs
                        state <= 4;
                    end
                end

                4: begin
                    en <= 0;
                    if (delay_counter < max_counter)
                        delay_counter <= delay_counter + 1;
                    else begin
                        delay_counter <= 0;
                        max_counter <= 5000; // Next state delay
                        state <= 5;
                    end
                end

                // Function Set Command: (8-Bit interface)
                5: begin
                    execute_sequence(4'b0011, task_done);
                    if (task_done) begin
                        max_counter <= 5000; // Delay for next state
                        state <= 6;
                    end
                end

                // Function Set: Sets interface to 4-bit
                6: begin
                    execute_sequence(4'b0010, task_done);
                    if (task_done) begin
                        max_counter <= 200; // Delay for upper nibble
                        state <= 7;
                    end
                end

                // Function Set (N=1 for 2-line display, F=0 for 5x7 dots) - UPPER NIBBLE
                7: begin
                    execute_sequence(4'b0010, task_done);
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 8;
                    end
                end

                // Function Set (N=1 for 2-line display, F=0 for 5x7 dots) - LOWER NIBBLE
                8: begin
                    execute_sequence(4'b1000, task_done);
                    if (task_done) begin
                        max_counter <= 200; // Delay for upper nibble
                        state <= 9;
                    end
                end

                // Display OFF - UPPER NIBBLE
                9: begin
                    execute_sequence(4'b0000, task_done);
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 10;
                    end
                end

                // Display OFF - LOWER NIBBLE
                10: begin
                    execute_sequence(4'b1000, task_done);
                    if (task_done) begin
                        max_counter <= 200; // Delay for upper nibble
                        state <= 11;
                    end
                end

                // Clear Display - UPPER NIBBLE
                11: begin
                    execute_sequence(4'b0000, task_done);
                    if (task_done) begin
                        max_counter <= 1_600_000; // Delay for 16ms
                        state <= 12;
                    end
                end

                // Clear Display - LOWER NIBBLE
                12: begin
                    execute_sequence(4'b0001, task_done);
                    if (task_done) begin
                        max_counter <= 200; // Delay for upper nibble
                        state <= 13;
                    end
                end

                // Entry Mode Set (I/D=1, Increment; S=1, Shift left) - UPPER NIBBLE
                13: begin
                    execute_sequence(4'b0000, task_done);
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 14;
                    end
                end

                // Entry Mode Set (I/D=1, Increment; S=1, Shift left) - LOWER NIBBLE
                14: begin
                    execute_sequence(4'b0110, task_done);
                    if (task_done) begin
                        max_counter <= 200; // Delay for upper nibble
                        state <= 15;
                    end
                end

                // Display ON - UPPER NIBBLE
                15: begin
                    execute_sequence(4'b0000, task_done);
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 16;
                    end
                end

                // Display ON - LOWER NIBBLE
                16: begin
                    execute_sequence(4'b1111, task_done);
                    if (task_done) begin
                        max_counter <= 200; // Delay for next operation
                        state <= 17;
                    end
                end
                                // Point Cursor to 1st Line, 1st Column (Address 00H) - UPPER NIBBLE
                17: begin
                    execute_sequence(4'b0000, task_done);
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 18;
                    end
                end

                // Point Cursor to 1st Line, 1st Column (Address 00H) - LOWER NIBBLE
                18: begin
                    execute_sequence(4'b0000, task_done);
                    if (task_done) begin
                        max_counter <= 15; // Buffer time for register set
                        state <= 19;
                    end
                end

                // Buffer Time for Register Set
                19: begin
                    rs <= 1; // Data register select
                    if (delay_counter < max_counter)
                        delay_counter <= delay_counter + 1;
                    else begin
                        delay_counter <= 0;
                        max_counter <= 200; // Delay for writing data
                        state <= 20;
                    end
                end

                // Display 'J' (Character Code 4A) - UPPER NIBBLE
                20: begin
                    execute_sequence(4'b0100, task_done); // 4H
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 21;
                    end
                end

                // Display 'J' (Character Code 4A) - LOWER NIBBLE
                21: begin
                    execute_sequence(4'b1010, task_done); // AH
                    if (task_done) begin
                        max_counter <= 200; // Delay for next operation
                        state <= 22;
                    end
                end

                // Display 'E'  - UPPER NIBBLE
                22: begin
                    execute_sequence(4'b0100, task_done); // 6H
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 23;
                    end
                end

                // Display 'E' - LOWER NIBBLE
                23: begin
                    execute_sequence(4'b0101, task_done);
                    if (task_done) begin
                        max_counter <= 200; // Delay for next operation
                        state <= 24;
                    end
                end

                // Display 'H'  - UPPER NIBBLE
                24: begin
                    execute_sequence(4'b0100, task_done); // 6H
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 25;
                    end
                end

                // Display 'H'- LOWER NIBBLE
                25: begin
                    execute_sequence(4'b1000, task_done); 
                    if (task_done) begin
                        max_counter <= 200; // Delay for next operation
                        state <= 26;
                    end
                end
                
                // Display 'A' (Character Code 61H) - UPPER NIBBLE
                26: begin
                    execute_sequence(4'b0100, task_done); // 6H
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 27;
                    end
                end

                // Display 'A' (Character Code 61H) - LOWER NIBBLE
                27: begin
                    execute_sequence(4'b0001, task_done);
                    if (task_done) begin
                        max_counter <= 200; // Delay for next operation
                        state <= 28;
                    end
                end
                
                // Display 'D' - UPPER NIBBLE
                28: begin
                    execute_sequence(4'b0100, task_done); // 6H
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 29;
                    end
                end

                // Display 'D' - LOWER NIBBLE
                29: begin
                    execute_sequence(4'b0100, task_done);
                    if (task_done) begin
                        max_counter <= 15; // Buffer time for register set
                        state <= 30;
                    end
                end

                // Buffer Time for Register Set
                30: begin
                    rs <= 0; // Command register select
                    if (delay_counter < max_counter)
                        delay_counter <= delay_counter + 1;
                    else begin
                        delay_counter <= 0;
                        max_counter <= 200; // Delay for next operation
                        state <= 31;
                    end
                end

                // Point Cursor to 2nd Line (Address 40H) - UPPER NIBBLE
                31: begin
                    execute_sequence(4'b1100, task_done); // 4H
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 32;
                    end
                end

                // Point Cursor to 2nd Line (Address 40H) - LOWER NIBBLE
                32: begin
                    execute_sequence(4'b0000, task_done);
                    if (task_done) begin
                        max_counter <= 15; // Buffer time for register set
                        state <= 33;
                    end
                end

                // Buffer Time for Register Set
                33: begin
                    rs <= 1; // Data register select
                    if (delay_counter < max_counter)
                        delay_counter <= delay_counter + 1;
                    else begin
                        delay_counter <= 0;
                        max_counter <= 200; // Delay for next operation
                        state <= 34;
                    end
                end

                // Display 'A' - UPPER NIBBLE
                34: begin
                    execute_sequence(4'b0100, task_done); // 4H
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 35;
                    end
                end

                35: begin
                    execute_sequence(4'b0001, task_done); // FH
                    if (task_done) begin
                        max_counter <= 200; // Delay for next operation
                        state <= 36;
                    end
                end

                36: begin
                    execute_sequence(4'b0100, task_done); // 6H
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 37;
                    end
                end

                37: begin
                    execute_sequence(4'b1100, task_done); // DH
                    if (task_done) begin
                        max_counter <= 200; // Delay for next operation
                        state <= 38;
                    end
                end

                // Display 'I'  - UPPER NIBBLE
                38: begin
                    execute_sequence(4'b0100, task_done); // 6H
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 39;
                    end
                end

                // Display 'I'- LOWER NIBBLE
                39: begin
                    execute_sequence(4'b1001, task_done); // 1H
                    if (task_done) begin
                        max_counter <= 200; // Delay for next operation
                        state <= 40;
                    end
                end

                // Display 'B' - UPPER NIBBLE
                40: begin
                    execute_sequence(4'b0100, task_done); // 6H
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 41;
                    end
                end

                // Display 'B' - LOWER NIBBLE
                41: begin
                    execute_sequence(4'b0010, task_done); 
                    if (task_done) begin
                        max_counter <= 200; // Delay for next operation
                        state <= 42;
                    end
                end

                42: begin
                    execute_sequence(4'b0100, task_done);
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 43;
                    end
                end

                43: begin
                    execute_sequence(4'b0001, task_done); 
                    if (task_done) begin
                        max_counter <= 200; // Delay for next operation
                        state <= 44;
                    end
                end
                
                44: begin
                    execute_sequence(4'b0101, task_done);
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 45;
                    end
                end

                45: begin
                    execute_sequence(4'b0011, task_done);
                    if (task_done) begin
                        max_counter <= 200; // Delay for next operation
                        state <= 46;
                    end
                end
                
                46: begin
                    execute_sequence(4'b0100, task_done); 
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 47;
                    end
                end

                47: begin
                    execute_sequence(4'b0101, task_done); // 9H
                    if (task_done) begin
                        max_counter <= 200; // Delay for next operation
                        state <= 48;
                    end
                end
                
                48: begin
                    execute_sequence(4'b0101, task_done); // 6H
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 49;
                    end
                end

                49: begin
                    execute_sequence(4'b0010, task_done); // FH
                    if (task_done) begin
                        max_counter <= 201_000_000; // 2-second display delay
                        state <= 50;
                    end
                end
                
                

                // Buffer Time for Name Display
                50: begin
                    rs <= 0; // Command register select
                    if (delay_counter < max_counter)
                        delay_counter <= delay_counter + 1;
                    else begin
                        delay_counter <= 0;
                        max_counter <= 200; // Delay for next operation
                        state <= 51;
                    end
                end

                // Clear Display - UPPER NIBBLE
                51: begin
                    execute_sequence(4'b0000, task_done); // Clear command
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 52;
                    end
                end
                // Clear Display - LOWER NIBBLE
                52: begin
                    execute_sequence(4'b0001, task_done);
                    if (task_done) begin
                        max_counter <= 200; // Final delay
                        state <= 53; // Proceed to next operation
                    end
                end
                // Display ON - UPPER NIBBLE
                53: begin
                    execute_sequence(4'b0000, task_done);
                    if (task_done) begin
                        max_counter <= 5000; // Delay for lower nibble
                        state <= 54;
                    end
                end

                // Display ON - LOWER NIBBLE
                54: begin
                    execute_sequence(4'b1111, task_done);
                    if (task_done) begin
                        max_counter <= 1_600_000; // Delay for next operation
                        //state <= 17;
                    end
                end
                
            endcase
        end
    end
endmodule