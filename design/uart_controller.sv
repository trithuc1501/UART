module uart_controller #(
    parameter int  CLK_FREQ       = 50_000_000,
    parameter int  BAUD_RATE      = 9_600,
    parameter int  DATA_WIDTH     = 8,
    parameter bit  PARITY_EN      = 1,
    parameter bit  PARITY_IS_EVEN = 1,
    parameter int  FIFO_DEPTH     = 16
) (
    input  logic i_clk,
    input  logic i_reset_n,

    input  logic i_rx_serial,
    output logic o_tx_serial,

    output logic o_rx_error,      
    output logic o_parity_error,   
    output logic o_tx_busy,      
    output logic o_rx_fifo_full,  
    output logic o_tx_fifo_empty  
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
    logic                  rx_err;
    logic                  rx_par_err;

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
        .o_rx_error     (rx_err),
        .o_parity_error (rx_par_err)
    );

    logic                  rx_fifo_wen;
    logic                  rx_fifo_ren;
    logic [DATA_WIDTH-1:0] rx_fifo_rdata;
    logic                  rx_fifo_full;
    logic                  rx_fifo_empty;

    assign rx_fifo_wen = rx_valid && !rx_fifo_full;

    fifo_sync #(
        .Depth(FIFO_DEPTH),
        .Width(DATA_WIDTH)
    ) u_rx_fifo (
        .clk   (i_clk),
        .rst_n (i_reset_n),
        .w_en  (rx_fifo_wen),
        .r_en  (rx_fifo_ren),
        .w_data(rx_data),
        .r_data(rx_fifo_rdata),
        .full  (rx_fifo_full),
        .empty (rx_fifo_empty)
    );

    logic                  tx_fifo_wen;
    logic [DATA_WIDTH-1:0] tx_fifo_wdata;
    logic                  tx_fifo_ren;
    logic [DATA_WIDTH-1:0] tx_fifo_rdata;
    logic                  tx_fifo_full;
    logic                  tx_fifo_empty;

    fifo_sync #(
        .Depth(FIFO_DEPTH),
        .Width(DATA_WIDTH)
    ) u_tx_fifo (
        .clk   (i_clk),
        .rst_n (i_reset_n),
        .w_en  (tx_fifo_wen),
        .r_en  (tx_fifo_ren),
        .w_data(tx_fifo_wdata),
        .r_data(tx_fifo_rdata),
        .full  (tx_fifo_full),
        .empty (tx_fifo_empty)
    );

    logic                  bridge_ren;
    logic                  bridge_wen_d;
    logic [DATA_WIDTH-1:0] bridge_wdata_d;

    assign bridge_ren  = !rx_fifo_empty && !tx_fifo_full;
    assign rx_fifo_ren = bridge_ren;

    always_ff @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
            bridge_wen_d   <= 1'b0;
            bridge_wdata_d <= '0;
        end else begin
            bridge_wen_d   <= bridge_ren;
            bridge_wdata_d <= rx_fifo_rdata;
        end
    end

    assign tx_fifo_wen   = bridge_wen_d;
    assign tx_fifo_wdata = bridge_wdata_d;

    typedef enum logic [2:0] {
        S_IDLE = 3'd0,
        S_READ = 3'd1,
        S_LOAD = 3'd2,
        S_SEND = 3'd3,
        S_WAIT = 3'd4
    } tx_ctrl_t;

    tx_ctrl_t              tx_ctrl_state;
    logic [DATA_WIDTH-1:0] tx_data_latch;
    logic                  tx_start;
    logic                  tx_busy;
    logic                  tx_fifo_ren_fsm;

    assign tx_fifo_ren = tx_fifo_ren_fsm;

    always_ff @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
            tx_ctrl_state   <= S_IDLE;
            tx_fifo_ren_fsm <= 1'b0;
            tx_start        <= 1'b0;
            tx_data_latch   <= '0;
        end else begin
            tx_fifo_ren_fsm <= 1'b0;
            tx_start        <= 1'b0;

            unique case (tx_ctrl_state)

                S_IDLE: begin
                    if (!tx_fifo_empty && !tx_busy) begin
                        tx_fifo_ren_fsm <= 1'b1;
                        tx_ctrl_state   <= S_READ;
                    end
                end

                S_READ: begin
                    tx_ctrl_state <= S_LOAD;
                end

                S_LOAD: begin
                    tx_data_latch <= tx_fifo_rdata;
                    tx_start      <= 1'b1;
                    tx_ctrl_state <= S_SEND;
                end

                S_SEND: begin
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

    assign o_rx_error      = rx_err;
    assign o_parity_error  = rx_par_err;
    assign o_tx_busy       = tx_busy;
    assign o_rx_fifo_full  = rx_fifo_full;
    assign o_tx_fifo_empty = tx_fifo_empty;

endmodule