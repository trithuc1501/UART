class uart_directed_seq extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_directed_seq)

    logic [7:0] directed_bytes[] = '{
        8'h00, 
        8'hFF,
        8'hAA, 
        8'h55,
        8'h01,
        8'h80,
        8'h0F,
        8'hF0
    };

    int unsigned inter_frame_delay = 5;

    function new(string name = "uart_directed_seq");
        super.new(name);
    endfunction

    virtual task body();
        uart_transaction tr;

        `uvm_info("DIR_SEQ", $sformatf("Starting directed sequence: %0d bytes corner-case", directed_bytes.size()), UVM_LOW)

        foreach (directed_bytes[i]) begin
            tr = uart_transaction::type_id::create( $sformatf("tr_directed_%0d", i));

            start_item(tr);

            if (!tr.randomize() with {
                data                == directed_bytes[i];
                inject_parity_error  == 1'b0;
                inject_framing_error == 1'b0;
                delay_before_send    == inter_frame_delay;
            }) begin
                `uvm_error("DIR_SEQ", "Randomization failed!")
            end

            `uvm_info("DIR_SEQ",
                $sformatf("[%0d/%0d] Send byte: 0x%02h", i + 1, directed_bytes.size(), tr.data), UVM_MEDIUM)

            finish_item(tr);
        end

        `uvm_info("DIR_SEQ", "The directed sequence has been completed.", UVM_LOW)
    endtask

endclass