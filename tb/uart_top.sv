`timescale 1ns/1ps

`include "uart_if.sv"
`include "uart_pkg.sv"

module top_tb;
	import uvm_pkg::*;
  	import uart_pkg::*;
  
    logic clk;
    logic rst_n;

    localparam CLK_PERIOD = 20;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        rst_n = 0;
        #(CLK_PERIOD * 5) rst_n = 1;
    end

    uart_if #(
        .CLK_FREQ(50_000_000),
        .BAUD_RATE(9_600),
        .DATA_WIDTH(8),
        .PARITY_EN(1),
        .PARITY_IS_EVEN(1)
    ) u_if (
        .i_clk(clk),
        .i_reset_n(rst_n)
    );

    uart_controller #(
        .CLK_FREQ(50_000_000),
        .BAUD_RATE(9_600)
    ) DUT (
        .i_clk(u_if.i_clk),
        .i_reset_n(u_if.i_reset_n),
        .i_rx_serial(u_if.i_rx_serial),
        .o_tx_serial(u_if.o_tx_serial),
        .o_rx_error(u_if.o_rx_error),
        .o_parity_error(u_if.o_parity_error),
        .o_tx_busy(u_if.o_tx_busy),
        .o_fifo_full(u_if.o_fifo_full),
        .o_fifo_empty(u_if.o_fifo_empty)
    );

    assign u_if.fifo_wen = DUT.fifo_wen;
    assign u_if.fifo_ren = DUT.fifo_ren;

    assign u_if.fifo_w_ptr = DUT.u_fifo.w_ptr;
    assign u_if.fifo_r_ptr = DUT.u_fifo.r_ptr;

    initial begin
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.*", "vif", u_if);

        uvm_top.set_report_verbosity_level(UVM_MEDIUM);

        run_test("uart_master_test");
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top_tb);
    end

endmodule