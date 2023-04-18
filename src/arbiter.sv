
`timescale 1ns/1fs
import SystemVerilogCSP::*;
`include "./src/data_bucket.sv"
`include "./src/data_generator.sv"

module arbiter_2_ip_2_op (interface A,B,W,O);
	parameter FL=2;
	parameter BL=2;
	parameter WIDTH=32;
	parameter ARBITER_INDEX = 1;
	logic channel_winner;
	logic [WIDTH-1:0]a = 0,b = 0;
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
	logic [WIDTH-1:0]a=0,b=0;
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

module merge_arbiter(interface left0, left1, right, select);
	parameter FL=2;
	parameter BL=2;
	parameter WIDTH=32;
	logic [WIDTH-1:0]input0 = 0, input1 = 0;
	logic [WIDTH-1:0]merge_select = 0;
	always begin
		select.Receive(merge_select);
		if(merge_select==0) begin
			left0.Receive(input0);
			#FL;
			right.Send(input0);
		end
		else if(merge_select==1) begin
			left1.Receive(input1);
			#FL;
			right.Send(input1);
		end
		#BL;
	end
endmodule

module arbiter_4_ip_1_op(interface in_0, in_1, in_2, in_3, out);
	parameter FL = 2;
	parameter BL = 2;
	parameter WIDTH = 32;

	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(WIDTH)) intf  [4:0] ();

	arbiter_2_ip_2_op #(.FL(FL),.BL(BL),.WIDTH(WIDTH), .ARBITER_INDEX(0)) a1 (in_0, in_1, intf[0], intf[1]);
	arbiter_2_ip_2_op #(.FL(FL),.WIDTH(WIDTH), .ARBITER_INDEX(1)) a2 (in_2, in_3, intf[2], intf[3]);
	arbiter_2_ip_1_op #(.FL(FL),.BL(BL),.WIDTH(1)) a3 (intf[1], intf[3], intf[4]);
	merge_arbiter #(.FL(FL),.BL(FL),.WIDTH(WIDTH)) m1 (intf[0], intf[2], out, intf[4]);
endmodule

///////////////////////////////////////////////////TestBench////////////////////////////////////////

module arbiter_tb;

	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(32)) intf  [7:0] ();

	data_generator #(.WIDTH(32)) d0 (intf[0]);
	data_generator #(.WIDTH(32)) d1 (intf[1]);
	data_generator #(.WIDTH(32)) d2 (intf[2]);
	data_generator #(.WIDTH(32)) d3 (intf[3]);

	// arbiter_2_ip_1_op arb0(intf[2], intf[3], intf[5]);
	// data_bucket #(.WIDTH(1)) db1 (intf[5]);

	// arbiter_2_ip_2_op arb2(intf[0], intf[1], intf[6], intf[7]);
	// data_bucket #(.WIDTH(32)) db2 (intf[6]);
	// data_bucket #(.WIDTH(1)) db3 (intf[7]);

	arbiter_4_ip_1_op arb1 (intf[0], intf[1], intf[2], intf[3], intf[4]);
	data_bucket db0 (intf[4]);

endmodule
/////////////////////////////////////////////////////////////////////////////////////////////////////