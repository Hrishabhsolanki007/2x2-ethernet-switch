`timescale 1ns/1ps

module packet_fifo #(
  parameter int MAX_PACKET_WORDS = 16,
  parameter int FIFO_DEPTH       = 8,
  parameter int LEN_WIDTH        = $clog2(MAX_PACKET_WORDS + 1),
  parameter int PTR_WIDTH        = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH),
  parameter int COUNT_WIDTH      = $clog2(FIFO_DEPTH + 1)
) (
  input  logic                                  clk,
  input  logic                                  rstn,

  input  logic                                  push,
  input  logic [LEN_WIDTH-1:0]                  push_len,
  input  var logic [MAX_PACKET_WORDS-1:0][31:0] push_words,

  input  logic                                  pop,
  output logic                                  not_empty,
  output logic                                  full,
  output logic [LEN_WIDTH-1:0]                  front_len,
  output logic [MAX_PACKET_WORDS-1:0][31:0]     front_words,
  output logic                                  overflow
);

  logic [FIFO_DEPTH-1:0][MAX_PACKET_WORDS-1:0][31:0] mem;
  logic [FIFO_DEPTH-1:0][LEN_WIDTH-1:0]              len_mem;
  logic [PTR_WIDTH-1:0]                              rd_ptr;
  logic [PTR_WIDTH-1:0]                              wr_ptr;
  logic [COUNT_WIDTH-1:0]                            count;

  logic do_push;
  logic do_pop;

  assign not_empty   = (count != '0);
  assign full        = (count == FIFO_DEPTH[COUNT_WIDTH-1:0]);
  assign front_len   = len_mem[rd_ptr];
  assign front_words = mem[rd_ptr];
  assign do_pop      = pop && not_empty;
  assign do_push     = push && (!full || do_pop);

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      rd_ptr   <= '0;
      wr_ptr   <= '0;
      count    <= '0;
      overflow <= 1'b0;
    end else begin
      overflow <= push && full && !do_pop;

      if (do_push) begin
        mem[wr_ptr]     <= push_words;
        len_mem[wr_ptr] <= push_len;
        wr_ptr          <= (wr_ptr == FIFO_DEPTH - 1) ? '0 : wr_ptr + 1'b1;
      end

      if (do_pop) begin
        rd_ptr <= (rd_ptr == FIFO_DEPTH - 1) ? '0 : rd_ptr + 1'b1;
      end

      unique case ({do_push, do_pop})
        2'b10: count <= count + 1'b1;
        2'b01: count <= count - 1'b1;
        default: count <= count;
      endcase
    end
  end

endmodule
