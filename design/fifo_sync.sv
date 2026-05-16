module fifo_sync #(
    parameter Depth = 8,
    parameter Width = 8
)(
    input logic clk, rst_n, w_en, r_en,
    input logic [Width - 1:0] w_data,
    output logic [Width - 1:0] r_data,
    output logic full, empty
);
    localparam Depth_log = $clog2(Depth);

    logic [Width - 1:0] mem [Depth - 1:0];

    logic [Depth_log:0] r_ptr;
    logic [Depth_log:0] w_ptr;

    // write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr <= 0;
        end else if (w_en && !full) begin
            mem[w_ptr[Depth_log - 1:0]] <= w_data;
            w_ptr <= w_ptr + 1'b1;
        end 
    end

    //read
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_ptr <= 0;
            r_data <= 0;
        end else if (r_en && ! empty) begin
            r_data <= mem[r_ptr[Depth_log - 1:0]];
            r_ptr <= r_ptr + 1'b1;
        end 
    end

    assign empty = (r_ptr == w_ptr);
    assign full = (r_ptr[Depth_log] != w_ptr[Depth_log]) && 
              (r_ptr[Depth_log-1:0] == w_ptr[Depth_log-1:0]);

endmodule
