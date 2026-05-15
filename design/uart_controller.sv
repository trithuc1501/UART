module uart_controller #(
    parameter int CLK_FREQ       = 50_000_000,
    parameter int BAUD_RATE      = 9_600,
    parameter int DATA_WIDTH     = 8,
    parameter bit PARITY_EN      = 1,
    parameter bit PARITY_IS_EVEN = 1,
    parameter int FIFO_DEPTH     = 16
) (
    input  logic i_clk,
    input  logic i_reset_n,

    input  logic i_rx_serial,
    output logic o_tx_serial,

    output logic o_rx_error,
    output logic o_parity_error,
    output logic o_tx_busy,
    output logic o_fifo_full,
    output logic o_fifo_empty
);

    logic baud_tick;

    baud_rate_generator #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_baud_gen (
        .i_clk      (i_clk),
        .i_reset_n  (i_reset_n),
        .o_baud_tick(baud_tick)
    );

    logic [DATA_WIDTH-1:0] rx_data;
    logic                  rx_valid;

    uart_rx #(
        .DATA_WIDTH    (DATA_WIDTH),
        .PARITY_EN     (PARITY_EN),
        .PARITY_IS_EVEN(PARITY_IS_EVEN)
    ) u_uart_rx (
        .i_clk          (i_clk),
        .i_reset_n      (i_reset_n),
        .i_baud_tick    (baud_tick),
        .i_rx_serial    (i_rx_serial),
        .o_data_parallel(rx_data),
        .o_data_valid   (rx_valid),
        .o_rx_error     (o_rx_error),
        .o_parity_error (o_parity_error)
    );

    logic                  fifo_wen;
    logic                  fifo_ren;
    logic [DATA_WIDTH-1:0] fifo_rdata;
    logic                  fifo_full;
    logic                  fifo_empty;
    assign fifo_wen = rx_valid & ~fifo_full;

    fifo_sync #(
        .Depth(FIFO_DEPTH),
        .Width(DATA_WIDTH)
    ) u_fifo (
        .clk   (i_clk),
        .rst_n (i_reset_n),
        .w_en  (fifo_wen),
        .r_en  (fifo_ren),
        .w_data(rx_data),
        .r_data(fifo_rdata),
        .full  (fifo_full),
        .empty (fifo_empty)
    );

    assign o_fifo_full  = fifo_full;
    assign o_fifo_empty = fifo_empty;

    typedef enum logic [1:0] {
        S_IDLE = 2'd0,
        S_READ = 2'd1,  
        S_LOAD = 2'd2, 
        S_WAIT = 2'd3   
    } tx_ctrl_t;

    tx_ctrl_t              tx_ctrl_state;
    logic [DATA_WIDTH-1:0] tx_data_latch;
    logic                  tx_start;
    logic                  tx_busy;

    always_ff @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
            tx_ctrl_state <= S_IDLE;
            fifo_ren      <= 1'b0;
            tx_start      <= 1'b0;
            tx_data_latch <= '0;
        end else begin

            fifo_ren <= 1'b0;
            tx_start <= 1'b0;

            unique case (tx_ctrl_state)

                S_IDLE: begin
                    if (!fifo_empty && !tx_busy) begin
                        fifo_ren      <= 1'b1;
                        tx_ctrl_state <= S_READ;
                    end
                end

                S_READ: begin
                    tx_ctrl_state <= S_LOAD;
                end

                S_LOAD: begin
                    tx_data_latch <= fifo_rdata;
                    tx_start      <= 1'b1;
                    tx_ctrl_state <= S_WAIT;
                end


                S_WAIT: begin
                    if (!tx_busy) begin
                        tx_ctrl_state <= S_IDLE;
                    end
                end

                default: tx_ctrl_state <= S_IDLE;

            endcase
        end
    end

    uart_tx #(
        .DATA_WIDTH    (DATA_WIDTH),
        .PARITY_EN     (PARITY_EN),
        .PARITY_IS_EVEN(PARITY_IS_EVEN)
    ) u_uart_tx (
        .i_clk      (i_clk),
        .i_reset_n  (i_reset_n),
        .i_baud_tick(baud_tick),
        .i_tx_start (tx_start),
        .i_data_in  (tx_data_latch),
        .o_tx_serial(o_tx_serial),
        .o_tx_busy  (tx_busy)
    );

    assign o_tx_busy = tx_busy;
endmodule