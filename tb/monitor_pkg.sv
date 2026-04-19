`timescale 1ns/1ps

package monitor_pkg;
  import packet_pkg::*;

  class monitor_c;
    virtual eth_sw_if.MONITOR vif;
    mailbox #(packet_c)       mb;
    port_e                    port;

    function new(virtual eth_sw_if.MONITOR vif, mailbox #(packet_c) mb, port_e port);
      this.vif  = vif;
      this.mb   = mb;
      this.port = port;
    endfunction

    function bit [31:0] sampled_data();
      return (port == PORT_A) ? vif.cb.outDataA : vif.cb.outDataB;
    endfunction

    function bit sampled_sop();
      return (port == PORT_A) ? vif.cb.sopOutA : vif.cb.sopOutB;
    endfunction

    function bit sampled_eop();
      return (port == PORT_A) ? vif.cb.eopOutA : vif.cb.eopOutB;
    endfunction

    task run();
      packet_c   pkt;
      bit [31:0] word;

      forever begin
        @(vif.cb);

        if (sampled_sop()) begin
          pkt          = new();
          pkt.dst_port = port;
          word         = sampled_data();
          pkt.da       = word[31:24];
          pkt.sa       = word[23:16];

          if (sampled_eop()) begin
            pkt.crc = word;
            pkt.display({ "MON_OUT_", port_name(port) });
            mb.put(pkt);
          end else begin
            forever begin
              @(vif.cb);
              word = sampled_data();

              if (sampled_eop()) begin
                pkt.crc = word;
                break;
              end

              pkt.data.push_back(word);
            end

            pkt.display({ "MON_OUT_", port_name(port) });
            mb.put(pkt);
          end
        end
      end
    endtask
  endclass
endpackage
