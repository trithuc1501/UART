module baud_rate_generator #(

    parameter int CLK_FREQ    = 50_000_000,  
    parameter int BAUD_RATE   = 9_600,       

    parameter int CLK_PER_TICK = CLK_FREQ / (BAUD_RATE * 16),

    parameter int TICK_BITS   = $clog2(CLK_PER_TICK)
) (
    input  logic i_clk,
    input  logic i_reset_n,
    output logic o_baud_tick
);

    logic [TICK_BITS-1:0] tick_counter;

    always_ff @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
            tick_counter <= '0;
            o_baud_tick  <= 1'b0;
        end else begin
            o_baud_tick <= 1'b0; 

            if (tick_counter == CLK_PER_TICK[TICK_BITS-1:0] - 1'b1) begin
                tick_counter <= '0;
                o_baud_tick  <= 1'b1;  
            end else begin
                tick_counter <= tick_counter + 1'd1;
            end
        end
    end
endmodule