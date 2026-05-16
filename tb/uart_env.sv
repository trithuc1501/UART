class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)

    uart_agent              rx_agt; 
    uart_agent              tx_agt; 
    uart_scoreboard         scb;
    uart_coverage_collector cov;   

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        scb = uart_scoreboard::type_id::create("scb", this);

        rx_agt = uart_agent::type_id::create("rx_agt", this);

        uvm_config_db#(bit)::set(this, "rx_agt", "is_tx_agent", 0);

        tx_agt = uart_agent::type_id::create("tx_agt", this);
        
        uvm_config_db#(bit)::set(this, "tx_agt", "is_tx_agent", 1);

        cov = uart_coverage_collector::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        rx_agt.mon.item_collected_port.connect(scb.rx_imp);
        tx_agt.mon.item_collected_port.connect(scb.tx_imp);
        rx_agt.mon.item_collected_port.connect(cov.analysis_export);
    endfunction
endclass