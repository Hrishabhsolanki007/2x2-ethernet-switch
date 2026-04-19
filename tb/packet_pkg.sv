`timescale 1ns/1ps

package packet_pkg;
  typedef enum int {
    PORT_A = 0,
    PORT_B = 1
  } port_e;

  function string port_name(port_e port);
    case (port)
      PORT_A: return "A";
      PORT_B: return "B";
      default: return "?";
    endcase
  endfunction

  class packet_c;
    rand bit [7:0]  da;
    rand bit [7:0]  sa;
    rand bit [31:0] data[$];

    bit [31:0] crc;
    port_e     src_port;
    port_e     dst_port;
    int        seq_id;

    constraint size_c { data.size() inside {[4:10]}; }
    constraint addr_c { da inside {8'h01, 8'h02}; }

    function void calc_crc();
      crc = '0;
      foreach (data[i]) begin
        crc ^= data[i];
      end
    endfunction

    function packet_c clone();
      packet_c pkt;
      pkt = new();

      pkt.da       = da;
      pkt.sa       = sa;
      pkt.crc      = crc;
      pkt.src_port = src_port;
      pkt.dst_port = dst_port;
      pkt.seq_id   = seq_id;

      foreach (data[i]) begin
        pkt.data.push_back(data[i]);
      end

      return pkt;
    endfunction

    function bit same_payload(packet_c rhs);
      if (da !== rhs.da) return 1'b0;
      if (sa !== rhs.sa) return 1'b0;
      if (crc !== rhs.crc) return 1'b0;
      if (data.size() != rhs.data.size()) return 1'b0;

      foreach (data[i]) begin
        if (data[i] !== rhs.data[i]) return 1'b0;
      end

      return 1'b1;
    endfunction

    function string sprint();
      return $sformatf("SEQ=%0d SRC=%s DST=%s DA=%02h SA=%02h SIZE=%0d CRC=%08h",
                       seq_id, port_name(src_port), port_name(dst_port),
                       da, sa, data.size(), crc);
    endfunction

    function void display(string tag = "PKT");
      $display("[%s] %s", tag, sprint());
    endfunction
  endclass
endpackage
