
`timescale 1ns/1fs
import SystemVerilogCSP::*;

module split_1x5(interface in, out_0, out_1, out_2, out_3, out_4);
parameter FL = 2;
parameter BL = 2;
parameter WIDTH = 32;
parameter X_LOCATION = 2'b00;
parameter Y_LOCATION = 2'b00;

localparam dest_bits_loc = 31;

logic [WIDTH-1:0]packet;
logic [1:0] x_dest, y_dest;

always begin
    in.Receive(packet);
    //$display("Received Packet at %m, Packet value : %h", packet);
    {x_dest,y_dest} = packet[dest_bits_loc-:4];
    //$display("x_dest :: %b, y_dest :: %b",x_dest, y_dest);
    //$display("x_LOCATION :: %b, y_LOCATION :: %b",X_LOCATION, Y_LOCATION);
    if (x_dest == X_LOCATION && y_dest == Y_LOCATION) begin
        out_0.Send(packet);
        //$display("SENDING PACKET TO PE!!");
    end
    else if(x_dest > X_LOCATION) begin
        out_1.Send(packet); // send it to East
        //$display("SENDING PACKET TO EAST!!");
    end
    else if(x_dest < X_LOCATION) begin
        out_2.Send(packet); // send it to West
        //$display("SENDING PACKET TO WEST!!");
    end
    else if(y_dest > Y_LOCATION) begin
        out_3.Send(packet); // send it to North
        //$display("SENDING PACKET TO NORTH!!");
    end
    else if(y_dest < Y_LOCATION) begin
        out_4.Send(packet); // send it to South
        //$display("SENDING PACKET TO SOUTH!!");
    end
end
endmodule

module split_5x20(interface in_intf4, in_intf3, in_intf2, in_intf1, in_intf0, interface out_intf[24:0] );
parameter FL = 2;
parameter BL = 2;
parameter WIDTH = 32;
parameter X_LOCATION = 2'b00;
parameter Y_LOCATION = 2'b00;

split_1x5 #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(X_LOCATION), .Y_LOCATION(Y_LOCATION)) s0 (.in(in_intf4), 
                                                                                                    .out_0(out_intf[0]), // to PE   intf[0 5 10 15 20]
                                                                                                    .out_1(out_intf[1]), // to East intf[1 6 11 16 21]
                                                                                                    .out_2(out_intf[2]), // to West intf[2 7 12 17 22]
                                                                                                    .out_3(out_intf[3]), // to North intf[3 8 13 18 23]
                                                                                                    .out_4(out_intf[4])); // to South intf[4 9 14 19 24]
split_1x5 #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(X_LOCATION), .Y_LOCATION(Y_LOCATION)) s1 (.in(in_intf3), 
                                                                                                    .out_0(out_intf[5]), // to PE   intf[0 5 10 15 20]
                                                                                                    .out_1(out_intf[6]), // to East intf[1 6 11 16 21]
                                                                                                    .out_2(out_intf[7]), // to West intf[2 7 12 17 22]
                                                                                                    .out_3(out_intf[8]), // to North intf[3 8 13 18 23]
                                                                                                    .out_4(out_intf[9])); // to South intf[4 9 14 19 24]
split_1x5 #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(X_LOCATION), .Y_LOCATION(Y_LOCATION)) s2 (.in(in_intf2), 
                                                                                                    .out_0(out_intf[10]), // to PE   intf[0 5 10 15 20]
                                                                                                    .out_1(out_intf[11]), // to East intf[1 6 11 16 21]
                                                                                                    .out_2(out_intf[12]), // to West intf[2 7 12 17 22]
                                                                                                    .out_3(out_intf[13]), // to North intf[3 8 13 18 23]
                                                                                                    .out_4(out_intf[14])); // to South intf[4 9 14 19 24]
split_1x5 #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(X_LOCATION), .Y_LOCATION(Y_LOCATION)) s3 (.in(in_intf1), 
                                                                                                    .out_0(out_intf[15]), // to PE   intf[0 5 10 15 20]
                                                                                                    .out_1(out_intf[16]), // to East intf[1 6 11 16 21]
                                                                                                    .out_2(out_intf[17]), // to West intf[2 7 12 17 22]
                                                                                                    .out_3(out_intf[18]), // to North intf[3 8 13 18 23]
                                                                                                    .out_4(out_intf[19])); // to South intf[4 9 14 19 24]
split_1x5 #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(X_LOCATION), .Y_LOCATION(Y_LOCATION)) s4 (.in(in_intf0), 
                                                                                                    .out_0(out_intf[20]), // to PE   intf[0 5 10 15 20]
                                                                                                    .out_1(out_intf[21]), // to East intf[1 6 11 16 21]
                                                                                                    .out_2(out_intf[22]), // to West intf[2 7 12 17 22]
                                                                                                    .out_3(out_intf[23]), // to North intf[3 8 13 18 23]
                                                                                                    .out_4(out_intf[24])); // to South intf[4 9 14 19 24]                                                                                                                                                                                                                                                                                                          

endmodule


module router (interface in_PE, in_East, in_West, in_North, in_South,
               interface out_PE, out_East, out_West, out_North, out_South);
parameter FL = 2;
parameter BL = 2;
parameter WIDTH = 32;
parameter X_LOCATION = 2'b00;
parameter Y_LOCATION = 2'b00;

localparam dest_bits_loc = 31;

Channel #(.hsProtocol(P4PhaseBD), .WIDTH(WIDTH)) intf  [24:0] ();

split_5x20 #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(X_LOCATION), .Y_LOCATION(Y_LOCATION)) sp (in_PE, 
                                                                                                   in_East,
                                                                                                   in_West,
                                                                                                   in_North,
                                                                                                   in_South,
                                                                                                   intf[24:0]);
arbiter_4_ip_1_op #(.FL(FL), .BL(BL), .WIDTH(WIDTH)) arb0 (.in_0(intf[5]),
                                                          .in_1(intf[10]),
                                                          .in_2(intf[15]),
                                                          .in_3(intf[20]),
                                                          .out(out_PE));
arbiter_4_ip_1_op #(.FL(FL), .BL(BL), .WIDTH(WIDTH)) arb1 (.in_0(intf[1]),
                                                          .in_1(intf[11]),
                                                          .in_2(intf[16]),
                                                          .in_3(intf[21]),
                                                          .out(out_East));
arbiter_4_ip_1_op #(.FL(FL), .BL(BL), .WIDTH(WIDTH)) arb2 (.in_0(intf[2]),
                                                          .in_1(intf[7]),
                                                          .in_2(intf[17]),
                                                          .in_3(intf[22]),
                                                          .out(out_West));
arbiter_4_ip_1_op #(.FL(FL), .BL(BL), .WIDTH(WIDTH)) arb3 (.in_0(intf[3]),
                                                          .in_1(intf[8]),
                                                          .in_2(intf[13]),
                                                          .in_3(intf[23]),
                                                          .out(out_North));
arbiter_4_ip_1_op #(.FL(FL), .BL(BL), .WIDTH(WIDTH)) arb4 (.in_0(intf[4]),
                                                          .in_1(intf[9]),
                                                          .in_2(intf[14]),
                                                          .in_3(intf[19]),
                                                          .out(out_South));

endmodule


module router_4x4(interface in_PE[0:15],
                  interface out_PE[0:15]);
parameter FL = 2;
parameter BL = 2;
parameter WIDTH = 32;

Channel #(.hsProtocol(P4PhaseBD), .WIDTH(WIDTH)) intf  [0:47] ();
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(WIDTH)) dummy  [0:31] ();


router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b00), .Y_LOCATION(2'b11)) r0 (.in_PE(in_PE[0]),
                                                                                      .in_East(intf[0]),
                                                                                      .in_West(dummy[0]),
                                                                                      .in_North(dummy[1]),
                                                                                      .in_South(intf[1]),
                                                                                      .out_PE(out_PE[0]),
                                                                                      .out_East(intf[2]),
                                                                                      .out_West(dummy[2]),
                                                                                      .out_North(dummy[3]),
                                                                                      .out_South(intf[3]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b01), .Y_LOCATION(2'b11)) r1 (.in_PE(in_PE[1]),
                                                                                      .in_East(intf[4]),
                                                                                      .in_West(intf[2]),
                                                                                      .in_North(dummy[4]),
                                                                                      .in_South(intf[5]),
                                                                                      .out_PE(out_PE[1]),
                                                                                      .out_East(intf[6]),
                                                                                      .out_West(intf[0]),
                                                                                      .out_North(dummy[5]),
                                                                                      .out_South(intf[7]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b10), .Y_LOCATION(2'b11)) r2 (.in_PE(in_PE[2]),
                                                                                      .in_East(intf[8]),
                                                                                      .in_West(intf[6]),
                                                                                      .in_North(dummy[6]),
                                                                                      .in_South(intf[9]),
                                                                                      .out_PE(out_PE[2]),
                                                                                      .out_East(intf[10]),
                                                                                      .out_West(intf[4]),
                                                                                      .out_North(dummy[7]),
                                                                                      .out_South(intf[11]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b11), .Y_LOCATION(2'b11)) r3 (.in_PE(in_PE[3]),
                                                                                      .in_East(dummy[8]),
                                                                                      .in_West(intf[10]),
                                                                                      .in_North(dummy[9]),
                                                                                      .in_South(intf[12]),
                                                                                      .out_PE(out_PE[3]),
                                                                                      .out_East(dummy[10]),
                                                                                      .out_West(intf[8]),
                                                                                      .out_North(dummy[11]),
                                                                                      .out_South(intf[13]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b00), .Y_LOCATION(2'b10)) r4 (.in_PE(in_PE[4]),
                                                                                      .in_East(intf[14]),
                                                                                      .in_West(dummy[12]),
                                                                                      .in_North(intf[3]),
                                                                                      .in_South(intf[15]),
                                                                                      .out_PE(out_PE[4]),
                                                                                      .out_East(intf[16]),
                                                                                      .out_West(dummy[13]),
                                                                                      .out_North(intf[1]),
                                                                                      .out_South(intf[17]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b01), .Y_LOCATION(2'b10)) r5 (.in_PE(in_PE[5]),
                                                                                      .in_East(intf[18]),
                                                                                      .in_West(intf[16]),
                                                                                      .in_North(intf[7]),
                                                                                      .in_South(intf[19]),
                                                                                      .out_PE(out_PE[5]),
                                                                                      .out_East(intf[20]),
                                                                                      .out_West(intf[14]),
                                                                                      .out_North(intf[5]),
                                                                                      .out_South(intf[21]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b10), .Y_LOCATION(2'b10)) r6 (.in_PE(in_PE[6]),
                                                                                      .in_East(intf[22]),
                                                                                      .in_West(intf[20]),
                                                                                      .in_North(intf[11]),
                                                                                      .in_South(intf[23]),
                                                                                      .out_PE(out_PE[6]),
                                                                                      .out_East(intf[24]),
                                                                                      .out_West(intf[18]),
                                                                                      .out_North(intf[9]),
                                                                                      .out_South(intf[25]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b11), .Y_LOCATION(2'b10)) r7 (.in_PE(in_PE[7]),
                                                                                      .in_East(dummy[14]),
                                                                                      .in_West(intf[24]),
                                                                                      .in_North(intf[13]),
                                                                                      .in_South(intf[26]),
                                                                                      .out_PE(out_PE[7]),
                                                                                      .out_East(dummy[15]),
                                                                                      .out_West(intf[22]),
                                                                                      .out_North(intf[12]),
                                                                                      .out_South(intf[27]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b00), .Y_LOCATION(2'b01)) r8 (.in_PE(in_PE[8]),
                                                                                      .in_East(intf[28]),
                                                                                      .in_West(dummy[16]),
                                                                                      .in_North(intf[17]),
                                                                                      .in_South(intf[29]),
                                                                                      .out_PE(out_PE[8]),
                                                                                      .out_East(intf[30]),
                                                                                      .out_West(dummy[17]),
                                                                                      .out_North(intf[15]),
                                                                                      .out_South(intf[31]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b01), .Y_LOCATION(2'b01)) r9 (.in_PE(in_PE[9]),
                                                                                      .in_East(intf[32]),
                                                                                      .in_West(intf[30]),
                                                                                      .in_North(intf[21]),
                                                                                      .in_South(intf[33]),
                                                                                      .out_PE(out_PE[9]),
                                                                                      .out_East(intf[34]),
                                                                                      .out_West(intf[28]),
                                                                                      .out_North(intf[19]),
                                                                                      .out_South(intf[35]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b10), .Y_LOCATION(2'b01)) r10 (.in_PE(in_PE[10]),
                                                                                      .in_East(intf[36]),
                                                                                      .in_West(intf[34]),
                                                                                      .in_North(intf[25]),
                                                                                      .in_South(intf[37]),
                                                                                      .out_PE(out_PE[10]),
                                                                                      .out_East(intf[38]),
                                                                                      .out_West(intf[32]),
                                                                                      .out_North(intf[23]),
                                                                                      .out_South(intf[39]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b11), .Y_LOCATION(2'b01)) r11 (.in_PE(in_PE[11]),
                                                                                      .in_East(dummy[8]),
                                                                                      .in_West(intf[38]),
                                                                                      .in_North(intf[27]),
                                                                                      .in_South(intf[40]),
                                                                                      .out_PE(out_PE[11]),
                                                                                      .out_East(dummy[19]),
                                                                                      .out_West(intf[36]),
                                                                                      .out_North(intf[26]),
                                                                                      .out_South(intf[41]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b00), .Y_LOCATION(2'b00)) r12 (.in_PE(in_PE[12]),
                                                                                      .in_East(intf[42]),
                                                                                      .in_West(dummy[20]),
                                                                                      .in_North(intf[31]),
                                                                                      .in_South(dummy[21]),
                                                                                      .out_PE(out_PE[12]),
                                                                                      .out_East(intf[43]),
                                                                                      .out_West(dummy[22]),
                                                                                      .out_North(intf[29]),
                                                                                      .out_South(dummy[23]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b01), .Y_LOCATION(2'b00)) r13 (.in_PE(in_PE[13]),
                                                                                      .in_East(intf[44]),
                                                                                      .in_West(intf[43]),
                                                                                      .in_North(intf[35]),
                                                                                      .in_South(dummy[24]),
                                                                                      .out_PE(out_PE[13]),
                                                                                      .out_East(intf[45]),
                                                                                      .out_West(intf[42]),
                                                                                      .out_North(intf[33]),
                                                                                      .out_South(dummy[25]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b10), .Y_LOCATION(2'b00)) r14 (.in_PE(in_PE[14]),
                                                                                      .in_East(intf[46]),
                                                                                      .in_West(intf[45]),
                                                                                      .in_North(intf[39]),
                                                                                      .in_South(dummy[26]),
                                                                                      .out_PE(out_PE[14]),
                                                                                      .out_East(intf[47]),
                                                                                      .out_West(intf[44]),
                                                                                      .out_North(intf[37]),
                                                                                      .out_South(dummy[27]));
router #(.FL(FL), .BL(BL), .WIDTH(WIDTH), .X_LOCATION(2'b11), .Y_LOCATION(2'b00)) r15 (.in_PE(in_PE[15]),
                                                                                      .in_East(dummy[28]),
                                                                                      .in_West(intf[47]),
                                                                                      .in_North(intf[41]),
                                                                                      .in_South(dummy[29]),
                                                                                      .out_PE(out_PE[15]),
                                                                                      .out_East(dummy[30]),
                                                                                      .out_West(intf[46]),
                                                                                      .out_North(intf[40]),
                                                                                      .out_South(dummy[31]));

endmodule



////////////////////////////////////////////////////testbench////////////////////////////////////////////

// //Sample data_generator module
// module data_generator (interface r);
//   parameter FL = 2;
//   parameter SENDVALUE = 32'h1111_1111;
//   parameter WIDTH = 32;
//   //logic [WIDTH-1:0] SendValue=0;
//   initial
//   begin 
    
// 	//add a display here to see when this module starts its main loop
//     //$display("*** %m %d",$time);
	
//     //SendValue = $random() % (2**WIDTH); // the range of random number is from 0 to 2^WIDTH
//     #FL;   // change FL and check the change of performance
     
//     //Communication action Send is about to start
//     //$display("Start sending in module %m. Simulation time =%t", $time);
//     r.Send(SENDVALUE);
//     //$display("SENDING VALUE::::%b", SENDVALUE);
	
//     //Communication action Send is finished
//     //$display("Finished sending in module %m. Simulation time =%t", $time);
	

//   end
// endmodule

// //Sample data_bucket module
// module data_bucket (interface r);
//   parameter WIDTH = 32;
//   parameter BL = 0; //ideal environment    backward delay
//   logic [WIDTH-1:0] ReceiveValue = 0;
  
//   //Variables added for performance measurements
//   real cycleCounter=0, //# of cycles = Total number of times a value is received
//        timeOfReceive=0, //Simulation time of the latest Receive 
//        cycleTime=0; // time difference between the last two receives
//   real averageThroughput=0, averageCycleTime=0, sumOfCycleTimes=0;
//   always
//   begin
	
// 	//add a display here to see when this module starts its main loop
//   //$display("*** %m %d",$time);

//     timeOfReceive = $time;
	
// 	//Communication action Receive is about to start
// 	//$display("Start receiving in module %m. Simulation time =%t", $time);
//     r.Receive(ReceiveValue);

//     //$display("Received Data: %d ------ %b", ReceiveValue, ReceiveValue);
//     $display("\nPacket Received at DATA BUCKET %m and Packet value: %h\n", ReceiveValue);
	
// 	//Communication action Receive is finished
//   //$display("Finished receiving in module %m. Simulation time =%t", $time);

// 	#BL;
//     cycleCounter += 1;		
//     //Measuring throughput: calculate the number of Receives per unit of time  
//     //CycleTime stores the time it takes from the begining to the end of the always block
//     cycleTime = $time - timeOfReceive; // the difference of time between now and the last receive
//     averageThroughput = cycleCounter/$time; 
//     sumOfCycleTimes += cycleTime;
//     averageCycleTime = sumOfCycleTimes / cycleCounter;
//     //$display("Execution cycle= %d, Cycle Time= %d, 
//     //Average CycleTime=%f, Average Throughput=%f", cycleCounter, cycleTime, 
//     //averageCycleTime, averageThroughput);
	
	
//   end

// endmodule

// module router_tb;

// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(32)) intf  [9:0] ();

// data_generator #(.WIDTH(32), .SENDVALUE(32'h5111_1111)) d0 (intf[0]);
// data_generator #(.WIDTH(32), .SENDVALUE(32'h5222_2222)) d1 (intf[1]);
// data_generator #(.WIDTH(32), .SENDVALUE(32'h5333_3333)) d2 (intf[2]);
// data_generator #(.WIDTH(32), .SENDVALUE(32'h5444_4444)) d3 (intf[3]);
// data_generator #(.WIDTH(32), .SENDVALUE(32'h5555_5555)) d4 (intf[4]);

// router r (intf[0], intf[1], intf[2], intf[3], intf[4], intf[5], intf[6], intf[7], intf[8], intf[9]);

// data_bucket db0 (intf[5]);
// data_bucket db1 (intf[6]);
// data_bucket db2 (intf[7]);
// data_bucket db3 (intf[8]);
// data_bucket db4 (intf[9]);

// endmodule

// module router_4x4_tb;
// parameter FL = 2;
// parameter BL = 2;
// parameter WIDTH = 32;
// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(WIDTH)) intf  [0:31] ();

// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hF000_0000)) d0 (intf[0]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hF111_1111)) d1 (intf[1]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hF222_2222)) d2 (intf[2]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hF333_3333)) d3 (intf[3]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hF444_4444)) d4 (intf[4]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hF555_5555)) d5 (intf[5]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hF666_6666)) d6 (intf[6]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hF777_7777)) d7 (intf[7]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hF888_8888)) d8 (intf[8]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hF999_9999)) d9 (intf[9]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hFAAA_AAAA)) d10 (intf[10]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hFBBB_BBBB)) d11 (intf[11]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hFCCC_CCCC)) d12 (intf[12]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hFDDD_DDDD)) d13 (intf[13]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hFEEE_EEEE)) d14 (intf[14]);
// data_generator #(.WIDTH(WIDTH), .SENDVALUE(32'hFFFF_FFFF)) d15 (intf[15]);

// router_4x4 #(.FL(FL), .BL(BL), .WIDTH(WIDTH)) r0 (intf[0:15], intf[16:31]);

// data_bucket db0 (intf[16]);
// data_bucket db1 (intf[17]);
// data_bucket db2 (intf[18]);
// data_bucket db3 (intf[19]);
// data_bucket db4 (intf[20]);
// data_bucket db5 (intf[21]);
// data_bucket db6 (intf[22]);
// data_bucket db7 (intf[23]);
// data_bucket db8 (intf[24]);
// data_bucket db9 (intf[25]);
// data_bucket db10 (intf[26]);
// data_bucket db11 (intf[27]);
// data_bucket db12 (intf[28]);
// data_bucket db13 (intf[29]);
// data_bucket db14 (intf[30]);
// data_bucket db15 (intf[31]);

// endmodule


                                                                                                