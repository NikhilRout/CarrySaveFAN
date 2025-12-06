`timescale 1ns/1ps

module CarrySaveFAN_tb;
    parameter N = 16;
    parameter W = 8;
    parameter V = 3;
    parameter S = W + $clog2(N);
    
    reg [N-1:0][W-1:0] operands;
    reg [N-1:0][V-1:0] vec_ids;
    wire [N-2:0][S-1:0] id_sums;
    wire [N-2:0] id_valids;
    
    CarrySaveFAN #(
        .N(N),
        .W(W),
        .V(V),
        .S(S)
    ) dut (
        .operands(operands),
        .vec_ids(vec_ids),
        .id_sums(id_sums),
        .id_valids(id_valids)
    );
    
    integer test_num = 0;
    
    // Expected sum calculation task
    function automatic [S-1:0] calc_expected_sum;
        input [N-1:0][W-1:0] ops;
        input [N-1:0][V-1:0] vids;
        input integer level;
        integer i;
        reg [S-1:0] sum;
        begin
            sum = ops[0];
            for (i = 1; i <= level && i < N; i++) begin
                if (vids[i] == vids[i+1] || i == 1) begin
                    sum = sum + ops[i];
                end
            end
            calc_expected_sum = sum;
        end
    endfunction

    initial begin
        $dumpfile("csa_fan.vcd");
        $dumpvars(0, tb_CarrySaveFAN);
        
        // Initialize
        operands = '0;
        vec_ids = '0;
        #10;
        
        $display("\n========================================");
        $display("CarrySaveFAN Testbench");
        $display("N=%0d, W=%0d, V=%0d, S=%0d", N, W, V, S);
        $display("========================================\n");
        
        // Test 1: All vector IDs match (all additions should happen)
        test_num = 1;
        $display("Test %0d: All vector IDs match (0)", test_num);
        operands[0] = 8'd10;
        operands[1] = 8'd20;
        operands[2] = 8'd30;
        operands[3] = 8'd40;
        operands[4] = 8'd50;
        operands[5] = 8'd60;      
        
        vec_ids[0] = 3'd0;
        vec_ids[1] = 3'd0;
        vec_ids[2] = 3'd0;
        vec_ids[3] = 3'd0;
        vec_ids[4] = 3'd0;
        vec_ids[5] = 3'd0;
        #10;
        print_results();
        $display("  Expected final sum: %0d (10+20+30+40+50+60=210)\n", 8'd10+8'd20+8'd30+8'd40+8'd50+8'd60);
        
        // Test 2: First two match, rest different (only first two should add)
        test_num = 2;
        $display("Test %0d: First two IDs match (0), rest different", test_num);
        operands[0] = 8'd15;
        operands[1] = 8'd25;
        operands[2] = 8'd35;
        operands[3] = 8'd45;
        operands[4] = 8'd55;
        operands[5] = 8'd65;
        vec_ids[0] = 3'd0;
        vec_ids[1] = 3'd0;  // Changed to match vec_ids[0]
        vec_ids[2] = 3'd2;
        vec_ids[3] = 3'd3;
        vec_ids[4] = 3'd4;
        vec_ids[5] = 3'd5;
        #10;
        print_results();
        $display("  Expected: Only operands[0]+operands[1] = %0d", 8'd15+8'd25);
        $display("  All intermediate and final sums should be 40\n");
        
        // Test 3: First 3 operands have matching vector IDs
        test_num = 3;
        $display("Test %0d: First 3 vector IDs match (1)", test_num);
        operands[0] = 8'd5;
        operands[1] = 8'd10;
        operands[2] = 8'd15;
        operands[3] = 8'd20;
        operands[4] = 8'd25;
        operands[5] = 8'd30;
        vec_ids[0] = 3'd1;
        vec_ids[1] = 3'd1;
        vec_ids[2] = 3'd1;
        vec_ids[3] = 3'd2;
        vec_ids[4] = 3'd3;
        vec_ids[5] = 3'd4;
        #10;
        print_results();
        $display("  Expected sum with matching IDs: %0d (5+10+15=30)", 8'd5+8'd10+8'd15);
        $display("  id_sums[0]=15, id_sums[1]=30, id_sums[2..5]=30\n");
        
        // Test 4: Multiple groups - demonstrates independent accumulation
        test_num = 4;
        $display("Test %0d: Three groups: [0,0], [1,1], [2,2]", test_num);
        operands[0] = 8'd1;
        operands[1] = 8'd2;
        operands[2] = 8'd3;
        operands[3] = 8'd4;
        operands[4] = 8'd5;
        operands[5] = 8'd6;
        vec_ids[0] = 3'd0;
        vec_ids[1] = 3'd0;
        vec_ids[2] = 3'd1;
        vec_ids[3] = 3'd1;
        vec_ids[4] = 3'd2;
        vec_ids[5] = 3'd2;
        #10;
        print_results();
        $display("  Expected valid sums:");
        $display("    Group 0 (1+2=3) at id_sums[1]");
        $display("    Group 1 (3+4=7) at id_sums[3]");
        $display("    Group 2 (5+6=11) at id_sums[5]\n");
        
        // Test 5: All zeros
        test_num = 5;
        $display("Test %0d: All zeros with matching IDs", test_num);
        operands = '0;
        vec_ids = '0;
        #10;
        print_results();
        $display("  Expected: All sums should be 0\n");
        
        // Test 6: Max values with matching IDs
        test_num = 6;
        $display("Test %0d: Max values (255) with matching IDs", test_num);
        operands[0] = 8'd255;
        operands[1] = 8'd255;
        operands[2] = 8'd255;
        operands[3] = 8'd255;
        operands[4] = 8'd255;
        operands[5] = 8'd255;
        vec_ids = '0;
        #10;
        print_results();
        $display("  Expected final sum: %0d (255*6=1530)\n", 255*6);
        
        $display("\n========================================");
        $display("Testbench Complete");
        $display("========================================\n");
        
        $stop;
    end
    
    // Task to print results
    task print_results;
        integer i;
        begin
            $display("  Operands: %0d, %0d, %0d, %0d, %0d, %0d",
                operands[0], operands[1], operands[2], operands[3], operands[4], operands[5]);
            $display("  Vec IDs:  %0d, %0d, %0d, %0d, %0d, %0d",
                vec_ids[0], vec_ids[1], vec_ids[2], vec_ids[3], vec_ids[4], vec_ids[5]);
            $display("  Results:");
            for (i = 0; i < N-1; i++) begin
                if (id_valids[i]) begin
                    $display("    [VALID] id_sums[%0d] = %0d (0x%h)", i, id_sums[i], id_sums[i]);
                end else begin
                    $display("    [-----] id_sums[%0d] = %0d (0x%h)", i, id_sums[i], id_sums[i]);
                end
            end
        end
    endtask
    
endmodule
