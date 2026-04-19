`timescale 1ns/1ps

package scoreboard_pkg;
  import packet_pkg::*;

  class scoreboard_c;
    mailbox #(packet_c) exp_mb;
    mailbox #(packet_c) act_mb;
    int                 total_expected;
    int                 error_count;
    bit                 done;

    packet_c expected_out_a[$];
    packet_c expected_out_b[$];

    function new(mailbox #(packet_c) exp_mb,
                 mailbox #(packet_c) act_mb,
                 int total_expected);
      this.exp_mb         = exp_mb;
      this.act_mb         = act_mb;
      this.total_expected = total_expected;
      this.error_count    = 0;
      this.done           = 1'b0;
    endfunction

    function void push_expected(packet_c pkt);
      if (pkt.dst_port == PORT_A) begin
        expected_out_a.push_back(pkt);
      end else begin
        expected_out_b.push_back(pkt);
      end
    endfunction

    task check_actual(packet_c actual);
      int hit;
      hit = -1;

      if ((actual.da == 8'h01) && (actual.dst_port != PORT_A)) begin
        error_count++;
        $error("[SCB] Routing error: DA=01 appeared on output %s", port_name(actual.dst_port));
      end

      if ((actual.da == 8'h02) && (actual.dst_port != PORT_B)) begin
        error_count++;
        $error("[SCB] Routing error: DA=02 appeared on output %s", port_name(actual.dst_port));
      end

      if (actual.dst_port == PORT_A) begin
        foreach (expected_out_a[i]) begin
          if (expected_out_a[i].same_payload(actual)) begin
            hit = i;
            break;
          end
        end

        if (hit >= 0) begin
          $display("[SCB] PASS OUT_A %s", actual.sprint());
          expected_out_a.delete(hit);
        end else begin
          error_count++;
          $error("[SCB] Unexpected packet on OUT_A: %s", actual.sprint());
        end
      end else begin
        foreach (expected_out_b[i]) begin
          if (expected_out_b[i].same_payload(actual)) begin
            hit = i;
            break;
          end
        end

        if (hit >= 0) begin
          $display("[SCB] PASS OUT_B %s", actual.sprint());
          expected_out_b.delete(hit);
        end else begin
          error_count++;
          $error("[SCB] Unexpected packet on OUT_B: %s", actual.sprint());
        end
      end
    endtask

    task run();
      packet_c pkt;

      repeat (total_expected) begin
        exp_mb.get(pkt);
        push_expected(pkt);
      end

      repeat (total_expected) begin
        act_mb.get(pkt);
        check_actual(pkt);
      end

      if (expected_out_a.size() != 0) begin
        error_count += expected_out_a.size();
        $error("[SCB] %0d expected packet(s) never reached OUT_A", expected_out_a.size());
      end

      if (expected_out_b.size() != 0) begin
        error_count += expected_out_b.size();
        $error("[SCB] %0d expected packet(s) never reached OUT_B", expected_out_b.size());
      end

      done = 1'b1;
    endtask
  endclass
endpackage
