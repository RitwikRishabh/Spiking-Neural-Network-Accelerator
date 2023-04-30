`timescale 1ns/1ns
import SystemVerilogCSP::*;


module c_element(input A, input B, output logic C);

    logic C1;

    initial begin
        C1 = 0;
    end

    always @(A, B) begin
        C1 = (A & B) | (B & C1) | (A & C1);
    end
    assign C = C1;
endmodule

module latch #(WIDTH = 10)
    (input [WIDTH-1:0] dataIn, input control, output logic [WIDTH-1:0] dataOut);

    always @(control) begin
        if (control) begin
            dataOut <= dataIn;
        end
    end
endmodule

module DETFF #(WIDTH = 10)
    (input [WIDTH-1:0] dataIn, input control, output logic [WIDTH-1:0] dataOut);

    always @(posedge control, negedge control) begin
        dataOut <= dataIn;
    end
endmodule

module buffer #(DELAY = 2)
    (input in, output logic out);

    initial begin 
        out = 0;
    end
    always @(in) begin
        #DELAY out = in;
    end
endmodule

module controller #(FL = 2, BL = 4)
    (input Lreq, output logic Lack, input Rack, output logic Rreq);

    logic cElement;

    initial begin
        // Lack = 0;
        // Rreq = 0;
        // cElement = 0;
    end

    c_element C(.A(Lreq), .B(~Rack), .C(cElement));

    buffer #(.DELAY(BL)) LackBuf(.in(cElement), .out(Lack));
    buffer #(.DELAY(FL)) RReqBuf(.in(cElement), .out(Rreq));
endmodule

module adderConv #(WIDTH = 13, FL = 2, BL = 1)
    (input accumReq, input [WIDTH-1:0] accumData, output logic accumAck, input multReq, input [WIDTH-1:0] multData, output logic multAck, output logic adderReq, output logic [WIDTH-1:0] adderData, input adderAck);

    wire ctrlLreq, ctrlLack, ctrlRreq;
    wire [WIDTH-1:0] regRdata1, regRdata2;

    c_element addC(.A(accumReq), .B(multReq), .C(ctrlLreq));

    always @(ctrlLack) begin
        accumAck = ctrlLack;
        multAck = ctrlLack;
    end
    controller adderCtrlr(.Lreq(ctrlLreq), .Lack(ctrlLack), .Rreq(ctrlRreq), .Rack(adderAck));
    latch #(.WIDTH(26)) adderLatch(.control(ctrlRreq), .dataIn({accumData, multData}), .dataOut({regRdata1, regRdata2}));

    assign adderData = regRdata1 + regRdata2;

    always @(regRdata1,regRdata2) begin
        $display("INPUTS TO ADDER ::::: %d -- %d :::::OUTPUTS:::::%d", regRdata1, regRdata2, adderData);
    end

    buffer #(.DELAY(FL)) bufReq(.in(ctrlRreq), .out(adderReq));
endmodule


// module data_generator (aReq, aAck, a,  reset);
//   input  logic          aAck;
//   output logic [12:0]    a;
//   output logic          reset, aReq;
//   logic        [12:0]    A [0:6] = {13'd14, 13'd5, 13'd118, 13'd51, 13'd27, 13'd8, 13'd77};
//    initial begin
//     reset = 1;
//     #2 reset = 0;
//     #1 reset = 1;
//     aReq = 1;

//     for (int i = 0; i<7; i = i+1) begin
//         aReq = 1;
//         a = A[i];
//         //b = B[i];
//         wait (aAck) begin
//             #1;
//             aReq = 0;
//         end
//         wait (!aAck) #2;
//     end
//   end
// endmodule

// module data_generator (interface r);
//   parameter FL = 0;
//   parameter SENDVALUE = 32'h1111_1111;
//   parameter WIDTH = 32;
//   logic [12:0]SendValue[0:6] = {13'd14, 13'd5, 13'd118, 13'd51, 13'd27, 13'd8, 13'd77};
//   integer i=0;
//   always
//   begin 
    
// 	//add a display here to see when this module starts its main loop
//     //$display("*** %m %d",$time);
	
//     //SendValue = $random() % (2**WIDTH); // the range of random number is from 0 to 2^WIDTH
//     #FL;   // change FL and check the change of performance
     
//     //Communication action Send is about to start
//     //$display("Start sending in module %m. Simulation time =%t", $time);
//     r.Send(SendValue[i]);
//     $display("Sending Value:::%d", SendValue[i]);
//     //$display("SENDING VALUE::::%b", SENDVALUE);
// 	i = i+1;
//     //Communication action Send is finished
//     //$display("Finished sending in module %m. Simulation time =%t", $time);
	

//   end
// endmodule

// // //-------------------data bucket (normal) ----------------------
// module data_bucket #(parameter WIDTH = 13) (interface r);
//   parameter BL = 0; //ideal environment
//   logic [WIDTH-1:0] ReceiveValue = 0;
 
//   always
//   begin
//     r.Receive(ReceiveValue);
//     $display("RECEIVED VALUE IN THE DATA BUCKET:::::::%b -- %b", ReceiveValue, ReceiveValue);
//     #BL;
//   end

// endmodule

//-------------------------shim code-------------------------------
// built from ruiheng's data_bucket module
module buffer_gate_right (output logic bAck, input logic bReq, input   logic [12:0] rcvd_val, interface out_chan);
  parameter WIDTH = 13;
  logic [WIDTH-1:0]  output_value;
 
 
  always begin
    bAck = 0;
    wait (bReq)
    begin: first_phase
        output_value = rcvd_val;
        #0;
        bAck = 1;
		out_chan.Send(output_value);
        $display("SENT VALUE FROM BUFFER::::%b", output_value);

    end: first_phase
   
    wait (!bReq) #0;

  end
endmodule

module buffer_gate_left (interface in_chan, input logic bAck, output logic bReq, output logic [12:0] sent_val);
  parameter WIDTH = 13;
  logic [WIDTH-1:0]  input_value; 
  always begin
    in_chan.Receive(input_value);
    bReq = 1;
    sent_val = input_value;
    wait (bAck) begin
        #0;
        bReq = 0;
    end
    wait (!bAck) #0;
    $display("Received BACK!!");
  end
endmodule

module gate_level_adder(interface multIn, interface accumIn, interface adderOut);
parameter WIDTH = 13;
parameter FL = 2;
parameter BL = 1;

logic accumReq, accumAck;
logic [WIDTH-1:0] accumData;
logic multReq, multAck;
logic [WIDTH-1:0] multData;
logic adderReq, adderAck;
logic [WIDTH-1:0] adderData;

buffer_gate_left #(.WIDTH(WIDTH)) buf_1 (.in_chan(multIn), .bAck(multAck), .bReq(multReq), .sent_val(multData));
buffer_gate_left #(.WIDTH(WIDTH)) buf_2 (.in_chan(accumIn), .bAck(accumAck), .bReq(accumReq), .sent_val(accumData));
adderConv #(.WIDTH(WIDTH), .FL(FL), .BL(BL)) add (.accumReq(accumReq), .accumData(accumData), .accumAck(accumAck), 
                                             .multReq(multReq), .multData(multData), .multAck(multAck), 
                                             .adderReq(adderReq), .adderData(adderData), .adderAck(adderAck));
buffer_gate_right #(.WIDTH(WIDTH)) buf_3 (.bAck(adderAck),.bReq(adderReq),.rcvd_val(adderData),.out_chan(adderOut));
endmodule

// module tb;
// parameter WIDTH = 13;
// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(13)) intf[0:4]();

// data_generator dg0 (.r(intf[0]));
// data_generator dg1 (.r(intf[1]));
// gate_level_adder #(.WIDTH(13)) gla (.mult_in(intf[0]), .accum_in(intf[1]), .adder_out(intf[2]));
// data_bucket db (.r(intf[2]));

// endmodule

                                    
