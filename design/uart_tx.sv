module uart_tx #(
    parameter int DATA_WIDTH     = 8,

    parameter bit PARITY_EN      = 1, 
    parameter bit PARITY_IS_EVEN = 1  
) (
    input  logic                   i_clk,
    input  logic                   i_reset_n,
    input  logic                   i_baud_tick,
    input  logic                   i_tx_start,

    input  logic [DATA_WIDTH-1:0]  i_data_in,

    output logic                   o_tx_serial,
    output logic                   o_tx_busy
);
    typedef enum logic [2:0] {
        S_IDLE       = 3'b000,
        S_START_BIT  = 3'b001,
        S_DATA_BITS  = 3'b010,
        S_PARITY_BIT = 3'b011,
        S_STOP_BIT   = 3'b100
    } tx_state_t;

    tx_state_t tx_state;

    logic [3:0]            tx_sample_count; 
    logic [3:0]            data_bit_count;  
    logic [DATA_WIDTH-1:0] tx_shift_reg;    

    logic parity_bit;

    always_ff @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
            tx_state        <= S_IDLE;
            o_tx_serial     <= 1'b1;  
            o_tx_busy       <= 1'b0;
            tx_sample_count <= 4'd0;
            data_bit_count  <= 4'd0;
            tx_shift_reg    <= '0;
        end else begin

            unique case (tx_state)

                S_IDLE: begin
                    o_tx_serial <= 1'b1;
                    o_tx_busy   <= 1'b0;

                    if (i_tx_start) begin
                        tx_shift_reg    <= i_data_in;
                        parity_bit <= PARITY_IS_EVEN ? (^i_data_in) : ~(^i_data_in);
                        data_bit_count  <= 4'd0;
                        tx_sample_count <= 4'd0;
                        o_tx_serial     <= 1'b0;    
                        o_tx_busy       <= 1'b1;  
                        tx_state        <= S_START_BIT;
                    end
                end

                S_START_BIT: begin
                    o_tx_busy <= 1'b1;
                    if (i_baud_tick) begin
                        if (tx_sample_count == 4'd15) begin
                            tx_sample_count <= 4'd0;
                            data_bit_count  <= 4'd0;  
                            o_tx_serial     <= tx_shift_reg[0];
                            tx_shift_reg    <= tx_shift_reg >> 1;
                            tx_state        <= S_DATA_BITS;
                        end else begin
                            tx_sample_count <= tx_sample_count + 1'd1;
                        end
                    end
                end

                S_DATA_BITS: begin
                    o_tx_busy <= 1'b1;
                    if (i_baud_tick) begin
                        if (tx_sample_count == 4'd15) begin
                            tx_sample_count <= 4'd0;

                            if (data_bit_count == DATA_WIDTH[3:0] - 1'b1) begin
                                if (PARITY_EN) begin
                                    o_tx_serial <= parity_bit;
                                    tx_state    <= S_PARITY_BIT;
                                end else begin
                                    o_tx_serial <= 1'b1;
                                    tx_state    <= S_STOP_BIT;
                                end
                            end else begin
                                data_bit_count <= data_bit_count + 1'd1;
                                o_tx_serial    <= tx_shift_reg[0];
                                tx_shift_reg   <= tx_shift_reg >> 1;
                            end
                        end else begin
                            tx_sample_count <= tx_sample_count + 1'd1;
                        end
                    end
                end

                S_PARITY_BIT: begin
                    o_tx_busy <= 1'b1;
                    if (i_baud_tick) begin
                        if (tx_sample_count == 4'd15) begin
                            tx_sample_count <= 4'd0;
                            o_tx_serial     <= 1'b1; 
                            tx_state        <= S_STOP_BIT;
                        end else begin
                            tx_sample_count <= tx_sample_count + 1'd1;
                        end
                    end
                end

                S_STOP_BIT: begin
                    o_tx_busy <= 1'b1;
                    if (i_baud_tick) begin
                        if (tx_sample_count == 4'd15) begin
                            tx_sample_count <= 4'd0;
                            tx_state        <= S_IDLE;
                        end else begin
                            tx_sample_count <= tx_sample_count + 1'd1;
                        end
                    end
                end

                default: begin
                    tx_state    <= S_IDLE;
                    o_tx_serial <= 1'b1;
                    o_tx_busy   <= 1'b0;
                end

            endcase
        end
    end
    
endmodule