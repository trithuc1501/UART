class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    virtual uart_if vif;
    
    bit is_tx_monitor = 0;

    uvm_analysis_port #(uart_transaction) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON_NOVIF", "Không thể lấy virtual interface cho monitor")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            collect_transaction();
        end
    endtask

    virtual task collect_transaction();
        uart_transaction tr;
        logic current_bit;

        int clks_per_tick = vif.CLK_FREQ / (vif.BAUD_RATE * 16); 

        int clks_per_bit  = 16 * clks_per_tick;

        do begin
            @(vif.mon_cb);
            current_bit = (is_tx_monitor) ? vif.mon_cb.o_tx_serial : vif.mon_cb.i_rx_serial;
        end while (current_bit !== 1'b0);

        tr = uart_transaction::type_id::create("tr");

        repeat(8 * clks_per_tick) @(vif.mon_cb);
        current_bit = (is_tx_monitor) ? vif.mon_cb.o_tx_serial : vif.mon_cb.i_rx_serial;
        
        if (current_bit !== 1'b0) begin
            `uvm_info("MON", "Phát hiện nhiễu (Glitch) trên Start bit, bỏ qua frame.", UVM_HIGH)
            return;
        end

        for (int i = 0; i < vif.DATA_WIDTH; i++) begin
            repeat(clks_per_bit) @(vif.mon_cb);
            current_bit = (is_tx_monitor) ? vif.mon_cb.o_tx_serial : vif.mon_cb.i_rx_serial;
            tr.data[i] = current_bit;
        end

        if (vif.PARITY_EN) begin
            bit expected_parity;
            repeat(clks_per_bit) @(vif.mon_cb);
            current_bit = (is_tx_monitor) ? vif.mon_cb.o_tx_serial : vif.mon_cb.i_rx_serial;
            
            expected_parity = (vif.PARITY_IS_EVEN) ? ^tr.data : ~(^tr.data);
            
            if (current_bit !== expected_parity) begin
                tr.parity_error_detected = 1;
                `uvm_warning("MON", $sformatf("Lỗi Parity! Nhận: %b, Mong đợi: %b", current_bit, expected_parity))
            end
        end

        repeat(clks_per_bit) @(vif.mon_cb);
        current_bit = (is_tx_monitor) ? vif.mon_cb.o_tx_serial : vif.mon_cb.i_rx_serial;
        
        if (current_bit !== 1'b1) begin
            tr.framing_error_detected = 1;
            `uvm_error("MON", "Lỗi Framing! Stop bit không phải mức cao (1).")
        end

        item_collected_port.write(tr);
        
        `uvm_info("MON", $sformatf("%s giải mã xong: 0x%0h", 
                  (is_tx_monitor ? "TX" : "RX"), tr.data), UVM_MEDIUM)
    endtask

endclass