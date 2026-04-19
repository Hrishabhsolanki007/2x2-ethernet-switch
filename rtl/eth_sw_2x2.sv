`timescale 1ns/1ps

module eth_sw_2x2 #(
  parameter int MAX_PACKET_WORDS = 16,
  parameter int FIFO_DEPTH       = 8,
  parameter int LEN_WIDTH        = $clog2(MAX_PACKET_WORDS + 1)
) (
  input  logic        clk,
  input  logic        rstn,

  input  logic [31:0] inDataA,
  input  logic        sopA,
  input  logic        eopA,
  input  logic [31:0] inDataB,
  input  logic        sopB,
  input  logic        eopB,

  output logic [31:0] outDataA,
  output logic        sopOutA,
  output logic        eopOutA,
  output logic [31:0] outDataB,
  output logic        sopOutB,
  output logic        eopOutB,
  output logic        portAStall,
  output logic        portBStall
);

  logic cap_a_to_out_a;
  logic cap_a_to_out_b;
  logic cap_b_to_out_a;
  logic cap_b_to_out_b;
  logic [LEN_WIDTH-1:0] cap_a_len;
  logic [LEN_WIDTH-1:0] cap_b_len;
  logic [MAX_PACKET_WORDS-1:0][31:0] cap_a_words;
  logic [MAX_PACKET_WORDS-1:0][31:0] cap_b_words;
  logic cap_a_too_long;
  logic cap_b_too_long;
  logic cap_a_bad_da;
  logic cap_b_bad_da;

  logic aa_empty_n;
  logic ab_empty_n;
  logic ba_empty_n;
  logic bb_empty_n;
  logic aa_full;
  logic ab_full;
  logic ba_full;
  logic bb_full;
  logic aa_pop;
  logic ab_pop;
  logic ba_pop;
  logic bb_pop;
  logic aa_overflow;
  logic ab_overflow;
  logic ba_overflow;
  logic bb_overflow;

  logic [LEN_WIDTH-1:0] aa_len;
  logic [LEN_WIDTH-1:0] ab_len;
  logic [LEN_WIDTH-1:0] ba_len;
  logic [LEN_WIDTH-1:0] bb_len;
  logic [MAX_PACKET_WORDS-1:0][31:0] aa_words;
  logic [MAX_PACKET_WORDS-1:0][31:0] ab_words;
  logic [MAX_PACKET_WORDS-1:0][31:0] ba_words;
  logic [MAX_PACKET_WORDS-1:0][31:0] bb_words;

  packet_capture #(
    .MAX_PACKET_WORDS(MAX_PACKET_WORDS),
    .LEN_WIDTH(LEN_WIDTH)
  ) cap_a (
    .clk(clk),
    .rstn(rstn),
    .inData(inDataA),
    .sop(sopA),
    .eop(eopA),
    .push_to_a(cap_a_to_out_a),
    .push_to_b(cap_a_to_out_b),
    .push_len(cap_a_len),
    .push_words(cap_a_words),
    .too_long(cap_a_too_long),
    .dropped_bad_da(cap_a_bad_da)
  );

  packet_capture #(
    .MAX_PACKET_WORDS(MAX_PACKET_WORDS),
    .LEN_WIDTH(LEN_WIDTH)
  ) cap_b (
    .clk(clk),
    .rstn(rstn),
    .inData(inDataB),
    .sop(sopB),
    .eop(eopB),
    .push_to_a(cap_b_to_out_a),
    .push_to_b(cap_b_to_out_b),
    .push_len(cap_b_len),
    .push_words(cap_b_words),
    .too_long(cap_b_too_long),
    .dropped_bad_da(cap_b_bad_da)
  );

  packet_fifo #(
    .MAX_PACKET_WORDS(MAX_PACKET_WORDS),
    .FIFO_DEPTH(FIFO_DEPTH),
    .LEN_WIDTH(LEN_WIDTH)
  ) fifo_a_to_a (
    .clk(clk),
    .rstn(rstn),
    .push(cap_a_to_out_a),
    .push_len(cap_a_len),
    .push_words(cap_a_words),
    .pop(aa_pop),
    .not_empty(aa_empty_n),
    .full(aa_full),
    .front_len(aa_len),
    .front_words(aa_words),
    .overflow(aa_overflow)
  );

  packet_fifo #(
    .MAX_PACKET_WORDS(MAX_PACKET_WORDS),
    .FIFO_DEPTH(FIFO_DEPTH),
    .LEN_WIDTH(LEN_WIDTH)
  ) fifo_a_to_b (
    .clk(clk),
    .rstn(rstn),
    .push(cap_a_to_out_b),
    .push_len(cap_a_len),
    .push_words(cap_a_words),
    .pop(ab_pop),
    .not_empty(ab_empty_n),
    .full(ab_full),
    .front_len(ab_len),
    .front_words(ab_words),
    .overflow(ab_overflow)
  );

  packet_fifo #(
    .MAX_PACKET_WORDS(MAX_PACKET_WORDS),
    .FIFO_DEPTH(FIFO_DEPTH),
    .LEN_WIDTH(LEN_WIDTH)
  ) fifo_b_to_a (
    .clk(clk),
    .rstn(rstn),
    .push(cap_b_to_out_a),
    .push_len(cap_b_len),
    .push_words(cap_b_words),
    .pop(ba_pop),
    .not_empty(ba_empty_n),
    .full(ba_full),
    .front_len(ba_len),
    .front_words(ba_words),
    .overflow(ba_overflow)
  );

  packet_fifo #(
    .MAX_PACKET_WORDS(MAX_PACKET_WORDS),
    .FIFO_DEPTH(FIFO_DEPTH),
    .LEN_WIDTH(LEN_WIDTH)
  ) fifo_b_to_b (
    .clk(clk),
    .rstn(rstn),
    .push(cap_b_to_out_b),
    .push_len(cap_b_len),
    .push_words(cap_b_words),
    .pop(bb_pop),
    .not_empty(bb_empty_n),
    .full(bb_full),
    .front_len(bb_len),
    .front_words(bb_words),
    .overflow(bb_overflow)
  );

  packet_streamer #(
    .MAX_PACKET_WORDS(MAX_PACKET_WORDS),
    .LEN_WIDTH(LEN_WIDTH)
  ) out_a_streamer (
    .clk(clk),
    .rstn(rstn),
    .src0_not_empty(aa_empty_n),
    .src0_len(aa_len),
    .src0_words(aa_words),
    .src0_pop(aa_pop),
    .src1_not_empty(ba_empty_n),
    .src1_len(ba_len),
    .src1_words(ba_words),
    .src1_pop(ba_pop),
    .outData(outDataA),
    .sopOut(sopOutA),
    .eopOut(eopOutA)
  );

  packet_streamer #(
    .MAX_PACKET_WORDS(MAX_PACKET_WORDS),
    .LEN_WIDTH(LEN_WIDTH)
  ) out_b_streamer (
    .clk(clk),
    .rstn(rstn),
    .src0_not_empty(ab_empty_n),
    .src0_len(ab_len),
    .src0_words(ab_words),
    .src0_pop(ab_pop),
    .src1_not_empty(bb_empty_n),
    .src1_len(bb_len),
    .src1_words(bb_words),
    .src1_pop(bb_pop),
    .outData(outDataB),
    .sopOut(sopOutB),
    .eopOut(eopOutB)
  );

  assign portAStall = aa_full || ab_full;
  assign portBStall = ba_full || bb_full;

  always_ff @(posedge clk) begin
    if (rstn) begin
      if (cap_a_too_long) $error("Input A packet exceeded MAX_PACKET_WORDS");
      if (cap_b_too_long) $error("Input B packet exceeded MAX_PACKET_WORDS");
      if (cap_a_bad_da)   $error("Input A packet has unsupported DA");
      if (cap_b_bad_da)   $error("Input B packet has unsupported DA");
      if (aa_overflow)    $error("FIFO A->A overflow");
      if (ab_overflow)    $error("FIFO A->B overflow");
      if (ba_overflow)    $error("FIFO B->A overflow");
      if (bb_overflow)    $error("FIFO B->B overflow");
    end
  end

endmodule
