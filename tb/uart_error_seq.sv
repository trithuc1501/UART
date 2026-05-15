class uart_error_seq extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_error_seq)

    int unsigned n_pre  = 3;
    int unsigned n_err  = 4;
    int unsigned n_rec  = 3;
    int unsigned n_both = 2;
    int unsigned n_post = 4;

    int unsigned frame_delay = 8;

    function new(string name = "uart_error_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("ERR_SEQ", "======== Starting Error Injection Sequence ========", UVM_LOW)

        `uvm_info("ERR_SEQ", "[Phase 1] Normal baseline", UVM_LOW)
        send_clean_frames(n_pre, "pre");

        `uvm_info("ERR_SEQ", "[Phase 2] Inject PARITY ERROR", UVM_LOW)
        send_error_frames(n_err, 1'b1, 1'b0, "parity");

        `uvm_info("ERR_SEQ", "[Phase 3] Recovery after parity error", UVM_LOW)
        send_clean_frames(n_rec, "rec_parity");

        `uvm_info("ERR_SEQ", "[Phase 4] Inject FRAMING ERROR", UVM_LOW)
        send_error_frames(n_err, 1'b0, 1'b1, "framing");

        `uvm_info("ERR_SEQ", "[Phase 5] Recovery after parity error", UVM_LOW)
        send_clean_frames(n_rec, "rec_framing");

        `uvm_info("ERR_SEQ", "[Phase 6] Injecting PARITY + FRAMING errors simultaneously", UVM_LOW)
        send_error_frames(n_both, 1'b1, 1'b1, "both");

        `uvm_info("ERR_SEQ", "[Phase 7] Final healthy check", UVM_LOW)
        send_clean_frames(n_post, "post");

        `uvm_info("ERR_SEQ", "======== Error Injection Sequence completed ========", UVM_LOW)
    endtask

    local task send_clean_frames(int unsigned n, string tag);
        uart_transaction tr;
        for (int i = 0; i < n; i++) begin
            tr = uart_transaction::type_id::create(
                     $sformatf("tr_%s_%0d", tag, i));
            start_item(tr);
            if (!tr.randomize() with {
                inject_parity_error  == 1'b0;
                inject_framing_error == 1'b0;
                delay_before_send    == frame_delay;
            }) begin
                `uvm_error("ERR_SEQ", "Failed to randomize clean frame!")
            end
            `uvm_info("ERR_SEQ", $sformatf("  [%s][%0d] CLEAN  data=0x%02h", tag, i, tr.data), UVM_MEDIUM)
            finish_item(tr);
        end
    endtask

    local task send_error_frames(
        int unsigned n,
        bit parity_err,
        bit framing_err,
        string tag
    );
        uart_transaction tr;
        for (int i = 0; i < n; i++) begin
            tr = uart_transaction::type_id::create(
                     $sformatf("tr_%s_%0d", tag, i));
            start_item(tr);
            if (!tr.randomize() with {
                inject_parity_error  == parity_err;
                inject_framing_error == framing_err;
                delay_before_send    == frame_delay;
            }) begin
                `uvm_error("ERR_SEQ", "Failed to randomize error frame!")
            end
            `uvm_info("ERR_SEQ", $sformatf("  [%s][%0d] ERROR  data=0x%02h  P=%0b F=%0b", tag, i, tr.data, parity_err, framing_err), UVM_MEDIUM)
            finish_item(tr);
        end
    endtask

endclass