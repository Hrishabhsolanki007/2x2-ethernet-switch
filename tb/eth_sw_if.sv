`timescale 1ns/1ps

interface eth_sw_if(input logic clk);
  logic rstn;

  logic [31:0] inDataA;
  logic        sopA;
  logic        eopA;
  logic [31:0] inDataB;
  logic        sopB;
  logic        eopB;

  logic [31:0] outDataA;
  logic        sopOutA;
  logic        eopOutA;
  logic [31:0] outDataB;
  logic        sopOutB;
  logic        eopOutB;
  logic        portAStall;
  logic        portBStall;

  clocking cb @(posedge clk);
    default input #2 output #2;

    output inDataA, sopA, eopA;
    output inDataB, sopB, eopB;

    input outDataA, sopOutA, eopOutA;
    input outDataB, sopOutB, eopOutB;
    input portAStall, portBStall;
  endclocking

  modport DRIVER  (clocking cb);
  modport MONITOR (clocking cb);
  modport DUT (
    input  clk,
    input  rstn,
    input  inDataA,
    input  sopA,
    input  eopA,
    input  inDataB,
    input  sopB,
    input  eopB,
    output outDataA,
    output sopOutA,
    output eopOutA,
    output outDataB,
    output sopOutB,
    output eopOutB,
    output portAStall,
    output portBStall
  );
endinterface
