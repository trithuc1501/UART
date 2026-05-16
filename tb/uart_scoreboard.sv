class uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uart_scoreboard)

    `uvm_analysis_imp_decl(_rx)
    `uvm_analysis_imp_decl(_tx)

    uvm_analysis_imp_rx #(uart_transaction, uart_scoreboard) rx_imp;
    uvm_analysis_imp_tx #(uart_transaction, uart_scoreboard) tx_imp;

    logic [7:0] ref_queue[$];
    bit         ref_perr_queue[$];

    int match_count        = 0;
    int match_with_perr    = 0;
    int mismatch_count     = 0;
    int drop_count         = 0;
    int framing_drop_count = 0;
    int parity_err_count   = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        rx_imp = new("rx_imp", this);
        tx_imp = new("tx_imp", this);
    endfunction

    virtual function void write_rx(uart_transaction tr);

        if (tr.framing_error_detected) begin
            framing_drop_count++;
            `uvm_info("SCB_RX",
                $sformatf("Framing error - DUT correctly dropped the frame. data=0x%02h", tr.data),
                UVM_MEDIUM)
            return;
        end

        if (tr.o_fifo_full) begin
            drop_count++;
            `uvm_info("SCB_RX",
                $sformatf("FIFO Full - data=0x%02h dropped.", tr.data),
                UVM_MEDIUM)
            return;
        end

        if (tr.parity_error_detected) begin
            parity_err_count++;
            ref_queue.push_back(tr.data);
            ref_perr_queue.push_back(1'b1);
            `uvm_info("SCB_RX",
                $sformatf("Parity error - DUT received: data=0x%02h -> pushed to ref_queue [perr]. Depth=%0d",
                          tr.data, ref_queue.size()),
                UVM_MEDIUM)
            return;
        end

        ref_queue.push_back(tr.data);
        ref_perr_queue.push_back(1'b0);
        `uvm_info("SCB_RX",
            $sformatf("Normal frame: data=0x%02h → push ref_queue. Depth=%0d",
                      tr.data, ref_queue.size()),
            UVM_DEBUG)
    endfunction

    virtual function void write_tx(uart_transaction tr);
        logic [7:0] expected_data;
        bit         was_parity_err;

        if (ref_queue.size() == 0) begin
            `uvm_error("SCB_TX",
                $sformatf("TX received 0x%02h but ref_queue is empty - DUT transmitted an extra byte.", tr.data))
            mismatch_count++;
            return;
        end

        expected_data  = ref_queue.pop_front();
        was_parity_err = ref_perr_queue.pop_front();

        if (tr.data !== expected_data) begin
            mismatch_count++;
            `uvm_error("SCB_CMP",
                $sformatf("MISMATCH: TX=0x%02h, Expected=0x%02h%s",
                          tr.data, expected_data,
                          was_parity_err ? "[This frame has injected parity error]" : ""))
            return;
        end

        if (was_parity_err) begin
            match_with_perr++;
            `uvm_info("SCB_CMP",
                $sformatf("MATCH [parity error expected]: data=0x%02h",
                          tr.data),
                UVM_LOW)
        end else begin
            match_count++;
            `uvm_info("SCB_CMP",
                $sformatf("MATCH: data=0x%02h", tr.data),
                UVM_LOW)
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        bit pass;
        super.report_phase(phase);

        pass = (mismatch_count == 0) &&
               (ref_queue.size() == 0) &&
               (match_count + match_with_perr > 0);

        `uvm_info("SCB_SUM", "================================================", UVM_LOW)
        `uvm_info("SCB_SUM", "       SCOREBOARD VERIFICATION SUMMARY          ", UVM_LOW)
        `uvm_info("SCB_SUM", "================================================", UVM_LOW)
        `uvm_info("SCB_SUM", $sformatf("  PASS  Match (clean)           : %0d", match_count),       UVM_LOW)
        `uvm_info("SCB_SUM", $sformatf("  PASS  Match (parity err exp)  : %0d", match_with_perr),   UVM_LOW)
        `uvm_info("SCB_SUM", $sformatf("  PASS  Framing drop (expected) : %0d", framing_drop_count),UVM_LOW)
        `uvm_info("SCB_SUM", $sformatf("  PASS  FIFO full drop          : %0d", drop_count),        UVM_LOW)
        `uvm_info("SCB_SUM", $sformatf("  FAIL  Mismatch (real bug)     : %0d", mismatch_count),    UVM_LOW)
        `uvm_info("SCB_SUM", $sformatf("  INFO  Remaining in ref_queue  : %0d", ref_queue.size()),  UVM_LOW)
        `uvm_info("SCB_SUM", "------------------------------------------------", UVM_LOW)

        if (pass)
            `uvm_info("SCB_SUM",  "  >>> RESULT: PASS <<<", UVM_LOW)
        else
            `uvm_error("SCB_SUM", "  >>> RESULT: FAIL <<<")

        `uvm_info("SCB_SUM", "================================================", UVM_LOW)
    endfunction

endclass