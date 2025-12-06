module SigmaBaseFAN #(
    parameter N = 32,
    parameter W = 8,
    parameter V = 3,
    parameter S = W + $clog2(N)
) (
    input  wire [N-1:0][W-1:0] operands,
    input  wire [N-1:0][V-1:0] vec_ids,
    output wire [N-2:0][S-1:0] id_sums,
    output wire [N-2:0]        id_valids
);

    localparam LEVELS = $clog2(N);

    // Mux logic func
    function int get_left_mux_idx(int c, int d);
        automatic int idx = c * 2; 
        for (int k = 0; k < d; k++) idx = idx * 2 + 1; 
        return idx;
    endfunction

    function int get_right_mux_idx(int c, int d);
        automatic int idx = c * 2 + 1; 
        for (int k = 0; k < d; k++) idx = idx * 2; 
        return idx;
    endfunction

    logic [S-1:0] tree_data [LEVELS:0][N-1:0];

    // Initialize level 0
    for (genvar i = 0; i < N; i++) begin : g_init_leaves
        assign tree_data[0][i] = S'(operands[i]);
    end

    // Recursive tree gen
    for (genvar lvl = 1; lvl <= LEVELS; lvl++) begin : g_levels
        localparam NUM_ADDERS = N >> lvl;
        localparam OUT_OFFSET = N - (N >> (lvl-1)); 

        for (genvar col = 0; col < NUM_ADDERS; col++) begin : g_cols
            
            // Topology calc
            localparam SPAN = 1 << lvl;
            localparam START_IDX = col * SPAN;
            localparam END_IDX   = START_IDX + SPAN - 1;
            localparam ADDER_ID  = START_IDX + (SPAN / 2) - 1;

            logic [S-1:0] left_op, right_op;
            logic [$clog2(LEVELS)-1:0] l_sel_depth, r_sel_depth;

            // Control logic
            logic add_en;
            VecIDComp #(
                .N (V)
            ) vec_cmp_cut (
                .a  (vec_ids[ADDER_ID]),
                .b  (vec_ids[ADDER_ID+1]),
                .eq (add_en)
            );

            wire [lvl-1:0] l_chunk_matches;
            wire [lvl-1:0] r_chunk_matches;

            for (genvar d = 0; d < lvl; d++) begin : g_mux_comps
                localparam chunk_sz = 1 << (lvl - 1 - d);
                localparam l_chunk_start = (ADDER_ID + 1) - chunk_sz;
                localparam r_chunk_end = (ADDER_ID + 1) + chunk_sz - 1;

                VecIDComp #(
                    .N (V)
                ) vec_cmp_left (
                    .a  (vec_ids[l_chunk_start]),
                    .b  (vec_ids[ADDER_ID]),
                    .eq (l_chunk_matches[d])
                );

                VecIDComp #(
                    .N (V)
                ) vec_cmp_right (
                    .a  (vec_ids[r_chunk_end]),
                    .b  (vec_ids[ADDER_ID+1]),
                    .eq (r_chunk_matches[d])
                );
            end

            always_comb begin
                // Left Mux (Look Backwards)
                l_sel_depth = lvl - 1; 
                for (int d = 0; d < lvl; d++) begin
                    if (l_chunk_matches[d]) begin
                        l_sel_depth = d;
                        break;
                    end
                end

                // Right Mux (Look Forwards)
                r_sel_depth = lvl - 1; 
                for (int d = 0; d < lvl; d++) begin
                    if (r_chunk_matches[d]) begin
                        r_sel_depth = d;
                        break;
                    end
                end
            end

            // Datapath
            assign left_op  = tree_data[lvl - 1 - l_sel_depth][get_left_mux_idx(col, l_sel_depth)];
            assign right_op = tree_data[lvl - 1 - r_sel_depth][get_right_mux_idx(col, r_sel_depth)];

            wire [S-1:0] adder_sum;
            KoggeStoneAdder #(
                .N (S)
            ) ksa (
                .dataa (left_op),
                .datab (right_op),
                .sum   (adder_sum),
                .cout  ()
            );

            assign tree_data[lvl][col] = adder_sum;

            // Valid signal logic
            logic consumed_by_parent;
            if (lvl == LEVELS) begin
                assign consumed_by_parent = 1'b0; // Root is never consumed
            end else begin
                logic vector_reaches_boundary;
                logic boundary_bridged_by_parent;

                if (col % 2 == 0) begin 
                    // Left child: consumed if my vector reaches the right edge
                    // AND the parent merges that edge with the neighbor.
                    wire id_match_right_edge;
                    wire id_match_right_neighbor;

                    VecIDComp #(
                        .N (V)
                    ) vec_cmp_right_edge (
                        .a  (vec_ids[ADDER_ID]),
                        .b  (vec_ids[END_IDX]),
                        .eq (id_match_right_edge)
                    );

                    VecIDComp #(
                        .N (V)
                    ) vec_cmp_right_neighbor (
                        .a  (vec_ids[END_IDX]),
                        .b  (vec_ids[END_IDX+1]),
                        .eq (id_match_right_neighbor)
                    );

                    assign vector_reaches_boundary = id_match_right_edge;
                    assign boundary_bridged_by_parent = id_match_right_neighbor;
                end else begin          
                    // Right child: consumed if my vector reaches the left edge
                    // AND the parent merges that edge with the neighbor.
                    wire id_match_left_edge;
                    wire id_match_left_neighbor;

                    VecIDComp #(
                        .N (V)
                    ) vec_cmp_left_edge (
                        .a  (vec_ids[ADDER_ID]),
                        .b  (vec_ids[START_IDX]),
                        .eq (id_match_left_edge)
                    );

                    VecIDComp #(
                        .N (V)
                    ) vec_cmp_left_neighbor (
                        .a  (vec_ids[START_IDX-1]),
                        .b  (vec_ids[START_IDX]),
                        .eq (id_match_left_neighbor)
                    );

                    assign vector_reaches_boundary = id_match_left_edge;
                    assign boundary_bridged_by_parent = id_match_left_neighbor;
                end
                
                assign consumed_by_parent = vector_reaches_boundary && boundary_bridged_by_parent;
            end

            assign id_sums[OUT_OFFSET + col]   = tree_data[lvl][col];
            assign id_valids[OUT_OFFSET + col] = add_en && !consumed_by_parent;

        end
    end

endmodule
