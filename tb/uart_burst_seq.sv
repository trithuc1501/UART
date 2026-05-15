class uart_burst_seq extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_burst_seq)

    int unsigned num_bursts            = 4;
    int unsigned bytes_per_burst       = 5;
    int unsigned burst_inner_delay_max = 3;
    int unsigned burst_gap_min         = 30;
    int unsigned burst_gap_max         = 80;

    function new(string name = "uart_burst_seq");
        super.new(name);
    endfunction

    virtual task body();
        uart_transaction tr;
        int gap_delay;

        `uvm_info("BURST_SEQ",
            $sformatf("Starting burst sequence: %0d bursts × %0d bytes/burst",
                      num_bursts, bytes_per_burst),
            UVM_LOW)

        for (int b = 0; b < num_bursts; b++) begin

            `uvm_info("BURST_SEQ",
                $sformatf("--- Burst %0d/%0d ---", b + 1, num_bursts),
                UVM_MEDIUM)

            for (int i = 0; i < bytes_per_burst; i++) begin
                tr = uart_transaction::type_id::create(
                         $sformatf("tr_burst%0d_%0d", b, i));

                start_item(tr);

                if (!tr.randomize() with {
                    inject_parity_error  == 1'b0;
                    inject_framing_error == 1'b0;
                    
                    delay_before_send inside {[0 : burst_inner_delay_max]};
                }) begin
                    `uvm_error("BURST_SEQ", "Randomization failed!")
                end

                `uvm_info("BURST_SEQ", $sformatf("  Byte[%0d] = 0x%02h, delay = %0d", i, tr.data, tr.delay_before_send),
                    UVM_HIGH)

                finish_item(tr);
            end

            if (b < num_bursts - 1) begin
                gap_delay = $urandom_range(burst_gap_max, burst_gap_min);

                `uvm_info("BURST_SEQ", $sformatf("Idle time between bursts: %0d cycles", gap_delay), UVM_MEDIUM)

                tr = uart_transaction::type_id::create(
                         $sformatf("tr_gap_%0d", b));
                start_item(tr);

                if (!tr.randomize() with {
                    inject_parity_error  == 1'b0;
                    inject_framing_error == 1'b0;
                    
                }) begin
                    `uvm_error("BURST_SEQ", "Randomization gap failed!")
                end
                tr.delay_before_send = gap_delay;

                finish_item(tr);
            end
        end

        `uvm_info("BURST_SEQ", $sformatf("Burst sequence completed. Total: %0d bytes.", num_bursts * bytes_per_burst), UVM_LOW)
    endtask

endclass