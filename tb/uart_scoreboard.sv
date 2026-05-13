class uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uart_scoreboard)

    `uvm_analysis_imp_decl(_rx)
    `uvm_analysis_imp_decl(_tx)

    uvm_analysis_imp_rx #(uart_transaction, uart_scoreboard) rx_imp;
    uvm_analysis_imp_tx #(uart_transaction, uart_scoreboard) tx_imp;

    logic [7:0] ref_queue[$];

    int match_count    = 0;
    int mismatch_count = 0;
    int drop_count     = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        rx_imp = new("rx_imp", this);
        tx_imp = new("tx_imp", this);
    endfunction

    virtual function void write_rx(uart_transaction tr);
        if (tr.framing_error_detected) begin
            `uvm_info("SCB_RX", "Phát hiện lỗi Framing: Bỏ qua gói tin (không vào FIFO).", UVM_HIGH)
            return;
        end

        if (tr.o_fifo_full) begin
            drop_count++;
            `uvm_info("SCB_RX", "FIFO Đầy: Dữ liệu bị drop.", UVM_MEDIUM)
            return;
        end

        ref_queue.push_back(tr.data);
        `uvm_info("SCB_RX", $sformatf("Đã thêm 0x%0h vào Ref Queue. Độ dài hiện tại: %0d", 
                  tr.data, ref_queue.size()), UVM_DEBUG)
    endfunction

    virtual function void write_tx(uart_transaction tr);
        logic [7:0] expected_data;

        if (ref_queue.size() == 0) begin
            `uvm_error("SCB_TX", $sformatf("LỖI: Nhận được dữ liệu TX (0x%0h) nhưng Ref Queue trống!", tr.data))
            mismatch_count++;
            return;
        end

        expected_data = ref_queue.pop_front();

        if (tr.data === expected_data) begin
            match_count++;
            `uvm_info("SCB_CMP", $sformatf("KHỚP: Dữ liệu = 0x%0h", tr.data), UVM_LOW)
        end else begin
            mismatch_count++;
            `uvm_error("SCB_CMP", $sformatf("SAI BIỆT: Thực tế = 0x%0h, Kỳ vọng = 0x%0h", 
                       tr.data, expected_data))
        end
    end function

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB_SUM", "--------------------------------------------------", UVM_LOW)
        `uvm_info("SCB_SUM", "        TỔNG KẾT KIỂM CHỨNG SCOREBOARD            ", UVM_LOW)
        `uvm_info("SCB_SUM", $sformatf("  - Số gói tin khớp (Matches):    %0d", match_count), UVM_LOW)
        `uvm_info("SCB_SUM", $sformatf("  - Số gói tin sai (Mismatches): %0d", mismatch_count), UVM_LOW)
        `uvm_info("SCB_SUM", $sformatf("  - Số gói tin bị bỏ (Drops):    %0d", drop_count), UVM_LOW)
        `uvm_info("SCB_SUM", $sformatf("  - Số gói tin còn lại trong Queue: %0d", ref_queue.size()), UVM_LOW)
        
        if (mismatch_count == 0 && ref_queue.size() == 0 && match_count > 0)
            `uvm_info("SCB_SUM", "  => KẾT QUẢ: PASS", UVM_LOW)
        else
            `uvm_error("SCB_SUM", "  => KẾT QUẢ: FAIL")
        `uvm_info("SCB_SUM", "--------------------------------------------------", UVM_LOW)
    endfunction

endclass