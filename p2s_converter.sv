module p2s_converter #(parameter N=4)(
    input logic clk, s_ready, p_valid, rstn,
    input logic [N-1:0] p_data,
    output logic p_ready, s_data, s_valid
);

    enum logic {RX, TX} state, next_state;
    logic [$clog2(N)-1:0] count;
    logic [N-1:0] shift_reg;

    // Next state decoder
    always_comb begin
        case (state)
            RX: next_state = p_valid ? TX : RX;
            TX: next_state = ((count == N-1) && s_ready) ? RX : TX;
        endcase
    end

    // State sequencer
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) state <= RX;
        else state <= next_state;
    end

    // Output assignments
    assign s_data = shift_reg[0];
    assign p_ready = (state == RX);
    assign s_valid = (state == TX);

    // Data path
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count <= '0;
            shift_reg <= '0;
        end
        else case (state)
            RX: begin
                shift_reg <= p_data;
                count <= '0;
            end
            TX: if (s_ready) begin
                shift_reg <= shift_reg >> 1;
                count <= count + 1'd1;
            end
        endcase
    end
endmodule
