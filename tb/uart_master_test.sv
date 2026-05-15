class uart_master_test extends uvm_test;
    `uvm_component_utils(uart_master_test)

    uart_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uart_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_master_seq mseq;

        phase.raise_objection(this);

        mseq = uart_master_seq::type_id::create("mseq");

        mseq.sqr = env.rx_agt.sqr;

        `uvm_info("MASTER_TEST", "Starting uart_master_test", UVM_LOW)

        mseq.start(null);

        #20ms;

        phase.drop_objection(this);

        `uvm_info("MASTER_TEST", "End uart_master_test.", UVM_LOW)
    endtask

endclass