class uart_driver extends uvm_driver #(uart_transaction);
    `uvm_component_utils(uart_driver)

    virtual uart_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Không thể lấy virtual interface cho uart_driver")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.drv_cb.i_rx_serial <= 1'b1;

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_item(uart_transaction tr);
        bit parity_bit;
        int clks_per_bit = 16 * (vif.CLK_FREQ / (vif.BAUD_RATE * 16));

        repeat(tr.delay_before_send) @(vif.drv_cb);

        `uvm_info("DRV", $sformatf("Đang gửi byte: 0x%0h (Parity Err: %0b, Framing Err: %0b)", 
                  tr.data, tr.inject_parity_error, tr.inject_framing_error), UVM_LOW)

        vif.drv_cb.i_rx_serial <= 1'b0;
        repeat(clks_per_bit) @(vif.drv_cb);

        for (int i = 0; i < vif.DATA_WIDTH; i++) begin
            vif.drv_cb.i_rx_serial <= tr.data[i];
            repeat(clks_per_bit) @(vif.drv_cb);
        end

        if (vif.PARITY_EN) begin
            parity_bit = (vif.PARITY_IS_EVEN) ? ^tr.data : ~(^tr.data);
            
            if (tr.inject_parity_error) parity_bit = ~parity_bit;
            
            vif.drv_cb.i_rx_serial <= parity_bit;
            repeat(clks_per_bit) @(vif.drv_cb);
        end
        vif.drv_cb.i_rx_serial <= (tr.inject_framing_error) ? 1'b0 : 1'b1;
        repeat(clks_per_bit) @(vif.drv_cb);

        vif.drv_cb.i_rx_serial <= 1'b1;
    endtask

endclass