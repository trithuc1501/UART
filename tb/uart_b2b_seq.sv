class uart_b2b_seq extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_b2b_seq)

    int unsigned num_bytes      = 20;
    bit          randomize_data = 1'b1;

    function new(string name = "uart_b2b_seq");
        super.new(name);
    endfunction

    virtual task body();
        uart_transaction tr;

        `uvm_info("B2B_SEQ", $sformatf("Starting back-to-back sequence: %0d bytes, delay = 0", num_bytes), UVM_LOW)

        for (int i = 0; i < num_bytes; i++) begin
            tr = uart_transaction::type_id::create(
                     $sformatf("tr_b2b_%0d", i));

            start_item(tr);

            if (randomize_data) begin
                
                if (!tr.randomize() with {
                    inject_parity_error  == 1'b0;
                    inject_framing_error == 1'b0;
                    delay_before_send    == 0;
                }) begin
                    `uvm_error("B2B_SEQ", "Randomization failed!")
                end
            end else begin
                
                if (!tr.randomize() with {
                    data                == (i % 256);
                    inject_parity_error  == 1'b0;
                    inject_framing_error == 1'b0;
                    delay_before_send    == 0;
                }) begin
                    `uvm_error("B2B_SEQ", "Randomization failed!")
                end
            end

            `uvm_info("B2B_SEQ", $sformatf("[%0d/%0d] Sending 0x%02h (delay=0)", i + 1, num_bytes, tr.data), UVM_HIGH)

            finish_item(tr);
        end

        `uvm_info("B2B_SEQ", $sformatf("Back-to-back sequence completed. Sent %0d bytes.", num_bytes), UVM_LOW)
    endtask

endclass