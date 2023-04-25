`timescale 1ns/1fs
import SystemVerilogCSP :: *;

module depacketizer(interface packet_in, interface ifmap_out, interface filtermap_out, interface residue_out, interface partial_sum_out);
parameter WIDTH_OF_PACKET = 64;
parameter ADDRESS_WIDTH = 4;
parameter IFMAP_LENGTH = 25;
parameter FILTER_LENGTH = 40;
parameter RESIDUE_LENGTH = 13;
parameter PARTIAL_ADDER_INPUT_LENGTH = 13;
parameter FL = 2;
parameter BL = 2;

logic [WIDTH_OF_PACKET-1:0] packet_data = 0;
logic [FILTER_LENGTH-1:0] filter_data = 0;
logic [IFMAP_LENGTH-1:0] ifmap_data = 0;
logic [RESIDUE_LENGTH-1:0] residue_data = 0;
logic [PARTIAL_ADDER_INPUT_LENGTH-1:0] partial_sum_data = 0;

always begin
    packet_in.Receive(packet_data);
    #FL;
    if(packet_data[WIDTH_OF_PACKET-9:WIDTH_OF_PACKET-10] == 2'b00) begin
        ifmap_data = packet_data[0+:IFMAP_LENGTH];
        ifmap_out.Send(ifmap_data);
    end
    else if(packet_data[WIDTH_OF_PACKET-9:WIDTH_OF_PACKET-10] == 2'b01) begin
        filter_data = packet_data[0+:FILTER_LENGTH];
        filtermap_out.Send(filter_data);
    end
    else if(packet_data[WIDTH_OF_PACKET-9:WIDTH_OF_PACKET-10] == 2'b10) begin
        residue_data = packet_data[0+:RESIDUE_LENGTH];
        residue_out.Send(residue_data);
    end
    else if(packet_data[WIDTH_OF_PACKET-9:WIDTH_OF_PACKET-10] == 2'b11) begin
        partial_sum_data = packet_data[0+:PARTIAL_ADDER_INPUT_LENGTH];
        partial_sum_out.Send(partial_sum_data);
    end
    #BL;
end
endmodule

module multiplier(interface ifmap_in, interface filter_mem, interface mult_out);
parameter IFMAP_WIDTH = 1;
paramter FILTER_WIDTH = 8;
parameter MULT_WIDTH = 8;
parameter FL = 2;
parameter BL = 2;

logic [IFMAP_WIDTH-1:0] ifmap_data;
logic [FILTER_WIDTH-1:0] filter_data;
logic [MULT_WIDTH-1:0] mult_data;

always begin
    fork
        ifmap_in.Receive(ifmap_data);
        filter_data.Receive(filter_data);
    join
    #FL;
    mult_data = ifmap_data * filter_data;
    mult_out.Send(mult_data);
    #BL;
end
endmodule

module adderCumAccum(interface mult_in, interface adder_out);
parameter MULT_IN_WIDTH = 8;
parameter ADDER_WIDTH = 13;
parameter NUMBER_OF_ITERATIONS = 5;
parameter FL = 2;
parameter BL = 2;

integer i = 0;

logic [MULT_IN_WIDTH-1:0] mult_data = 0;
logic [ADDER_WIDTH-1:0] adderCumAccumData = 0;

always begin
    for(i = 0; i<NUMBER_OF_ITERATIONS; i = i + 1)begin
        mult_in.Receive(mult_data);
        #FL;
        adderCumAccumData = adderCumAccumData + mult_data;
    end
    adder_out.Send(adderCumAccumData);
    adderCumAccumData = 0;
    #BL;
end
endmodule

module packetizer(interface ifmap_data_in, interface adder_data_in, interface packet_out);
parameter DESTINATION_ADDRESS_PSUM_PE = 4'b0000;
parameter DESTINATION_ADDRESS_CONV_PE = 4'b0000;
parameter SOURCE_ADDRESS = 4'b0000;
parameter PACKET_TYPE_PSUM_PE = 2'b11;
parameter PACKET_TYPE_CONV_PE = 2'b00;
parameter DATA_WIDTH_ADDER = 13;
parameter DATA_WIDTH_CONV = 25;
parameter CONV_COUNT = 21;
parameter FL = 2;
parameter BL = 2;
localparam PADDING_PSUM_PE = 54 - DATA_WIDTH_ADDER;
localparam PADDING_PSUM_PE = 54 - DATA_WIDTH_CONV;// 64-4-4-2-DATA_WIDTH
logic [DATA_WIDTH-1:0] data_adder;
logic [DATA_WIDTH_CONV-1:-0] data_ifmap;

always begin
    for (i=0; i<CONV_COUNT; i=i+1) begin
        adder_data_in.Receive(data_adder);
        #FL;
        packet_out.Send({DESTINATION_ADDRESS_PSUM_PE,SOURCE_ADDRESS,PACKET_TYPE_PSUM_PE,PADDING_PSUM_PE'd0,data_adder});
        #BL;
    end
    ifmap_data_in.Receive(data_ifmap);
    #FL;
    packet_out.Send({DESTINATION_ADDRESS_CONV_PE,SOURCE_ADDRESS,PACKET_TYPE_CONV_PE,PADDING_CONV_PE'd0,data_ifmap});
end
endmodule

module ifmap_mem(interface ifmap_data_in, interface to_mult, interface to_packetizer);
parameter IF_MAP_WIDTH = 25;
parameter DEPTH = 25;
parameter NUMBER_OF_CONVOLUTIONS = 21;
localparam WIDTH = IF_MAP_WIDTH/DEPTH;
parameter FL = 2;
parameter BL = 2;

logic [IF_MAP_WIDTH-1:0] data_in = 0;
logic [IF_MAP_WIDTH-1:0] old_data = 0;
logic [WIDTH-1:0] mem [DEPTH-1:0];
integer i;
integer numberOfConvolutions = 0;
integer flag = 0;

always begin
    ifmap_data_in.Receive(data_in);
    #FL;
    for(i=0;i<DEPTH;i=i+1) begin
        mem[i] = data_in[i*WIDTH+:WIDTH];
    end
    for(numberOfConvolutions = 0; numberOfConvolutions < NUMBER_OF_CONVOLUTIONS; numberOfConvolutions = numberOfConvolutions + 1) begin
        for(i = numberOfConvolutions;i < numberOfConvolutions + DEPTH;i = i + 1) begin
        #FL;
        to_mult.Send(mem[i]);
        #BL;
        end
    end
    flag = 1;
    old_data = data_in;
end
always @(flag) begin
    if(flag) begin
        #FL;
        to_packetizer.Send(old_data);
        flag = 0;
        #BL;
    end
end
endmodule

module filter_mem(interface filter_data_in, interface to_mult);
parameter FILTER_WIDTH = 40;
parameter DEPTH = 5;
parameter NUMBER_OF_CONVOLUTIONS = 21;
localparam WIDTH = FILTER_WIDTH/DEPTH;
parameter FL = 2;
parameter BL = 2;

logic [FILTER_WIDTH-1:0] data_in = 0;
logic [WIDTH-1:0] mem [DEPTH-1:0];
integer i;
integer numberOfConvolutions0 = 0;
integer numberOfConvolutions1 = 0;


always begin
    filter_data_in.Receive(data_in);
    #FL;
    for(i=0;i<DEPTH;i=i+1) begin
        mem[i] = data_in[i*WIDTH+:WIDTH];
    end
    for(numberOfConvolutions0 = 0; numberOfConvolutions0 < NUMBER_OF_CONVOLUTIONS; numberOfConvolutions0 = numberOfConvolutions0 + 1) begin
        for(numberOfConvolutions1 = 0; numberOfConvolutions1 < NUMBER_OF_CONVOLUTIONS; numberOfConvolutions1 = numberOfConvolutions1 + 1) begin
            for(i = numberOfConvolutions1;i < numberOfConvolutions1 + DEPTH;i = i + 1) begin
            #FL;
            to_mult.Send(mem[i]);
            #BL;
            end
        end
    end
end
endmodule


module residue_mem(interface residue_data_in, interface to_packetizer);
parameter RESIDUE_WIDTH = 13;
parameter NO_OF_ENTRIES_IN_ROW = 21;
parameter NO_OF_ENTRIES_IN_COLUMN = 21;
parameter FL = 2;
parameter BL = 2;

logic [RESIDUE_WIDTH-1:0] data_in = 0;
logic [RESIDUE_WIDTH-1:0] mem [NO_OF_ENTRIES_IN_ROW-1:0][NO_OF_ENTRIES_IN_COLUMN-1:0];
integer i = 0;
integer k = 0;
integer count = 0;
integer j = 0;
integer l = 0;

always begin
    if(count <= 21*21) begin
        residue_data_in.Receive(data_in);
        mem[k%21][i] = data_in;
        if(i==20) begin i=0; k=k+1; end
        else i = i+1;
        count = count + 1;
        #BL;
    end
end

always begin
    if(count >= 21) begin
        #FL;
        for(j=0; j<21; j=j+1) begin
            to_packetizer.Send(mem[l%21][j]);
            count = count - 1; 
        end
        l = l+1;
    end
end
endmodule

module residue_packetizer(interface from_residue_mem, interface packet_out);
parameter SOURCE_ADDRESS = 4'b0000;
parameter DESTINATION_ADDRESS = 4'b0000;
parameter PACKET_TYPE = 2'b10;
parameter RESIDUE_WIDTH = 13;
localparam PADDING = 54 - RESIDUE_WIDTH;
logic [RESIDUE_WIDTH-1:0] residue_data_in=0;
parameter FL = 2;
parameter BL = 2;

always begin
    from_residue_mem.Recieve(residue_data_in);
    #FL;
    packet_out.Send({DESTINATION_ADDRESS, SOURCE_ADDRESS, PACKET_TYPE, PADDING'd0, residue_data_in});
    #BL;
end
endmodule

module partial_sum_depacketizer(interface packet_1, interface packet_2, interface data_1, interface data_2);
parameter WIDTH = 13;
parameter PACKET_WIDTH = 64;
parameter FL = 2;
parameter BL = 2;

logic [PACKET_WIDTH-1:0] packet_in1, packet_in2=0;

always begin
    packet_1.Receive(packet_in1);
    #FL;
    data_1.Send(packet_in1[0+:WIDTH]);
    #BL;
end
always begin
    packet_2.Receive(packet_in2);
    #FL;
    data_2.Send(packet_in2[0+:WIDTH]);
    #BL;
end
endmodule

module convolution_PE(interface packet_in, interface packet_out);
parameter DESTINATION_ADDRESS_PSUM_PE = 4'b0000;
parameter DESTINATION_ADDRESS_CONV_PE = 4'b0000;
parameter SOURCE_ADDRESS = 4'b0000;

Channel #(.hsProtocol(P4PhaseBD), .WIDTH(64)) intf [6:0] ();

depacketizer #(.WIDTH_OF_PACKET(64),
               .IFMAP_LENGTH(25),
               .FILTER_LENGTH(40),
               .RESIDUE_LENGTH(13),
               .PARTIAL_ADDER_INPUT_LENGTH(13)
               .FL(2),
               .BL(2)) d0 (.packet_in(packet_in),
                            .ifmap_out(intf[0]), 
                            .filtermap_out(intf[1]), 
                            .residue_out(dummy[0]),
                            .partial_sum_out(dummy[1]));
ifmap_mem #(.IF_MAP_WIDTH(25),
            .DEPTH(25),
            .NUMBER_OF_CONVOLUTIONS(21),
            .FL(2),
            .BL(2)) i0 (.ifmap_data_in(intf[0]), 
                        .to_mult(intf[2]), 
                        .to_packetizer(intf[3]));
filter_mem #(.FILTER_WIDTH(40),
             .DEPTH(5),
             .NUMBERPF_CONVOLUTIONS(21),
             .FL(2),
             .BL(2)) f0 (.filter_data_in(intf[1]),
                         .to_mult(intf[4]));
multiplier #(.IFMAP_WIDTH(1),
             .FILTER_WIDTH(8),
             .MULT_WIDTH(8)) m0 (.ifmap_in(intf[2]),
                                .filter_mem(intf[4]),
                                .mult_out(intf[5]));
adderCumAccum #(.MULT_IN_WIDTH(8),
                .ADDER_WIDTH(13),
                .NUMBER_OF_ITERATIONS(5),
                .FL(2),
                .BL(2)) a0 (.mult_in(intf[5]),
                           .adder_out(intf[6]));
packetizer #(.DESTINATION_ADDRESS_CONV_PE(DESTINATION_ADDRESS_CONV_PE),
             .DESTINATION_ADDRESS_PSUM_PE(DESTINATION_ADDRESS_PSUM_PE),
             .SOURCE_ADDRESS(SOURCE_ADDRESS),
             .DATA_WIDTH_ADDER(13),
             .DATA_WIDTH_CONV(25),
             .CONV_COUNT(21),
             .FL(2),
             .BL(2)) p1 (.ifmap_data_in(intf[3]),
                         .adder_data_in(intf[6]),
                         .packet_out(packet_out));
endmodule

module partial_sum_PE(interface packet_in, interface packet_out);
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(64)) intf [6:0] ();

depacketizer #(.WIDTH_OF_PACKET(64),
               .IFMAP_LENGTH(25),
               .FILTER_LENGTH(40),
               .RESIDUE_LENGTH(13),
               .PARTIAL_ADDER_INPUT_LENGTH(13)
               .FL(2),
               .BL(2)) d0 (.packet_in(packet_in),
                            .ifmap_out(dummy[0]), 
                            .filtermap_out(intf[1]), 
                            .residue_out(dummy[0]),
                            .partial_sum_out(dummy[1]));
endmodule

module residue_mem(interface packet_in, interface packet_out);
endmodule