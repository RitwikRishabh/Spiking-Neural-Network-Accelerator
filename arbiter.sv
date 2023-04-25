
`timescale 1ns/1fs
import SystemVerilogCSP::*;

module arbiter_2_ip_2_op (interface A,B,W,O);
parameter FL=2;
parameter BL=2;
parameter WIDTH=32;
parameter ARBITER_INDEX = 1;
logic channel_winner;
logic [WIDTH-1:0]a,b;
always begin
	wait (A.status != idle || B.status != idle);
	if (A.status != idle && B.status != idle) begin
		channel_winner = ($random%2 == 0) ? 0 : 1;
		end
	else if (A.status != idle) begin
		channel_winner = 0;
		end
	else begin
		channel_winner = 1;
		end
	if (channel_winner == 0) begin
		A.Receive(a); 
        #FL;
        O.Send(ARBITER_INDEX);
		W.Send(a);
		#BL;
	end
	else begin
		B.Receive(b); 
        #FL;
        O.Send(ARBITER_INDEX);
		W.Send(b);
		#BL;
	end
end
endmodule

module arbiter_2_ip_1_op (interface A,B,W);
parameter FL=2;
parameter BL=2;
parameter WIDTH=1;
logic channel_winner;
logic [WIDTH-1:0]a,b;
always begin
	wait (A.status != idle || B.status != idle);
	if (A.status != idle && B.status != idle) begin
		channel_winner = ($random%2 == 0) ? 0 : 1;
		end
	else if (A.status != idle) begin
		channel_winner = 0;
		end
	else begin
		channel_winner = 1;
		end
	if (channel_winner == 0) begin
		A.Receive(a); 
        #FL;
		W.Send(a);
		#BL;
	end
	else begin
		B.Receive(b); 
        #FL;
		W.Send(b);
		#BL;
	end
end
endmodule

module merge(interface left0, left1, right, select);
parameter FL=2;
parameter BL=2;
parameter WIDTH=32;
logic [WIDTH-1:0]input0, input1;
logic [WIDTH-1:0]merge_select;
always begin
	select.Receive(merge_select);
	if(merge_select==0) 
	begin
	left0.Receive(input0);
	right.Send(input0);
	end
	else if(merge_select==1) 
	begin
	left1.Receive(input1);
	right.Send(input1);
	end
end
endmodule

module arbiter_4_ip_1_op(interface in_0, in_1, in_2, in_3, out);
parameter FL = 2;
parameter BL = 2;
parameter WIDTH = 32;
logic [WIDTH-1:0]input_0, input_1, input_2, input_3, input_4, arbiter_op;

Channel #(.hsProtocol(P4PhaseBD), .WIDTH(WIDTH)) intf  [4:0] ();

arbiter_2_ip_2_op #(.FL(FL),.BL(BL),.WIDTH(WIDTH), .ARBITER_INDEX(0)) a1 (in_0, in_1, intf[0], intf[1]);
arbiter_2_ip_2_op #(.FL(FL),.WIDTH(WIDTH), .ARBITER_INDEX(1)) a2 (in_2, in_3, intf[2], intf[3]);
arbiter_2_ip_1_op #(.FL(FL),.BL(BL),.WIDTH(1)) a3 (intf[1], intf[3], intf[4]);
merge #(.FL(FL),.BL(FL),.WIDTH(WIDTH)) m1 (intf[0], intf[2], out, intf[4]);

endmodule

///////////////////////////////////////////////////TestBench////////////////////////////////////////

// //Sample data_generator module
// module data_generator (interface r);
//   parameter WIDTH = 8;
//   parameter FL = 2; //ideal environment   forward delay
//   parameter SENDVALUE = 32'h 1111_1111;
//   //logic [WIDTH-1:0] SendValue=0;
//   always
//   begin 
    
// 	//add a display here to see when this module starts its main loop
//     $display("*** %m %d",$time);
	
//     //SendValue = $random() % (2**WIDTH); // the range of random number is from 0 to 2^WIDTH
//     #FL;   // change FL and check the change of performance
     
//     //Communication action Send is about to start
//     $display("Start sending in module %m. Simulation time =%t", $time);
//     r.Send(SENDVALUE);
//     $display("SENDING VALUE::::%b", SENDVALUE);
	
//     //Communication action Send is finished
//     $display("Finished sending in module %m. Simulation time =%t", $time);
	

//   end
// endmodule

// //Sample data_bucket module
// module data_bucket (interface r);
//   parameter WIDTH = 8;
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
//   $display("*** %m %d",$time);

//     timeOfReceive = $time;
	
// 	//Communication action Receive is about to start
// 	$display("Start receiving in module %m. Simulation time =%t", $time);
//     r.Receive(ReceiveValue);

//     $display("Received Data: %d ------ %b", ReceiveValue, ReceiveValue);
	
// 	//Communication action Receive is finished
//   $display("Finished receiving in module %m. Simulation time =%t", $time);

// 	#BL;
//     cycleCounter += 1;		
//     //Measuring throughput: calculate the number of Receives per unit of time  
//     //CycleTime stores the time it takes from the begining to the end of the always block
//     cycleTime = $time - timeOfReceive; // the difference of time between now and the last receive
//     averageThroughput = cycleCounter/$time; 
//     sumOfCycleTimes += cycleTime;
//     averageCycleTime = sumOfCycleTimes / cycleCounter;
//     $display("Execution cycle= %d, Cycle Time= %d, 
//     Average CycleTime=%f, Average Throughput=%f", cycleCounter, cycleTime, 
//     averageCycleTime, averageThroughput);
	
	
//   end

// endmodule


// module arbiter_tb;

// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(32)) intf  [7:0] ();

// data_generator #(.WIDTH(32), .SENDVALUE(32'h1111_1111)) d0 (intf[0]);
// data_generator #(.WIDTH(32), .SENDVALUE(32'h2222_2222)) d1 (intf[1]);
// data_generator #(.WIDTH(32), .SENDVALUE(32'h3333_3333)) d2 (intf[2]);
// data_generator #(.WIDTH(32), .SENDVALUE(32'h4444_4444)) d3 (intf[3]);

// // arbiter_2_ip_1_op arb0(intf[2], intf[3], intf[5]);
// // data_bucket #(.WIDTH(1)) db1 (intf[5]);

// // arbiter_2_ip_2_op arb2(intf[0], intf[1], intf[6], intf[7]);
// // data_bucket #(.WIDTH(32)) db2 (intf[6]);
// // data_bucket #(.WIDTH(1)) db3 (intf[7]);

// arbiter_4_ip_1_op arb1 (intf[0], intf[1], intf[2], intf[3], intf[4]);
// data_bucket db0 (intf[4]);

// endmodule
/////////////////////////////////////////////////////////////////////////////////////////////////////