class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)
    uvm_sequencer #(uart_transaction) sqr;
    uart_driver                       drv;
    uart_monitor                      mon;

    bit is_tx_agent = 0; 

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        uvm_config_db#(bit)::get(this, "", "is_tx_agent", is_tx_agent);

        if (is_tx_agent == 1) begin
            is_active = UVM_PASSIVE;
        end else begin
            is_active = UVM_ACTIVE; 
        end

        mon = uart_monitor::type_id::create("mon", this);
        
        mon.is_tx_monitor = this.is_tx_agent;

        if (is_active == UVM_ACTIVE) begin
            sqr = uvm_sequencer#(uart_transaction)::type_id::create("sqr", this);
            drv = uart_driver::type_id::create("drv", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass