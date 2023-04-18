//Sample data_generator module
module data_generator (interface r);
    parameter WIDTH = 8;
    parameter FL = 2; //ideal environment   forward delay
    logic [WIDTH-1:0] SendValue=0;
    always begin 
      //add a display here to see when this module starts its main loop
      $display("*** %m %d",$time);
      SendValue = $random() % (2**WIDTH);
      
      //SendValue = $random() % (2**WIDTH); // the range of random number is from 0 to 2^WIDTH
      #FL;   // change FL and check the change of performance
       
      //Communication action Send is about to start
      $display("Start sending in module %m. Simulation time =%t", $time);
      r.Send(SendValue);
      $display("SENDING VALUE::::%b", SendValue);
      
      //Communication action Send is finished
      $display("Finished sending in module %m. Simulation time =%t", $time);
    end
  endmodule