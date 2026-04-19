`timescale 1ns/1ps

package driver_pkg;
  import packet_pkg::*;

  class driver_c;
    virtual eth_sw_if.DRIVER vif;
    mailbox #(packet_c)      mb;
    port_e                   port;

    function new(virtual eth_sw_if.DRIVER vif, mailbox #(packet_c) mb, port_e port);
      this.vif  = vif;
      this.mb   = mb;
      this.port = port;
    endfunction

    task drive_word(bit [31:0] word, bit sop, bit eop);
      if (port == PORT_A) begin
        vif.cb.inDataA <= word;
        vif.cb.sopA    <= sop;
        vif.cb.eopA    <= eop;
      end else begin
        vif.cb.inDataB <= word;
        vif.cb.sopB    <= sop;
        vif.cb.eopB    <= eop;
      end
    endtask

    task drive_idle();
      drive_word(32'h0, 1'b0, 1'b0);
    endtask

    task run();
      packet_c pkt;

      forever begin
        mb.get(pkt);

        @(vif.cb);
        drive_word({pkt.da, pkt.sa, 16'h0}, 1'b1, 1'b0);

        foreach (pkt.data[i]) begin
          @(vif.cb);
          drive_word(pkt.data[i], 1'b0, 1'b0);
        end

        @(vif.cb);
        drive_word(pkt.crc, 1'b0, 1'b1);

        @(vif.cb);
        drive_idle();
      end
    endtask
  endclass
endpackage
