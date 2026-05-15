class uart_random_seq extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_random_seq)

    function new(string name = "uart_random_seq");
        super.new(name);
    endfunction

    virtual task body();
        uart_transaction req;

        `uvm_info("RANDOM_SEQ", "Starting random transmission sequence of 20 bytes...", UVM_LOW)

        repeat(20) begin
            req = uart_transaction::type_id::create("req");
            
            start_item(req);
            
            if (!req.randomize()) begin
                `uvm_error("RANDOM_SEQ", "Randomization failed!")
            end
            
            finish_item(req);
        end

        `uvm_info("RANDOM_SEQ", "The random sequence has been completed.", UVM_LOW)
    endtask
endclass