`timescale 1ns/100ps
import SystemVerilogCSP :: *;

module partial_sum (interface in, interface out);
    parameter ADDER_NUM = 5'b00000;
    parameter ADDER_COUNT = 63;
    parameter WIDTH = 64;
    parameter WIDTH_MEMBRANE_POTENTIAL = 13;
    parameter THRESHOLD = 64;
    parameter DESTINATION_ADDRESS = 4'b1010;
    parameter SOURCE_ADDRESS = 4'b0000;
    
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
    reg [WIDTH_MEMBRANE_POTENTIAL-1:0] partialPE1[2:0], partialPE2[2:0], partialPE3[2:0], partialPE4[2:0], partialPE5[2:0];
    logic outputSpike;
    logic [WIDTH-1:0] outputPacket;
    logic [9:0] outputSpikeAddr;
    integer count = 0;
    logic  getMembranePotential = 1'b0;
    logic [12:0] residue_mem[2:0][20:0];
    integer i=0,j=0;
    logic [4:0] count_X = 0, count_Y = 0;
    integer counts = 0;
    int count1=0, count2=0, count3=0, count4=0, count5=0;

    task storePartialSums;
        begin
            in.Receive(inputPacket);
            //$display("%m PARTIALPE:::%b:::%d:::%h",inputPacket[WIDTH-5:WIDTH-8], inputPacket[12:0], inputPacket);
            //$display("Received the packet in the PS%d::::%h",ADDER_NUM, inputPacket );
            case(inputPacket[WIDTH-5:WIDTH-8])
                addrPE1 : begin
                    partialPE1[count1] = inputPacket[12:0];
                    count1+=1;
                    //counts = counts + 1;
                    // $display("PARTIALPE1:::%d:::%h",partialPE1, inputPacket);
                end
                addrPE2 : begin
                    partialPE2[count2] = inputPacket[12:0];
                    count2+=1;
                    //counts = counts + 1;
                    // $display("PARTIALPE2:::%d::::%h",partialPE2, inputPacket);
                end
                addrPE3 : begin
                    partialPE3[count3] = inputPacket[12:0];
                    //counts = counts + 1;
                    count3+=1;
                    // $display("PARTIALPE3:::%d::::%h",partialPE3, inputPacket);
                end
                addrPE4 : begin
                    partialPE4[count4] = inputPacket[12:0];
                    count4+=1;
                    //counts = counts + 1;
                    // $display("PARTIALPE4:::%d::::%h",partialPE4, inputPacket);
                end
                addrPE5 : begin
                    partialPE5[count5] = inputPacket[12:0];
                    count5+=1;
                    //counts = counts + 1;
                    // $display("PARTIALPE5:::%d::::%h",partialPE5, inputPacket);
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
        // #5;
        // storePartialSums(); // PE1
        // #5;
        // // $display("%m Received the packet in the PS1%d::%d::%h",ADDER_NUM, partialPE1, inputPacket );
        // storePartialSums(); // PE2
        // #5;
        // // $display("%m Received the packet in the PS2%d::%d::%h",ADDER_NUM, partialPE2, inputPacket );
        // storePartialSums(); // PE3
        // #5;
        // // $display("%m Received the packet in the PS3%d::%d::%h",ADDER_NUM, partialPE3, inputPacket );
        // storePartialSums(); // PE4
        // #5;
        // // $display("%m Received the packet in the PS4%d::%d::%h",ADDER_NUM, partialPE4, inputPacket );
        // storePartialSums(); // PE5
        // #5;
        // $display("%m counts  %d",counts);
        // counts = 0;
        // // $display("%m Received the packet in the PS5%d::%d::%h",ADDER_NUM, partialPE5, inputPacket );
        // $display("%m RECIVED ALL PES::::: %d %d %d %d %d %h", partialPE1,partialPE2,partialPE3,partialPE4,partialPE5, inputPacket);
        // //$display("RECEIVED ALL PES!!!!");   
        //$display("%m COUNTSSS:::: %d %d %d %d %d", count1, count2, count3, count4, count5);

        if(!(count1 == 3 && count2 == 3 && count3 == 3 && count4 == 3 && count5 == 3) && !(count1 > 3 ||count2 > 3 ||count3 > 3 || count4 > 3 || count5 > 3))begin
           storePartialSums();
           $display("Total No of packets received in %m is %d",count1+count2+count3+count4+count5);
           $display("Count Split in %m :: PE1:%d PE2:%d PE3:%d PE4:%d PE5:%d", count1, count2, count3, count4, count5);
            #5; 
        end
        else #1;



        if(count1 == 3 && count2 == 3 && count3 == 3 && count4 == 3 && count5 == 3) begin
            if (getMembranePotential) begin
            //storePartialSums(); // Membrane
            residue_mem[j][i] += partialPE1[counts] + partialPE2[counts] + partialPE3[counts] + partialPE4[counts] + partialPE5[counts];
            end
            else begin //Calculate first membrane potential
                residue_mem[j][i] = partialPE1[counts] + partialPE2[counts] + partialPE3[counts] + partialPE4[counts] + partialPE5[counts];
                $display("%m DISPLAY RESIDUE MEM:::::%d %d %d %d %d %d %h", residue_mem[j][i], partialPE1[counts],partialPE2[counts],partialPE3[counts],partialPE4[counts],partialPE5[counts], inputPacket[counts]);
            end
            counts+=1;
            if(counts >= 3) begin
                counts = 0;
                count1 = 0;
                count2 = 0;
                count3 = 0;
                count4 = 0;
                count5 = 0;
            end

            if (residue_mem[j][i] > THRESHOLD) begin
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
                outputPacket = {DESTINATION_ADDRESS, SOURCE_ADDRESS, outSpikeType, outToMemZeroes, outputSpikeAddr};
                out.Send(outputPacket);
                $display(" %m SENT OUTPUT PACKET :::::: %h", outputPacket);
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
                outputPacket = {DESTINATION_ADDRESS, SOURCE_ADDRESS, outSpikeType, outToMemZeroes, done};
                out.Send(outputPacket);
                count = 0;
                getMembranePotential = 1;
                // $display("SENT OUTPUT PACKET after time step :::::: %h", outputPacket);
            end
            #5;
        end
        else #1;
        
    end
endmodule