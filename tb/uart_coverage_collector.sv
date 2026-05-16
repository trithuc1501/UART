class uart_coverage_collector extends uvm_subscriber #(uart_transaction);
    `uvm_component_utils(uart_coverage_collector)

    covergroup cg_protocol with function sample(uart_transaction t);

        cp_data: coverpoint t.data {
            bins corner_zero     = {8'h00};
            bins corner_ff       = {8'hFF};
            bins checkerboard_55 = {8'h55};
            bins checkerboard_aa = {8'hAA};
            bins random_low      = {[8'h01 : 8'h54]};
            bins random_mid      = {[8'h56 : 8'hA9]};
            bins random_high     = {[8'hAB : 8'hFE]};
        }

        cp_parity_err: coverpoint t.inject_parity_error {
            bins no_parity_err  = {0};
            bins has_parity_err = {1};
        }

        cp_framing_err: coverpoint t.inject_framing_error {
            bins no_framing_err  = {0};
            bins has_framing_err = {1};
        }

        cp_error_type: coverpoint {t.inject_parity_error, t.inject_framing_error} {
            bins clean        = {2'b00};
            bins parity_only  = {2'b10};
            bins framing_only = {2'b01};
            bins both_errors  = {2'b11};
        }

    endgroup : cg_protocol

    covergroup cg_fifo with function sample(uart_transaction t);

        cp_fifo_empty: coverpoint t.o_fifo_full {
            bins not_full = {0};
            bins full     = {1};
        }

        cp_fifo_full: coverpoint t.o_fifo_full {
            bins not_full = {0};
            bins full     = {1};
        }

    endgroup : cg_fifo

    covergroup cg_cross with function sample(uart_transaction t);

        cp_parity_err_x: coverpoint t.inject_parity_error {
            bins no_err  = {0};
            bins has_err = {1};
        }

        cp_fifo_full_x: coverpoint t.o_fifo_full {
            bins not_full = {0};
            bins full     = {1};
        }

        cp_framing_err_x: coverpoint t.inject_framing_error {
            bins no_err  = {0};
            bins has_err = {1};
        }

        cross_parity_fifo:      cross cp_parity_err_x, cp_fifo_full_x;
        cross_framing_fifo:     cross cp_framing_err_x, cp_fifo_full_x;
        cross_both_errors_fifo: cross cp_parity_err_x, cp_framing_err_x, cp_fifo_full_x;

    endgroup : cg_cross

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_protocol = new();
        cg_fifo     = new();
        cg_cross    = new();
    endfunction


    virtual function void write(uart_transaction t);
        cg_protocol.sample(t);
        cg_fifo.sample(t);
        cg_cross.sample(t);
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COVERAGE", "==================== FUNCTIONAL COVERAGE REPORT ====================", UVM_NONE)
        `uvm_info("COVERAGE", $sformatf("  Protocol Coverage : %.2f%%", cg_protocol.get_coverage()), UVM_NONE)
        `uvm_info("COVERAGE", $sformatf("  FIFO Coverage     : %.2f%%", cg_fifo.get_coverage()), UVM_NONE)
        `uvm_info("COVERAGE", $sformatf("  Cross Coverage    : %.2f%%", cg_cross.get_coverage()), UVM_NONE)
        `uvm_info("COVERAGE", "====================================================================", UVM_NONE)
    endfunction

endclass