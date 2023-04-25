`timescale 1ns/100ps
import SystemVerilogCSP :: *;

module partial_sum (interface in, interface out);
    parameter ADDER_NUM = 3'b000;
    parameter ADDER_COUNT = 3'b100;
    parameter WIDTH = 64;
    parameter WIDTH_MEMBRANE_POTENTIAL = 13;
    parameter THRESHOLD = 16;
    parameter ADDER_ADDR = 4'b0110;
    
    localparam addrPE1 = 4'b0000, addrPE2 = 4'b0001, addrPE3 = 4'b0010, addrPE4 = 4'b0011, addrPE5 = 4'b1001;
    localparam addrWR = 4'b0000;
    localparam addrMem = 4'b0000;
    localparam outToMemZeroes = {46{1'b0}};
    localparam membraneToMemZeroes = {46{1'b0}};
    localparam counter = 3'b101;
    localparam done = 4'b1111;
    localparam membranePotType = 2'b10;
    localparam outSpikeType = 2'b11;

    logic [WIDTH-1:0] inputPacket = 0;
    reg [WIDTH_MEMBRANE_POTENTIAL-1:0] partialPE1, partialPE2, partialPE3, partialPE4, partialPE5, membranePotential;
    logic outputSpike;
    logic [WIDTH-1:0] outputPacket;
    logic [3:0] outputSpikeAddr;
    logic [2:0] count = 0;
    logic  getMembranePotential = 1'b0;

    task storePartialSums;
        begin
            in.Receive(inputPacket);
            $display("%m Received psum packet %h", inputPacket);
            case(inputPacket[WIDTH-1:WIDTH-4])
                addrPE1 : begin
                    partialPE1 = inputPacket[12:0];
                end
                addrPE2 : begin
                    partialPE2 = inputPacket[12:0];
                end
                addrPE3 : begin
                    partialPE3 = inputPacket[12:0];
                end
                addrPE4 : begin
                    partialPE4 = inputPacket[12:0];
                end
                addrPE5 : begin
                    partialPE5 = inputPacket[12:0];
                end
            endcase
        end
    endtask

    always begin

        storePartialSums(); // PE1
        storePartialSums(); // PE2
        storePartialSums(); // PE3
        storePartialSums(); // PE4
        storePartialSums(); // PE5

        if (getMembranePotential) begin
            storePartialSums(); // Membrane
            membranePotential += partialPE1 + partialPE2 + partialPE3 + partialPE4 + partialPE5;
        end
        else begin //Calculate first membrane potential
            membranePotential = partialPE1 + partialPE2 + partialPE3 + partialPE4 + partialPE5;
        end

        if (membranePotType >= THRESHOLD) begin
            outputSpike = 1;
            membranePotential = membranePotential - THRESHOLD;
        end
        else begin
            outputSpike = 0;
        end
        outputPacket = {ADDER_ADDR, addrMem, membranePotType, membraneToMemZeroes, membranePotential};
        out.Send(outputPacket);
        if (outputSpike) begin
            outputSpikeAddr = {count, ADDER_NUM};
            outputPacket = {ADDER_ADDR, addrMem, outSpikeType, outToMemZeroes, outputSpikeAddr};
            out.Send(outputPacket);
        end
        if (ADDER_NUM == ADDER_COUNT) begin
            outputPacket = {ADDER_ADDR, addrMem, outSpikeType, outToMemZeroes, done};
            out.Send(outputPacket);
        end
        count += 1;
        if (count >= counter) begin
            count = 0;
            getMembranePotential = 1;
        end
        #10;
    end
endmodule