`timescale 1ns/1ps

module packet_streamer #(
  parameter int MAX_PACKET_WORDS = 16,
  parameter int LEN_WIDTH        = $clog2(MAX_PACKET_WORDS + 1)
) (
  input  logic                                  clk,
  input  logic                                  rstn,

  input  logic                                  src0_not_empty,
  input  logic [LEN_WIDTH-1:0]                  src0_len,
  input  var logic [MAX_PACKET_WORDS-1:0][31:0] src0_words,
  output logic                                  src0_pop,

  input  logic                                  src1_not_empty,
  input  logic [LEN_WIDTH-1:0]                  src1_len,
  input  var logic [MAX_PACKET_WORDS-1:0][31:0] src1_words,
  output logic                                  src1_pop,

  output logic [31:0]                           outData,
  output logic                                  sopOut,
  output logic                                  eopOut
);

  typedef enum logic [1:0] {
    IDLE,
    SEND_SRC0,
    SEND_SRC1
  } stream_state_e;

  stream_state_e       state;
  logic                 prefer_src1;
  logic [LEN_WIDTH-1:0] word_idx;
  logic [LEN_WIDTH-1:0] active_len;

  logic choose_src0;
  logic choose_src1;

  assign choose_src0 = src0_not_empty && (!src1_not_empty || !prefer_src1);
  assign choose_src1 = src1_not_empty && (!src0_not_empty ||  prefer_src1);
  assign src0_pop    = ((state == IDLE) && choose_src0 && (src0_len == 1)) ||
                       ((state == SEND_SRC0) && (word_idx == active_len - 1'b1));
  assign src1_pop    = ((state == IDLE) && !choose_src0 && choose_src1 && (src1_len == 1)) ||
                       ((state == SEND_SRC1) && (word_idx == active_len - 1'b1));

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      state       <= IDLE;
      prefer_src1 <= 1'b0;
      word_idx    <= '0;
      active_len  <= '0;
      outData     <= '0;
      sopOut      <= 1'b0;
      eopOut      <= 1'b0;
    end else begin
      outData <= '0;
      sopOut  <= 1'b0;
      eopOut  <= 1'b0;

      unique case (state)
        IDLE: begin
          if (choose_src0) begin
            outData    <= src0_words[0];
            sopOut     <= 1'b1;
            eopOut     <= (src0_len == 1);
            active_len <= src0_len;

            if (src0_len == 1) begin
              prefer_src1 <= 1'b1;
              word_idx    <= '0;
              state       <= IDLE;
            end else begin
              word_idx <= 1;
              state    <= SEND_SRC0;
            end
          end else if (choose_src1) begin
            outData    <= src1_words[0];
            sopOut     <= 1'b1;
            eopOut     <= (src1_len == 1);
            active_len <= src1_len;

            if (src1_len == 1) begin
              prefer_src1 <= 1'b0;
              word_idx    <= '0;
              state       <= IDLE;
            end else begin
              word_idx <= 1;
              state    <= SEND_SRC1;
            end
          end
        end

        SEND_SRC0: begin
          outData <= src0_words[word_idx];
          eopOut  <= (word_idx == active_len - 1'b1);

          if (word_idx == active_len - 1'b1) begin
            prefer_src1 <= 1'b1;
            word_idx    <= '0;
            state       <= IDLE;
          end else begin
            word_idx <= word_idx + 1'b1;
          end
        end

        SEND_SRC1: begin
          outData <= src1_words[word_idx];
          eopOut  <= (word_idx == active_len - 1'b1);

          if (word_idx == active_len - 1'b1) begin
            prefer_src1 <= 1'b0;
            word_idx    <= '0;
            state       <= IDLE;
          end else begin
            word_idx <= word_idx + 1'b1;
          end
        end

        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
