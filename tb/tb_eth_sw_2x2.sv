`timescale 1ns/1ps

import packet_pkg::*;
import generator_pkg::*;
import driver_pkg::*;
import monitor_pkg::*;
import scoreboard_pkg::*;

module tb_eth_sw_2x2;
  localparam int PACKETS_PER_PORT = 8;
  localparam int TOTAL_PACKETS    = PACKETS_PER_PORT * 2;

  logic clk;
  eth_sw_if intf(clk);

  eth_sw_2x2 dut (
    .clk(clk),
    .rstn(intf.rstn),
    .inDataA(intf.inDataA),
    .sopA(intf.sopA),
    .eopA(intf.eopA),
    .inDataB(intf.inDataB),
    .sopB(intf.sopB),
    .eopB(intf.eopB),
    .outDataA(intf.outDataA),
    .sopOutA(intf.sopOutA),
    .eopOutA(intf.eopOutA),
    .outDataB(intf.outDataB),
    .sopOutB(intf.sopOutB),
    .eopOutB(intf.eopOutB),
    .portAStall(intf.portAStall),
    .portBStall(intf.portBStall)
  );

  mailbox #(packet_c) gen_drv_a = new();
  mailbox #(packet_c) gen_drv_b = new();
  mailbox #(packet_c) exp_scb   = new();
  mailbox #(packet_c) mon_scb   = new();

  generator_c  gen;
  driver_c     drv_a;
  driver_c     drv_b;
  monitor_c    mon_a;
  monitor_c    mon_b;
  scoreboard_c scb;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    intf.rstn    = 1'b0;
    intf.inDataA = '0;
    intf.sopA    = 1'b0;
    intf.eopA    = 1'b0;
    intf.inDataB = '0;
    intf.sopB    = 1'b0;
    intf.eopB    = 1'b0;

    gen   = new(gen_drv_a, gen_drv_b, exp_scb);
    drv_a = new(intf, gen_drv_a, PORT_A);
    drv_b = new(intf, gen_drv_b, PORT_B);
    mon_a = new(intf, mon_scb, PORT_A);
    mon_b = new(intf, mon_scb, PORT_B);
    scb   = new(exp_scb, mon_scb, TOTAL_PACKETS);

    repeat (3) @(posedge clk);
    intf.rstn = 1'b1;

    fork
      drv_a.run();
      drv_b.run();
      mon_a.run();
      mon_b.run();
      scb.run();
    join_none

    gen.run(PACKETS_PER_PORT);

    fork
      begin
        wait (scb.done);
      end
      begin
        #5000;
        $fatal(1, "Timeout waiting for scoreboard to receive all packets");
      end
    join_any
    disable fork;

    if (scb.error_count == 0) begin
      $display("TEST PASSED: 2x2 Ethernet switch routed %0d packets correctly", TOTAL_PACKETS);
    end else begin
      $fatal(1, "TEST FAILED with %0d scoreboard error(s)", scb.error_count);
    end

    $finish;
  end
endmodule
