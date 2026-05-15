module uart_rx #(
    parameter int DATA_WIDTH     = 8, 
    
    parameter bit PARITY_EN      = 1, 
    parameter bit PARITY_IS_EVEN = 1  
) (
    input  logic                    i_clk,
    input  logic                    i_reset_n,
    input  logic                    i_baud_tick,
    input  logic                    i_rx_serial,

    output logic [DATA_WIDTH-1:0]   o_data_parallel,
    output logic                    o_data_valid,
    output logic                    o_rx_error,
    output logic                    o_parity_error
);
    typedef enum logic [2:0] {
        S_IDLE       = 3'b000,
        S_START_BIT  = 3'b001,
        S_DATA_BITS  = 3'b010,
        S_PARITY_BIT = 3'b011,
        S_STOP_BIT   = 3'b100
    } rx_state_t;

    rx_state_t rx_state;

    logic rx_meta, rx_sync, rx_sync_d1;

    always_ff @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
            rx_meta    <= 1'b1;
            rx_sync    <= 1'b1;
            rx_sync_d1 <= 1'b1;
        end else begin
            rx_meta    <= i_rx_serial;
            rx_sync    <= rx_meta;
            rx_sync_d1 <= rx_sync;
        end
    end

    logic start_detect;
    assign start_detect = rx_sync_d1 & ~rx_sync;

    logic [3:0]            rx_sample_count; 
    logic [2:0]            data_bit_count; 
    logic [DATA_WIDTH-1:0] rx_shift_reg;  

    logic parity_expected;
    assign parity_expected = PARITY_IS_EVEN ? (^rx_shift_reg) : ~(^rx_shift_reg);

    always_ff @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
            rx_state        <= S_IDLE;
            rx_sample_count <= 4'd0;
            data_bit_count  <= 3'd0;
            rx_shift_reg    <= '0;
            o_data_parallel <= '0;
            o_data_valid    <= 1'b0;
            o_rx_error      <= 1'b0;
            o_parity_error  <= 1'b0;
        end else begin

            // Mặc định: pulse 1 cycle
            o_data_valid   <= 1'b0;
            o_rx_error     <= 1'b0;
            o_parity_error <= 1'b0;

            unique case (rx_state)

                S_IDLE: begin
                    if (start_detect) begin
                        rx_sample_count <= 4'd0;
                        rx_state        <= S_START_BIT;
                    end
                end

                S_START_BIT: begin
                    if (i_baud_tick) begin
                        rx_sample_count <= rx_sample_count + 1'd1;
                        if (rx_sample_count == 4'd7) begin
                            rx_sample_count <= 4'd0;
                            if (rx_sync == 1'b0) begin
                                data_bit_count <= 3'd0;
                                rx_state       <= S_DATA_BITS;
                            end else begin
                                rx_state <= S_IDLE;
                            end
                        end
                    end
                end

                S_DATA_BITS: begin
                    if (i_baud_tick) begin
                        rx_sample_count <= rx_sample_count + 1'd1;
                        if (rx_sample_count == 4'd15) begin
                            rx_sample_count <= 4'd0;
                            rx_shift_reg <= {rx_sync, rx_shift_reg[DATA_WIDTH-1:1]};

                            if (data_bit_count == DATA_WIDTH[2:0] - 1'b1) begin
                                data_bit_count <= 3'd0;
                                rx_state       <= PARITY_EN ? S_PARITY_BIT : S_STOP_BIT;
                            end else begin
                                data_bit_count <= data_bit_count + 1'd1;
                            end
                        end
                    end
                end

                S_PARITY_BIT: begin
                    if (i_baud_tick) begin
                        rx_sample_count <= rx_sample_count + 1'd1;
                        if (rx_sample_count == 4'd15) begin
                            rx_sample_count <= 4'd0;
                            if (rx_sync != parity_expected) begin
                                o_parity_error <= 1'b1;
                            end
                            rx_state <= S_STOP_BIT;
                        end
                    end
                end

                S_STOP_BIT: begin
                    if (i_baud_tick) begin
                        rx_sample_count <= rx_sample_count + 1'd1;
                        if (rx_sample_count == 4'd15) begin
                            rx_sample_count <= 4'd0;
                            if (rx_sync == 1'b1) begin
                                o_data_parallel <= rx_shift_reg;
                                o_data_valid    <= 1'b1;
                            end else begin
                                o_rx_error <= 1'b1;
                            end
                            rx_state <= S_IDLE;
                        end
                    end
                end

                default: rx_state <= S_IDLE;
            endcase
        end
    end

endmodule