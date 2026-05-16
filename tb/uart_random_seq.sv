class uart_random_seq extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_random_seq)

    int unsigned num_tx = 20;

    function new(string name = "uart_random_seq");
        super.new(name);
    endfunction 

    virtual task body();
        uart_transaction req;

        `uvm_info("RANDOM_SEQ", $sformatf("Starting random transmission sequence of %0d bytes...", num_tx), UVM_LOW)

        repeat(num_tx) begin
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