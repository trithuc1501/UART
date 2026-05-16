class uart_master_seq extends uvm_sequence;
    `uvm_object_utils(uart_master_seq)

    bit run_directed = 1'b1;
    bit run_b2b      = 1'b1;
    bit run_burst    = 1'b1;
    bit run_error    = 1'b1;
    bit run_random   = 1'b1;

    int unsigned directed_inter_delay = 5;

    int unsigned b2b_num_bytes      = 20;
    bit          b2b_randomize_data = 1'b1;

    int unsigned burst_num_bursts      = 4;
    int unsigned burst_bytes_per_burst = 5;
    int unsigned burst_gap_min         = 30;
    int unsigned burst_gap_max         = 80;

    int unsigned err_n_pre  = 3;
    int unsigned err_n_err  = 4;
    int unsigned err_n_rec  = 3;
    int unsigned err_n_both = 2;
    int unsigned err_n_post = 4;

    int unsigned random_num_tx = 20; 

    function new(string name = "uart_master_seq");
        super.new(name);
    endfunction

    virtual task body();

        `uvm_info("MASTER_SEQ", "==================================================", UVM_LOW)
        `uvm_info("MASTER_SEQ", "           STARTING UART MASTER SEQUENCE          ", UVM_LOW)
        `uvm_info("MASTER_SEQ", "==================================================", UVM_LOW)

        if (run_directed) begin
            uart_directed_seq dir_seq;
            `uvm_info("MASTER_SEQ", " Phase 1: Directed Sequence", UVM_LOW)

            dir_seq = uart_directed_seq::type_id::create("dir_seq");
            dir_seq.inter_frame_delay = directed_inter_delay;
            dir_seq.start(m_sequencer, this);

            `uvm_info("MASTER_SEQ", " Phase 1 completed.", UVM_LOW)
        end else begin
            `uvm_info("MASTER_SEQ", " Phase 1 (Directed) skipped.", UVM_LOW)
        end

        if (run_b2b) begin
            uart_b2b_seq b2b_seq;
            `uvm_info("MASTER_SEQ", " Phase 2: Back-to-Back Sequence", UVM_LOW)

            b2b_seq = uart_b2b_seq::type_id::create("b2b_seq");
            b2b_seq.num_bytes      = b2b_num_bytes;
            b2b_seq.randomize_data = b2b_randomize_data;
            b2b_seq.start(m_sequencer, this);

            `uvm_info("MASTER_SEQ", " Phase 2 completed.", UVM_LOW)
        end else begin
            `uvm_info("MASTER_SEQ", " Phase 2 (B2B) skipped.", UVM_LOW)
        end

        if (run_burst) begin
            uart_burst_seq bst_seq;
            `uvm_info("MASTER_SEQ", " Phase 3: Burst Sequence", UVM_LOW)

            bst_seq = uart_burst_seq::type_id::create("bst_seq");
            bst_seq.num_bursts      = burst_num_bursts;
            bst_seq.bytes_per_burst = burst_bytes_per_burst;
            bst_seq.burst_gap_min   = burst_gap_min;
            bst_seq.burst_gap_max   = burst_gap_max;
            bst_seq.start(m_sequencer, this);

            `uvm_info("MASTER_SEQ", " Phase 3 completed.", UVM_LOW)
        end else begin
            `uvm_info("MASTER_SEQ", " Phase 3 (Burst) skipped.", UVM_LOW)
        end

        if (run_error) begin
            uart_error_seq err_seq;
            `uvm_info("MASTER_SEQ", " Phase 4: Error Injection Sequence", UVM_LOW)

            err_seq = uart_error_seq::type_id::create("err_seq");
            err_seq.n_pre  = err_n_pre;
            err_seq.n_err  = err_n_err;
            err_seq.n_rec  = err_n_rec;
            err_seq.n_both = err_n_both;
            err_seq.n_post = err_n_post;
            err_seq.start(m_sequencer, this);

            `uvm_info("MASTER_SEQ", " Phase 4 completed.", UVM_LOW)
        end else begin
            `uvm_info("MASTER_SEQ", " Phase 4 (Error) skipped.", UVM_LOW)
        end

        if (run_random) begin
            uart_random_seq rand_seq;
            `uvm_info("MASTER_SEQ", " Phase 5: Random Sequence", UVM_LOW)

            rand_seq = uart_random_seq::type_id::create("rand_seq");
            rand_seq.num_tx = random_num_tx; 
            rand_seq.start(m_sequencer, this);

            `uvm_info("MASTER_SEQ", " Phase 5 completed.", UVM_LOW)
        end else begin
            `uvm_info("MASTER_SEQ", " Phase 5 (Random) skipped.", UVM_LOW)
        end

        `uvm_info("MASTER_SEQ", "==================================================", UVM_LOW)
        `uvm_info("MASTER_SEQ", "          UART MASTER SEQUENCE COMPLETED          ", UVM_LOW)
        `uvm_info("MASTER_SEQ", "==================================================", UVM_LOW)

    endtask

endclass