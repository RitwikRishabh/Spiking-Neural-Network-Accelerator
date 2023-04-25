
`timescale 1ns/100ps
import SystemVerilogCSP :: *;

// module noc(interface from_ifmap, interface from_filtermap, interface to_output);

// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(64)) intf [0:31] ();
// // Channel #(.hsProtocol(P4PhaseBD), .WIDTH(64)) intf [14:15] ();
// // Channel #(.hsProtocol(P4PhaseBD), .WIDTH(64)) intf [16:21] ();
// // Channel #(.hsProtocol(P4PhaseBD), .WIDTH(64)) intf [23:31] ();

// router_4x4_torus #(.FL(2), .BL(1), .WIDTH(64)) r0 (intf[0:15], intf[16:31]);
// assign from_ifmap = intf[12];
// assign from_filtermap = intf[13];
// assign to_output = intf[22];

// //router_4x4_torus #(.FL(2), .BL(1), .WIDTH(64)) r0 (intf[0:15],  intf[16:31]);

// pe pe1 (.packetIn(intf[8]),
//         .packetOut(intf[24]));
// pe pe2 (.packetIn(intf[9]),
//         .packetOut(intf[25]));
// pe pe3 (.packetIn(intf[0]),
//         .packetOut(intf[16]));
// pe pe4 (.packetIn(intf[1]),
//         .packetOut(intf[17]));
// pe pe5 (.packetIn(intf[15]),
//         .packetOut(intf[31]));

// partial_sum ps1 (.in(intf[4]),
//                  .out(intf[20]));
// partial_sum ps2 (.in(intf[5]),
//                  .out(intf[21]));
// partial_sum ps3 (.in(intf[2]),
//                  .out(intf[18]));
// partial_sum ps4 (.in(intf[3]),
//                  .out(intf[19]));
// partial_sum ps5 (.in(intf[7]),
//                  .out(intf[23]));
// partial_sum ps6 (.in(intf[10]),
//                  .out(intf[26]));
// partial_sum ps7 (.in(intf[11]),
//                  .out(intf[27]));
// endmodule


module snn;

//Channel #(.hsProtocol(P4PhaseBD), .WIDTH(64)) intff [0:3] ();
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(64)) intf [0:31] ();

pe pe1 (.packetIn(intf[24]),
        .packetOut(intf[8]));
pe pe2 (.packetIn(intf[25]),
        .packetOut(intf[9]));
pe pe3 (.packetIn(intf[16]),
        .packetOut(intf[0]));
pe pe4 (.packetIn(intf[17]),
        .packetOut(intf[1]));
pe pe5 (.packetIn(intf[31]),
        .packetOut(intf[15]));

partial_sum ps1 (.in(intf[20]),
                 .out(intf[4]));
partial_sum ps2 (.in(intf[21]),
                 .out(intf[5]));
partial_sum ps3 (.in(intf[18]),
                 .out(intf[2]));
partial_sum ps4 (.in(intf[19]),
                 .out(intf[3]));
partial_sum ps5 (.in(intf[23]),
                 .out(intf[7]));
partial_sum ps6 (.in(intf[26]),
                 .out(intf[10]));
partial_sum ps7 (.in(intf[27]),
                 .out(intf[11]));

router_4x4_torus #(.FL(2), .BL(1), .WIDTH(64)) r0 (intf[0:15], intf[16:31]);
memoryController mc (intf[13], intf[12], intf[22]);
// noc n0 (intff[1], intff[0], intff[2]);

initial begin
    #100000 $stop; 
end
endmodule





