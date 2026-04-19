`timescale 1ns/1ps

package generator_pkg;
  import packet_pkg::*;

  class generator_c;
    mailbox #(packet_c) drv_a_mb;
    mailbox #(packet_c) drv_b_mb;
    mailbox #(packet_c) exp_mb;

    function new(mailbox #(packet_c) drv_a_mb,
                 mailbox #(packet_c) drv_b_mb,
                 mailbox #(packet_c) exp_mb);
      this.drv_a_mb = drv_a_mb;
      this.drv_b_mb = drv_b_mb;
      this.exp_mb   = exp_mb;
    endfunction

    function packet_c make_packet(port_e src_port, bit [7:0] forced_da, int seq_id);
      packet_c pkt;
      pkt = new();

      if (!pkt.randomize()) begin
        $fatal(1, "Randomization failed in generator");
      end

      pkt.da       = forced_da;
      pkt.sa       = seq_id[7:0];
      pkt.src_port = src_port;
      pkt.dst_port = (forced_da == 8'h01) ? PORT_A : PORT_B;
      pkt.seq_id   = seq_id;

      pkt.data[0] = {16'hCAFE, (src_port == PORT_A) ? 8'hA0 : 8'hB0, seq_id[7:0]};
      pkt.calc_crc();

      return pkt;
    endfunction

    task run(int packets_per_port);
      packet_c pkt_a;
      packet_c pkt_b;
      bit [7:0] da_a;
      bit [7:0] da_b;
      int seq;

      seq = 0;

      for (int i = 0; i < packets_per_port; i++) begin
        case (i % 4)
          0: begin
            da_a = 8'h01;
            da_b = 8'h01;
          end
          1: begin
            da_a = 8'h02;
            da_b = 8'h02;
          end
          2: begin
            da_a = 8'h01;
            da_b = 8'h02;
          end
          default: begin
            da_a = 8'h02;
            da_b = 8'h01;
          end
        endcase

        pkt_a = make_packet(PORT_A, da_a, seq++);
        pkt_b = make_packet(PORT_B, da_b, seq++);

        pkt_a.display("GEN");
        pkt_b.display("GEN");

        exp_mb.put(pkt_a.clone());
        exp_mb.put(pkt_b.clone());
        drv_a_mb.put(pkt_a.clone());
        drv_b_mb.put(pkt_b.clone());
      end
    endtask
  endclass
endpackage
