`timescale 1ns/1ps

module packet_capture #(
  parameter int MAX_PACKET_WORDS = 16,
  parameter int LEN_WIDTH        = $clog2(MAX_PACKET_WORDS + 1)
) (
  input  logic                              clk,
  input  logic                              rstn,
  input  logic [31:0]                       inData,
  input  logic                              sop,
  input  logic                              eop,

  output logic                              push_to_a,
  output logic                              push_to_b,
  output logic [LEN_WIDTH-1:0]              push_len,
  output logic [MAX_PACKET_WORDS-1:0][31:0] push_words,
  output logic                              too_long,
  output logic                              dropped_bad_da
);

  logic                              active;
  logic [7:0]                        dest_da;
  logic [LEN_WIDTH-1:0]              cap_len;
  logic [MAX_PACKET_WORDS-1:0][31:0] cap_words;

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      active         <= 1'b0;
      dest_da        <= '0;
      cap_len        <= '0;
      push_to_a      <= 1'b0;
      push_to_b      <= 1'b0;
      push_len       <= '0;
      push_words     <= '0;
      cap_words      <= '0;
      too_long       <= 1'b0;
      dropped_bad_da <= 1'b0;
    end else begin
      push_to_a      <= 1'b0;
      push_to_b      <= 1'b0;
      too_long       <= 1'b0;
      dropped_bad_da <= 1'b0;

      if (sop) begin
        cap_words[0] <= inData;
        dest_da      <= inData[31:24];
        cap_len      <= 1;
        active       <= !eop;

        if (eop) begin
          push_words       <= '0;
          push_words[0]    <= inData;
          push_len         <= 1;
          active           <= 1'b0;
          cap_len          <= '0;

          unique case (inData[31:24])
            8'h01: push_to_a <= 1'b1;
            8'h02: push_to_b <= 1'b1;
            default: dropped_bad_da <= 1'b1;
          endcase
        end
      end else if (active) begin
        if (cap_len < MAX_PACKET_WORDS) begin
          cap_words[cap_len] <= inData;

          if (eop) begin
            for (int i = 0; i < MAX_PACKET_WORDS; i++) begin
              if (i < cap_len) begin
                push_words[i] <= cap_words[i];
              end else if (i == cap_len) begin
                push_words[i] <= inData;
              end else begin
                push_words[i] <= '0;
              end
            end

            push_len <= cap_len + 1'b1;
            active   <= 1'b0;
            cap_len  <= '0;

            unique case (dest_da)
              8'h01: push_to_a <= 1'b1;
              8'h02: push_to_b <= 1'b1;
              default: dropped_bad_da <= 1'b1;
            endcase
          end else begin
            cap_len <= cap_len + 1'b1;
          end
        end else begin
          too_long <= 1'b1;

          if (eop) begin
            active  <= 1'b0;
            cap_len <= '0;
          end
        end
      end
    end
  end

endmodule
