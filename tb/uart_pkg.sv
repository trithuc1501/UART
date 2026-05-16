package uart_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "uart_transaction.sv"   
         
    `include "uart_random_seq.sv"
    `include "uart_directed_seq.sv"
    `include "uart_b2b_seq.sv" 
    `include "uart_burst_seq.sv"
    `include "uart_error_seq.sv"
    `include "uart_master_seq.sv"

    `include "uart_driver.sv"          
    `include "uart_monitor.sv"         
    
    `include "uart_scoreboard.sv"  
    `include "uart_coverage_collector.sv"    
    
    `include "uart_agent.sv"           
    `include "uart_env.sv"            
    
    `include "uart_master_test.sv"    
    
endpackage : uart_pkg