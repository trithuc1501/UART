interface uart_if#(
    parameter int CLK_FREQ       = 50_000_000,
    parameter int BAUD_RATE      = 9_600,
    parameter int DATA_WIDTH     = 8,
    parameter bit PARITY_EN      = 1,
    parameter bit PARITY_IS_EVEN = 1,
    parameter int FIFO_DEPTH     = 16
)(
    input  logic i_clk,
    input  logic i_reset_n
);

    logic i_rx_serial;
    logic o_tx_serial;

    logic o_rx_error;
    logic o_parity_error;
    logic o_tx_busy;
    logic o_fifo_full;
    logic o_fifo_empty;

    logic fifo_wen;
    logic fifo_ren;
    logic [$clog2(FIFO_DEPTH):0] fifo_r_ptr;
    logic [$clog2(FIFO_DEPTH):0] fifo_w_ptr;

    logic tx_start;

    clocking drv_cb @(posedge i_clk);
        default input #1ns output #1ns;
        output i_rx_serial;
        input o_tx_serial;

        input o_rx_error;
        input o_parity_error;
        input o_tx_busy;
        input o_fifo_full;
        input o_fifo_empty;
    endclocking

    clocking mon_cb @(posedge i_clk);
        default input #1ns output #1ns;
        input i_rx_serial;
        input o_tx_serial;
        
        input o_rx_error;
        input o_parity_error;
        input o_tx_busy;
        input o_fifo_full;
        input o_fifo_empty;
    endclocking

    modport DRV (clocking drv_cb, input i_clk, i_reset_n);
    modport MON (clocking mon_cb, input i_clk, i_reset_n);
      
    property p_mutex_flags;
      @(posedge i_clk) disable iff (!i_reset_n)
      !(o_fifo_full && o_fifo_empty);
    endproperty

    A_MUTEX_FLAGS : assert property(p_mutex_flags) 
                    else $fatal(1, "[SVA] FATAL ERROR: FIFO is both FULL and EMPTY at the same time!");

    property p_empty_stable;
      @(posedge i_clk) disable iff (!i_reset_n)
      (o_fifo_empty && !fifo_wen) |=> o_fifo_empty;
    endproperty

    A_EMPTY_STABLE: assert property(p_empty_stable) 
                    else $error("[SVA] ERROR: EMPTY flag deasserted without any Write command!");

    property p_full_stable;
      @(posedge i_clk) disable iff (!i_reset_n)
      (o_fifo_full && !fifo_ren) |=> o_fifo_full;
    endproperty

    A_FULL_STABLE : assert property(p_full_stable) 
                    else $error("[SVA] ERROR: FULL flag deasserted without any Read command!");
    
    property p_no_fifo_overflow;
        @(posedge i_clk) disable iff (!i_reset_n)
        o_fifo_full |-> !fifo_wen;
    endproperty

    A_NO_FIFO_OVERFLOW: assert property(p_no_fifo_overflow)
        else $error("[SVA] OVERFLOW: Attempted to write (fifo_wen=1) while FIFO is FULL!");

    property p_no_fifo_underflow;
        @(posedge i_clk) disable iff (!i_reset_n)
        o_fifo_empty |-> !fifo_ren;
    endproperty

    A_NO_FIFO_UNDERFLOW: assert property(p_no_fifo_underflow)
        else $error("[SVA] UNDERFLOW: Attempted to read (fifo_ren=1) while FIFO is EMPTY!");

    property p_tx_handshake_start;
        @(posedge i_clk) disable iff (!i_reset_n)
        $rose(tx_start) |-> ##[1:2] $rose(o_tx_busy);
    endproperty

    A_TX_HANDSHAKE: assert property(p_tx_handshake_start)
        else $error("[SVA] DEADLOCK: tx_start triggered but o_tx_busy did not respond!");

    property p_tx_busy_min_width;
        @(posedge i_clk) disable iff (!i_reset_n)
        $rose(o_tx_busy) |=> o_tx_busy;
    endproperty
    
    A_TX_BUSY_GLITCH: assert property(p_tx_busy_min_width)
        else $error("[SVA] FSM ERROR: o_tx_busy deasserted too quickly (glitch detected)!");

endinterface
