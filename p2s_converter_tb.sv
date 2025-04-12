`timescale 1ns/1ps

module p2s_converter_tb;

    logic clk = 0, rstn = 0;
    localparam CLK_PERIOD = 10;
    initial forever 
        #(CLK_PERIOD/2)
        clk <= ~clk;

    parameter N = 4;
    logic [N-1:0] p_data;
    logic p_valid=0;
	 logic p_ready, s_valid, s_ready, s_data;

    p2s_converter #(.N(N)) dut(.*);

    // checking output bits
    task check_outputs(input bit exp_s_valid, exp_s_data, exp_p_ready);
        #1; // Sample just after clock edge
        assert(s_valid === exp_s_valid) else $error("s_valid mismatch");
        if (exp_s_valid) assert(s_data === exp_s_data) else $error("s_data mismatch");
        assert(p_ready === exp_p_ready) else $error("p_ready mismatch");
    endtask

    // sending parallel data
    task send_parallel(input logic [N-1:0] data, input bit ready);
        @(posedge clk); #1 p_data <= data; p_valid <= 1; s_ready <= ready;
        wait(p_ready); // Wait for acknowledgment
        @(posedge clk); #1 p_valid <= 0;
        $display("Sent parallel data: %h", data);
    endtask

    // verify serialized data
    task verify_serial(input logic [N-1:0] expected);
		for (int i = 0; i < N; i++) begin
        // Wait for valid data and ready
			while (!(s_valid && s_ready)) @(posedge clk);
        #1 assert(s_data === expected[i]) 
            else $error("Bit %0d mismatch: exp=%b, got=%b", i, expected[i], s_data);
        @(posedge clk); // Wait for next clock
		end
    $display("Verified serial data: %h", expected);
	  endtask

    // monitoring for debugging purposes
    always @(posedge clk) begin
        if (dut.state == dut.TX && s_valid && s_ready)
            $display("[%0t] TX: s_data=%b, count=%0d", $time, s_data, dut.count);
        if (p_valid && p_ready)
            $display("[%0t] RX: p_data=%h loaded", $time, p_data);
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, p2s_converter_tb); 
        
        // reset sequence
        @(posedge clk); #1 rstn <= 0;
        @(posedge clk); #1 rstn <= 1;
        check_outputs(0, 0, 1); // s_valid, s_data, p_ready
        
			// Test Case 1: Simple transfer (6)
			$display("\nTest Case 1: Simple transfer (6)");
			send_parallel(4'h6, 1);
			verify_serial(4'h6);

			// Test Case 2: Zero value
			$display("\nTest Case 2: Zero value");
			send_parallel(4'h0, 1);
			verify_serial(4'h0);

			// Test Case 3: Maximum value (F)
			$display("\nTest Case 3: Maximum value (F)");
			send_parallel(4'hF, 1);
			verify_serial(4'hF);

			// Test Case 4: Edge case (1)
			$display("\nTest Case 4: Edge case (1)");
			send_parallel(4'h1, 1);
			verify_serial(4'h1);

			// Test Case 5: Odd number (7)
			$display("\nTest Case 5: Odd number (7)");
			send_parallel(4'h7, 1);
			verify_serial(4'h7);

			// Test Case 6: Even number (A)
			$display("\nTest Case 6: Even number (A)");
			send_parallel(4'hA, 1);
			verify_serial(4'hA);

			// Test Case 7: Binary pattern 1010
			$display("\nTest Case 7: Binary pattern 1010");
			send_parallel(4'hA, 1);
			verify_serial(4'hA);

			// Test Case 8: Binary pattern 0101
			$display("\nTest Case 8: Binary pattern 0101");
			send_parallel(4'h5, 1);
			verify_serial(4'h5);

			// Test Case 9: Middle value (8)
			$display("\nTest Case 9: Middle value (8)");
			send_parallel(4'h8, 1);
			verify_serial(4'h8);

			// Test Case 10: Hex value (D)
			$display("\nTest Case 10: Hex value (D)");
			send_parallel(4'hD, 1);
			verify_serial(4'hD);
					  
		  
end
endmodule