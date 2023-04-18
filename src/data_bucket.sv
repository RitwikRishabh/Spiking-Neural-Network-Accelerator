//Sample data_bucket module
module data_bucket (interface r);
    parameter WIDTH = 8;
    parameter BL = 0; //ideal environment    backward delay
    logic [WIDTH-1:0] ReceiveValue = 0;
    
    //Variables added for performance measurements
    real cycleCounter=0, //# of cycles = Total number of times a value is received
         timeOfReceive=0, //Simulation time of the latest Receive 
         cycleTime=0; // time difference between the last two receives
    real averageThroughput=0, averageCycleTime=0, sumOfCycleTimes=0;
    always
    begin
      
      //add a display here to see when this module starts its main loop
    $display("*** %m %d",$time);
  
      timeOfReceive = $time;
      
      //Communication action Receive is about to start
      $display("Start receiving in module %m. Simulation time =%t", $time);
      r.Receive(ReceiveValue);
  
      $display("Received Data: %d ------ %b", ReceiveValue, ReceiveValue);
      
      //Communication action Receive is finished
    $display("Finished receiving in module %m. Simulation time =%t", $time);
  
      #BL;
      cycleCounter += 1;		
      //Measuring throughput: calculate the number of Receives per unit of time  
      //CycleTime stores the time it takes from the begining to the end of the always block
      cycleTime = $time - timeOfReceive; // the difference of time between now and the last receive
      averageThroughput = cycleCounter/$time; 
      sumOfCycleTimes += cycleTime;
      averageCycleTime = sumOfCycleTimes / cycleCounter;
      $display("Execution cycle= %d, Cycle Time= %d, Average CycleTime=%f, Average Throughput=%f", cycleCounter, cycleTime, averageCycleTime, averageThroughput);
    end
  endmodule