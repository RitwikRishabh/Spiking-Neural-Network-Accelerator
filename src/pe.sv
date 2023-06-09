`timescale 1ns/1fs
import SystemVerilogCSP :: *;

// `include "./src/data_bucket.sv"
// `include "./src/data_generator.sv"

module packetizerConv(interface psumOut, interface addrIn, interface convCount, interface ifmapIn, interface packet);
    parameter PACKET_WIDTH = 64;
    parameter ADDR_WIDTH = 4;
    parameter IFMAP_LENGTH = 25;
    parameter MEM_WIDTH = 13;
    parameter FL = 2;
    parameter BL = 4;
    parameter CONVOLUTIONS_PER_ROW = 21;

    localparam addrPE1 = 4'b0000, addrPE2 = 4'b0001, addrPE3 = 4'b0010, addrPE4 = 4'b0011, addrPE5 = 4'b1001;
    localparam addrAdd1 = 4'b0100, addrAdd2 = 4'b0111, addrAdd3 = 4'b1010, addrAdd4 = 4'b1000, addrAdd5 = 4'b1101;

    logic [PACKET_WIDTH-1:0] packetValue1 = 0, packetValue2 = 0;
    logic [$clog2(IFMAP_LENGTH)-1:0] ifmapValue = 0;
    logic [MEM_WIDTH-1:0] psumOutValue = 0;
    logic [ADDR_WIDTH-1:0] addrValue = 0;
    logic [CONVOLUTIONS_PER_ROW-1:0] convCounter = 0;

    logic [3:0] adderArray[4:0] = {addrAdd1, addrAdd2, addrAdd3, addrAdd4, addrAdd5};

    always begin
        addrIn.Receive(addrValue);
    end

    always begin
        fork
            psumOut.Receive(psumOutValue);
            convCount.Receive(convCounter);
        join
        #FL;
        packetValue1 = {addrValue, adderArray[convCounter], 2'b10, 41'b0, psumOutValue};
        packet.Send(packetValue1);
        #BL;
    end

    always begin
        ifmapIn.Receive(ifmapValue);
        #FL;
        case (addrValue)
            addrPE2 : packetValue2 = {addrValue, addrPE1, 2'b00, 29'b0, ifmapValue};
            addrPE3 : packetValue2 = {addrValue, addrPE2, 2'b00, 29'b0, ifmapValue};
            addrPE4 : packetValue2 = {addrValue, addrPE3, 2'b00, 29'b0, ifmapValue};
            addrPE5 : packetValue2 = {addrValue, addrPE4, 2'b00, 29'b0, ifmapValue};
        endcase
        packet.Send(packetValue2);
        #BL;
    end
endmodule

module depacketizerConv(interface packet, interface filterOut, interface ifmapOut, interface addrOut);
    parameter WIDTH = 64;
    parameter ADDR_WIDTH = 4;
    parameter IFMAP_LENGTH = 25;
    parameter FILTER_LENGTH = 40;
    parameter FL = 2;
    parameter BL = 1;

    logic [WIDTH-1:0] packetValue = 0;
    logic [FILTER_LENGTH-1:0] filterValue = 0;
    logic [IFMAP_LENGTH-1:0] ifmapValue = 0;
    logic [ADDR_WIDTH-1:0] addrValue = 0;

    always begin
        packet.Receive(packetValue);
        $display("Received the Packet:::::%b", packetValue);
        #FL;
        if (packetValue[WIDTH-9:WIDTH-10] == 00) begin
            ifmapValue = packetValue[0+:IFMAP_LENGTH];
            ifmapOut.Send(ifmapValue);
        end
        else if (packetValue[WIDTH-9:WIDTH-10] == 01) begin
            filterValue = packetValue[0+:FILTER_LENGTH];
            filterOut.Send(filterValue);
        end
        addrValue = packetValue[WIDTH-5:WIDTH-8];
        addrOut.Send(addrValue);
        #BL;
    end
endmodule

module ifmapMemConv(interface ifmapIn, interface ifmapOut, interface toPacketizer, interface convDone);
    parameter IFMAP_LENGTH = 25;
    parameter CONVOLUTION_ROW = 5;
    parameter CONVOLUTIONS_PER_ROW = 21;
    parameter FL = 2;
    parameter BL = 1;

    logic sendVal = 0;
    logic [CONVOLUTION_ROW-1:0] convolutionsDonePerRow, convolutionVal;
    logic [IFMAP_LENGTH-1:0] ifmapRow = 0, oldIfmapRow = 0;
    integer convolutionCounter = 0;

    always begin
        ifmapIn.Receive(ifmapRow);
        $display("Received ifmapROW::::::%b", ifmapRow);
        convolutionCounter += 1;
        #FL;
        // toPacketizer.Send(oldIfmapRow);
        for (convolutionsDonePerRow = 0; convolutionsDonePerRow < CONVOLUTIONS_PER_ROW; convolutionsDonePerRow ++) begin
            for (convolutionVal = convolutionsDonePerRow; convolutionVal < convolutionsDonePerRow + CONVOLUTION_ROW; convolutionVal++) begin
                sendVal = ifmapRow[convolutionVal];
                ifmapOut.Send(sendVal);
                #BL;
            end
            convDone.Send(convolutionsDonePerRow);
        end
        oldIfmapRow = ifmapRow;
        toPacketizer.Send(oldIfmapRow);
        if (convolutionCounter == CONVOLUTION_ROW) begin
            convolutionCounter = 0;
        end
    end
endmodule

module filterMemConv(interface filterIn, interface convCount, interface filterOut);
    parameter FILTER_LENGTH = 40;
    parameter WIDTH = 8;
    parameter CONVOLUTIONS_PER_ROW = 21;
    parameter FL = 2;
    parameter BL = 1;

    logic [WIDTH-1:0] sendVal;
    logic [FILTER_LENGTH-1:0] filterRow = 0;
    logic [CONVOLUTIONS_PER_ROW-1:0] convolutionsDonePerRow, filterSendCount;

    always begin
        filterIn.Receive(filterRow);
        $display("Received filterrow::::::%b", filterRow);
        #FL;
        while(1) begin
            for (convolutionsDonePerRow = 0; convolutionsDonePerRow < CONVOLUTIONS_PER_ROW; convolutionsDonePerRow++) begin
                for (filterSendCount = 0; filterSendCount < FILTER_LENGTH/WIDTH; filterSendCount++) begin
                    sendVal = filterRow[filterSendCount*8 +: 8];
                    convCount.Send(filterSendCount);
                    filterOut.Send(sendVal);
                    #BL;
                end
            end
        end
    end
endmodule

module multiplierConv(interface ifmapIn, interface filterIn, interface multOut);
    parameter WIDTH = 8;
    parameter FL = 2;
    parameter BL = 1;

    logic [WIDTH-1:0] filterVal = 0, product = 0;
    logic ifmapVal = 0;

    always begin
        fork
            ifmapIn.Receive(ifmapVal);
            filterIn.Receive(filterVal);
        join
        $display("Received Multiplicants:::::::%b %b",ifmapVal, filterVal);
        #FL;
        product = ifmapVal * filterVal;
        multOut.Send(product);
        #BL;
    end
endmodule

module adderConv(interface accumIn, interface multIn, interface adderOut);
    parameter WIDTH = 13;
    parameter FL = 2;
    parameter BL = 1;

    logic [WIDTH-1:0] accumVal = 0, multVal = 0, sum = 0;

    always begin
        fork
            accumIn.Receive(accumVal);
            multIn.Receive(multVal);
        join
        $display("Received accum and Mult values:::::::%b ---- %b", accumVal, multVal);
        #FL;
        sum = accumVal + multVal;
        adderOut.Send(sum);
        #BL;
    end
endmodule

module splitConv(interface in, interface convCount, interface accumOut, interface psumOut);
    parameter WIDTH = 13;
    parameter FL = 2;
    parameter BL = 1;
    parameter CONVOLUTIONS_PER_ROW = 5;

    logic [WIDTH-1:0] token = 0;
    logic [CONVOLUTIONS_PER_ROW-1:0] convolutionsDonePerRow = 0;

    always begin
        convCount.Receive(convolutionsDonePerRow);
        if (convolutionsDonePerRow != CONVOLUTIONS_PER_ROW-1) begin
            in.Receive(token);
            $display("Received Token in splitConv :::::: %b", token);
            #FL;
            accumOut.Send(token);
            #BL;
        end
        else begin
            in.Receive(token);
            #FL;
            psumOut.Send(token);
            accumOut.Send(0);
            #BL;
        end
    end
endmodule

module accumulatorConv(interface in, interface out);
    parameter WIDTH = 13;
    parameter FL = 2;
    parameter BL = 1;

    logic [WIDTH-1:0] token = 0;

    initial begin
        out.Send(0);
        #BL;
    end

    always begin
        in.Receive(token);
        $display("Received Token in Accumulator::::::%b", token);
        #FL;
        out.Send(token);
        #BL;
    end
endmodule

module pe(interface packetIn, interface packetOut);
    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(64)) intf [12:0] ();

    depacketizerConv #(.ADDR_WIDTH(4), .IFMAP_LENGTH(25), .FILTER_LENGTH(40), .WIDTH(64), .FL(2), .BL(1))
        depacket(.packet(packetIn), .filterOut(intf[0]), .ifmapOut(intf[1]), .addrOut(intf[2]));
    filterMemConv #(.FILTER_LENGTH(40), .CONVOLUTIONS_PER_ROW(21), .WIDTH(8), .FL(2), .BL(1))
        memFilter(.filterIn(intf[0]), .convCount(intf[3]), .filterOut(intf[4]));
    ifmapMemConv #(.IFMAP_LENGTH(25), .CONVOLUTIONS_PER_ROW(21), .CONVOLUTION_ROW(5), .FL(2), .BL(1))
        memIfmap(.ifmapIn(intf[1]), .ifmapOut(intf[5]), .toPacketizer(intf[6]), .convDone(intf[12]));
    multiplierConv #(.WIDTH(8), .FL(2), .BL(1)) mult(.filterIn(intf[4]), .ifmapIn(intf[5]), .multOut(intf[7]));
    adderConv #(.WIDTH(13), .FL(2), .BL(1)) add(.multIn(intf[7]), .accumIn(intf[8]), .adderOut(intf[9]));
    splitConv #(.CONVOLUTIONS_PER_ROW(5), .WIDTH(13), .FL(2), .BL(1)) spl(.in(intf[9]), .convCount(intf[3]), .accumOut(intf[10]), .psumOut(intf[11]));
    accumulatorConv #(.WIDTH(13), .FL(2), .BL(1)) accum(.in(intf[10]), .out(intf[8]));
    packetizerConv #(.ADDR_WIDTH(4), .CONVOLUTIONS_PER_ROW(21), .IFMAP_LENGTH(25), .PACKET_WIDTH(64), .MEM_WIDTH(13), .FL(2), .BL(1))
        packet(.psumOut(intf[11]), .ifmapIn(intf[6]), .convCount(intf[12]), .addrIn(intf[2]), .packet(packetOut));
endmodule


///////////////////////////// TESTBENCH///////////////////////////////////////////
// module pe_tb;
//     Channel #(.hsProtocol(P4PhaseBD), .WIDTH(64)) intf  [1:0] ();
//     data_generator #(.WIDTH(64)) d0 (intf[0]);
//     peTB pe (intf[0], intf[1]);
//     data_bucket #(.WIDTH(64)) db (intf[1]);
// endmodule