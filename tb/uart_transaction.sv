class uart_transaction extends uvm_sequence_item;
    rand logic [7:0] data;                 
    rand bit inject_parity_error; 
    rand bit inject_framing_error; 
    
    rand int delay_before_send;   

    logic parity_error_detected;
    logic framing_error_detected;

    `uvm_object_utils_begin(uart_transaction)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(inject_parity_error, UVM_ALL_ON)
        `uvm_field_int(inject_framing_error, UVM_ALL_ON)
        `uvm_field_int(delay_before_send, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(parity_error_detected, UVM_ALL_ON)
        `uvm_field_int(framing_error_detected, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "uart_transaction");
        super.new(name);
    endfunction

    constraint c_parity_err_dist {
        inject_parity_error dist {0 := 90, 1 := 10}; 
    }

    constraint c_framing_err_dist {
        inject_framing_error dist {0 := 95, 1 := 5};
    }

    constraint c_delay_dist {
        delay_before_send inside {[0:20]};
    }

endclass