`timescale 1ns/100ps
import SystemVerilogCSP :: *;

module partial_sum (interface in, interface out);
    parameter ADDER_NUM = 5'b00000;
    parameter ADDER_COUNT = 63;
    parameter WIDTH = 64;
    parameter WIDTH_MEMBRANE_POTENTIAL = 13;
    parameter THRESHOLD = 64;
    parameter ADDER_ADDR = 4'b1010;
    
    localparam addrPE1 = 4'b0001, addrPE2 = 4'b0101, addrPE3 = 4'b0011, addrPE4 = 4'b0111, addrPE5 = 4'b1100;
    //localparam addrWR = 4'b0000;
    localparam addrMem = 4'b0000;
    localparam outToMemZeroes = {44{1'b0}};
    //localparam membraneToMemZeroes = {46{1'b0}};
    localparam counter = 21;
    localparam done = 10'b11111_11111;
    //localparam membranePotType = 2'b10;
    localparam outSpikeType = 2'b11;

    logic [WIDTH-1:0] inputPacket = 0;
    reg [WIDTH_MEMBRANE_POTENTIAL-1:0] partialPE1, partialPE2, partialPE3, partialPE4, partialPE5;
    logic outputSpike;
    logic [WIDTH-1:0] outputPacket;
    logic [9:0] outputSpikeAddr;
    integer count = 0;
    logic  getMembranePotential = 1'b0;
    logic [12:0] residue_mem[2:0][20:0];
    integer i=0,j=0;
    logic [4:0] count_X = 0, count_Y = 0;

    task storePartialSums;
        begin
            in.Receive(inputPacket);
            $display("Received the packet in the PS%d::::%h",ADDER_NUM, inputPacket );
            case(inputPacket[WIDTH-5:WIDTH-8])
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
                // addrWR : begin
                //     if (inputPacket[WIDTH-9:WIDTH-10] == membranePotType) begin
                //         membranePotential = inputPacket[0:+WIDTH_MEMBRANE_POTENTIAL];
                //     end
                // end
            endcase
        end
    endtask

    always begin

        storePartialSums(); // PE1
        
        storePartialSums(); // PE2
        storePartialSums(); // PE3
        storePartialSums(); // PE4
        storePartialSums(); // PE5
        //$display("RECEIVED ALL PES!!!!");   

        if (getMembranePotential) begin
            //storePartialSums(); // Membrane
            residue_mem[j][i] += partialPE1 + partialPE2 + partialPE3 + partialPE4 + partialPE5;
        end
        else begin //Calculate first membrane potential
            residue_mem[j][i] = partialPE1 + partialPE2 + partialPE3 + partialPE4 + partialPE5;
            $display("DISPLAY RESIDUE MEM:::::%d", residue_mem[j][i]);
        end

        if (residue_mem[j][i] >= THRESHOLD) begin
            outputSpike = 1;
            $display(" %t %m OUTPUT SPIKE:::::%b", $time, outputSpike);
            residue_mem[j][i] = residue_mem[j][i] - THRESHOLD;
        end
        else begin
            outputSpike = 0;
        end

        if (j>=2) begin
                i=0;j=0;
        end
        else if(i>=20) begin 
            j = j + 1;
            i = 0;
        end
        else i = i + 1; 

        // outputPacket = {ADDER_ADDR, addrMem, membranePotType, membraneToMemZeroes, membranePotential};
        // out.Send(outputPacket);
        if (outputSpike) begin
            outputSpikeAddr = {count_X, (count_Y*7) + ADDER_NUM};
            outputPacket = {ADDER_ADDR, addrMem, outSpikeType, outToMemZeroes, outputSpikeAddr};
            out.Send(outputPacket);
            $display("SENT OUTPUT PACKET :::::: %h", outputPacket);
        end
        count = count + 1;
        if(count_X == 20) begin
            count_X = 0;
            count_Y = 0;
        end
        else if(count_Y == 2) begin
            count_X = count_X + 1;
            count_Y = 0;
        end else count_Y+=1;
        if (ADDER_COUNT == count) begin
            outputPacket = {ADDER_ADDR, addrMem, outSpikeType, outToMemZeroes, done};
            out.Send(outputPacket);
            count = 0;
            getMembranePotential = 1;
            $display("SENT OUTPUT PACKET after time step :::::: %h", outputPacket);
        end
    end
endmodule