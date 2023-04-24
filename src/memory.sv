`timescale 1ns/1ps
import SystemVerilogCSP::*;

module memory_interface(interface toMemRead, toMemWrite, toMemT, toMemX, toMemY, toMemSendData, fromMemGetData, toNOC, fromNOC); 

    parameter MEM_LATENCY = 15;
    parameter timesteps = 10;
    parameter WIDTH = 8;
    parameter WIDTH_NOC = 64;
    parameter IFMAP_WIDTH = 25;
    parameter FILTER_WIDTH = 40;

    localparam addrPE1 = 4'b0000, addrPE2 = 4'b0001, addrPE3 = 4'b0010, addrPE4 = 4'b0011, addrPE5 = 4'b1001;
    localparam interfaceAddr=4'b0000, addrAdd1 = 4'b0100, addrAdd2 = 4'b0111, addrAdd3 = 4'b1010, addrAdd4 = 4'b1000, addrAdd5 = 4'b1101;

    localparam inputType = 2'b00, kernelType = 2'b01, memType = 2'b10, outputType = 2'b11;
    localparam zerosLong = 29'b0, zerosShort = 14'b0, zerosLonger = 46'b0;
    localparam DONE=4'b1111;

    int flitsX = 5;
    int flitsY = 5;

    int ofMapx = 3;
    int ofMapy = 3;
    int ifMapx = 5;
    int ifMapy = 5;

    int readFilts = 2;
    int readIFmaps = 1;
    int readMembranePot = 0;
    int writeOFmaps = 1;
    int writeMembranePot = 0;

    int flag = 0;
    logic [WIDTH-1:0] byteVal = 0;;
    logic [WIDTH-1:0] byte1, byte2, byte3, byte4, byte5;
    logic [WIDTH_NOC-1:0] nocVal;
    logic [IFMAP_WIDTH-1:0] ifMapValue;
    logic [FILTER_WIDTH-1:0] filterValue;
    logic spikeValue = 0;;
    
    // Weight stationary design
    initial begin
        // Get filters
        for (int i = 0; i < flitsX; i++) begin
            for (int j = 0; j < flitsY; j++) begin
                toMemRead.Send(readFilts);
                toMemX.Send(i);
                toMemY.Send(j);
                fromMemGetData.Receive(byteVal);
                case(j)
                    0 : byte1 = byteVal;
                    1 : byte2 = byteVal;
                    2 : byte3 = byteVal;
                    3 : byte4 = byteVal;
                    4 : byte5 = byteVal;
                endcase
            end
            #MEM_LATENCY;
            filterValue={byte5, byte4, byte3, byte2, byte1};
            case(i)
                0: nocVal = {interfaceAddr, addrPE1, kernelType, zerosShort, filterValue};
                1: nocVal = {interfaceAddr, addrPE2, kernelType, zerosShort, filterValue};
                2: nocVal = {interfaceAddr, addrPE3, kernelType, zerosShort, filterValue};
                3: nocVal = {interfaceAddr, addrPE4, kernelType, zerosShort, filterValue};
                4: nocVal = {interfaceAddr, addrPE5, kernelType, zerosShort, filterValue};
            endcase
            toNOC.Send(nocVal);
        end

        for (int t = 1; t <= timesteps; t++) begin
            // get the new ifmaps
            for (int i = 0; i < ifMapx-2; i++) begin
                for (int j = 0; j < ifMapy; j++) begin
                    // request the input spikes
                    toMemRead.Send(readIFmaps);
                    toMemX.Send(i);
                    toMemY.Send(j);
                    fromMemGetData.Receive(spikeValue);
                    ifMapValue[j]=spikeValue;
                end
                #MEM_LATENCY;
                case(i)
                    0: nocVal = {interfaceAddr, addrPE1, inputType, zerosLong, ifMapValue};
                    1: nocVal = {interfaceAddr, addrPE2, inputType, zerosLong, ifMapValue};
                    2: nocVal = {interfaceAddr, addrPE3, inputType, zerosLong, ifMapValue};
                    3: nocVal = {interfaceAddr, addrPE4, inputType, zerosLong, ifMapValue};
                    4: nocVal = {interfaceAddr, addrPE5, inputType, zerosLong, ifMapValue};
                endcase
                toNOC.Send(nocVal);
                $display("%m toNOC send is %b in %t", nocVal, $time);
            end
        
            for (int i = 0; i < ofMapx ; i++) begin
                //read old membrane potential
                if(t>=2 & i==0) begin
                    for(int k=0; k< ofMapy; k++) begin
                        toMemRead.Send(readMembranePot);
                        toMemX.Send(i);
                        toMemY.Send(k);
                        fromMemGetData.Receive(byteVal);
                        case(k)
                            0: nocVal={interfaceAddr, addrAdd1, memType, zerosLonger, byteVal};
                            1: nocVal={interfaceAddr, addrAdd2, memType, zerosLonger, byteVal};
                            2: nocVal={interfaceAddr, addrAdd3, memType, zerosLonger, byteVal};
                            3: nocVal={interfaceAddr, addrAdd4, memType, zerosLonger, byteVal};
                            4: nocVal={interfaceAddr, addrAdd5, memType, zerosLonger, byteVal};
                        endcase
                        toNOC.Send(nocVal);
                    end
                end

                for (int j = 0; j < ofMapy; j++) begin	
                    //send membrane potential and output spikes
                    fromNOC.Receive(nocVal);						
                    if((nocVal[WIDTH_NOC-9:WIDTH_NOC-10]==outputType) & (nocVal[WIDTH_NOC-31:0]==DONE)) begin	
                        flag += 1;
                        if((t>=2) & (i>=1) & (flag<5)) begin
                            for(int k=0; k < ofMapy; k++) begin
                                toMemRead.Send(readMembranePot);
                                toMemX.Send(i);
                                toMemY.Send(k);
                                fromMemGetData.Receive(byteVal);
                                case(k)
                                    0: nocVal={interfaceAddr, addrAdd1, memType, zerosLonger, byteVal};
                                    1: nocVal={interfaceAddr, addrAdd2, memType, zerosLonger, byteVal};
                                    2: nocVal={interfaceAddr, addrAdd3, memType, zerosLonger, byteVal};
                                    3: nocVal={interfaceAddr, addrAdd4, memType, zerosLonger, byteVal};
                                    4: nocVal={interfaceAddr, addrAdd5, memType, zerosLonger, byteVal};
                                endcase
                                toNOC.Send(nocVal);
                            end
                        end
                        if(flag<=2) begin
                            for(int k=0; k < ifMapy; k++) begin
                                toMemRead.Send(readIFmaps);
                                toMemX.Send(flag+2);
                                toMemY.Send(k);
                                fromMemGetData.Receive(spikeValue);
                                ifMapValue[k]=spikeValue;
                            end
                            #MEM_LATENCY;
                            nocVal={interfaceAddr, addrPE3, inputType, zerosLong, ifMapValue};
                            toNOC.Send(nocVal);
                        end
                        if(flag==5) begin
                            flag = 0;
                        end
                        else begin
                            j = j - 1;
                        end
                    end
                    else begin
                        if(nocVal[WIDTH_NOC-9:WIDTH_NOC-10]==memType) begin
                            toMemWrite.Send(writeMembranePot);
                            toMemX.Send(i);
                            toMemY.Send(j);
                            toMemSendData.Send(nocVal[WIDTH_NOC-27:0]);
                            if(i==2 & j==2 & flag==2) begin
                                j = j - 1;
                            end
                        end
                        else if(nocVal[WIDTH_NOC-9:WIDTH_NOC-10]==outputType) begin
                            toMemWrite.Send(writeOFmaps);
                            toMemX.Send(nocVal[WIDTH_NOC-31:WIDTH_NOC-32]);
                            toMemY.Send(nocVal[WIDTH_NOC-33:0]);
                            j = j - 1;
                        end
                    end
                end
            end            
            toMemT.Send(t);
        end
        #MEM_LATENCY;
        $stop;
    end

    always begin
        #200;
        $display("%m working still...");
    end
endmodule

module memory(interface read, write, T, x, y, data_out, data_in); 
    parameter timesteps = 10;
    
    parameter FILTER_ROWS = 5; 
    parameter FILTER_COLS = 5; 
    parameter FILTER_WIDTH = 8; 
    logic [FILTER_WIDTH-1:0] membranePotValue = 0;
    logic spikeValue = 0;
    logic [FILTER_WIDTH-1:0] filterMem[FILTER_ROWS-1:0][FILTER_COLS-1:0];
    
    parameter IFMAP_ROWS = 25; 
    parameter IFMAP_COLS = 25; 
    logic ifMapMem[timesteps-1:0][IFMAP_ROWS-1:0][IFMAP_COLS-1:0];
    
    parameter OFMAP_ROWS = 21; 
    parameter OFMAP_COLS = 21; 
    logic ofMapMem[timesteps-1:0][OFMAP_ROWS-1:0][OFMAP_COLS-1:0];
    logic ofMapMemGolden[OFMAP_ROWS-1:0][OFMAP_COLS-1:0];
    
    parameter V_POT_WIDTH = 8;
    logic [V_POT_WIDTH-1:0] V_pot_mem[OFMAP_ROWS-1:0][OFMAP_COLS-1:0];
  
    integer index, fi, fj, ifi,ifj, ift,ofi,ofj;
    int rtype,wtype, row, col,t,t_dummy;
  
    logic [FILTER_WIDTH-1:0] goldenMemPre [0:OFMAP_ROWS*OFMAP_COLS-1];	
    logic [FILTER_WIDTH-1:0] filterMemPre [0:FILTER_ROWS*FILTER_COLS-1];
    logic ifmapMemPre [0:IFMAP_COLS*IFMAP_ROWS*timesteps-1];
      
  
    initial begin 
  
        //Load golden mem 			  
        $readmemb("sparse_output_bin.mem", goldenMemPre);	 	  
        for (ofi = 0; ofi < OFMAP_ROWS; ofi++) begin
            for (ofj = 0; ofj < OFMAP_COLS; ofj++) begin	
                ofMapMemGolden[ofi][ofj] = goldenMemPre[OFMAP_COLS * ofi + ofj];				
          end
        end

        //Load filters 	
        $readmemh("sparse_kernel_hex.mem", filterMemPre);
        for (fi = 0; fi < FILTER_ROWS; fi++) begin
          for (fj = 0; fj < FILTER_COLS; fj++) begin
              filterMem[fi][fj] = filterMemPre[FILTER_COLS * fi + fj];				
          end
        end

        // Load spikes 
        $readmemb("sparse_ifmaps_bin.mem", ifmapMemPre);
        for (ift = 0; ift < timesteps; ++ift) begin 
            for (ifi = 0; ifi < IFMAP_ROWS; ++ifi) begin 
                for (ifj = 0; ifj < IFMAP_COLS; ++ifj) begin
                    ifMapMem[ift][ifi][ifj] = ifmapMemPre[(IFMAP_ROWS*IFMAP_COLS)*ift + (IFMAP_COLS*ifi) + ifj];
                end
            end	  
        end
  
        t = 0;
        #1;
        $display("%m has loaded all filters, ifmaps and golden output");	
        for (int i=0; i < timesteps; i++) begin
            for (int j=0; j < OFMAP_ROWS; j++) begin
                for (int k=0; k < OFMAP_COLS; k++) begin
                    ofMapMem[i][j][k] = 1'b0;
                end	
            end
        end
  
        while (t < timesteps) begin
            fork
                begin
                    // Request to read value
                    read.Receive(rtype);
                    fork
                        x.Receive(row);
                        y.Receive(col);
                    join
                    if (rtype == 0) begin
                        if (row >= OFMAP_ROWS | col >= OFMAP_COLS) begin
                            $display("%m reading beyond edge of membrane potential memory");
                        end
                        data_out.Send(V_pot_mem[row][col]);
                    end
                    else if (rtype == 1) begin
                        if (row >= IFMAP_ROWS | col >= IFMAP_COLS) begin
                            $display("%m reading beyond the edge of input spike array");
                        end
                            data_out.Send(ifMapMem[t][row][col]);	
                    end
                    else if (rtype == 2) begin
                        if (row >= FILTER_ROWS | col >= FILTER_COLS) begin
                            $display("reading beyond the edge of filter array");
                        end
                        data_out.Send(filterMem[row][col]);					
                    end
                    else begin
                        $display("%m request to read from an unknown memory");
                    end
                end
                
                begin
                    // request to write value
                    write.Receive(wtype);	
                    fork
                        x.Receive(row);
                        y.Receive(col);
                    join
                    if (wtype == 0) begin
                        if (row >= OFMAP_ROWS | col >= OFMAP_COLS) begin
                            $display("%m writing beyond the edge of memV array");
                        end
                        data_in.Receive(membranePotValue);
                        V_pot_mem[row][col] = membranePotValue;
                    end
                    else if (wtype == 1) begin
                        if (row >= OFMAP_ROWS | col >= OFMAP_COLS) begin
                            $display("%m writing beyond the edge of output spike array");
                        end				
                        ofMapMem[t][row][col] = 1;
                    end
                    else begin
                        $display("%m request to write from an unknown memory");
                    end
                end
                
                begin
                    T.Receive(t);//_dummy);
                end
            join_any
        end
        for (integer golden_i = 0; golden_i < OFMAP_ROWS; golden_i++) begin
            for (integer golden_j = 0; golden_j < OFMAP_COLS; golden_j++) begin
                $display("%m Golden[%d][%d} = %b",golden_i,golden_j,ofMapMemGolden[golden_i][golden_j]);
                $display("%m Your mem val = %b", ofMapMem[timesteps-1][golden_i][golden_j]);
            end // golden_i
            end
            
            for (integer golden_i = 0; golden_i < OFMAP_ROWS; golden_i++) begin
            for (integer golden_j = 0; golden_j < OFMAP_COLS; golden_j++) begin
                $display("%m Your 1st mem val = %b", ofMapMem[0][golden_i][golden_j]);
            end // golden_i
            end
            
            for (integer golden_i = 0; golden_i < OFMAP_ROWS; golden_i++) begin
            for (integer golden_j = 0; golden_j < OFMAP_COLS; golden_j++) begin
                $display("%m Your 2nd mem val = %b", ofMapMem[1][golden_i][golden_j]);
            end // golden_i
            end
            
            for (integer golden_i = 0; golden_i < OFMAP_ROWS; golden_i++) begin
            for (integer golden_j = 0; golden_j < OFMAP_COLS; golden_j++) begin
                $display("%m Your 3rd mem val = %b", ofMapMem[2][golden_i][golden_j]);
            end // golden_i
            end
            
            for (integer golden_i = 0; golden_i < OFMAP_ROWS; golden_i++) begin
            for (integer golden_j = 0; golden_j < OFMAP_COLS; golden_j++) begin
                $display("%m Your 4th mem val = %b", ofMapMem[3][golden_i][golden_j]);
            end // golden_i
            end
            
            for (integer golden_i = 0; golden_i < OFMAP_ROWS; golden_i++) begin
            for (integer golden_j = 0; golden_j < OFMAP_COLS; golden_j++) begin
                $display("%m Your 5th mem val = %b", ofMapMem[4][golden_i][golden_j]);
            end // golden_i
            end
            
            for (integer golden_i = 0; golden_i < OFMAP_ROWS; golden_i++) begin
            for (integer golden_j = 0; golden_j < OFMAP_COLS; golden_j++) begin
                $display("%m Your 6th mem val = %b", ofMapMem[5][golden_i][golden_j]);
            end // golden_i
            end
            
            for (integer golden_i = 0; golden_i < OFMAP_ROWS; golden_i++) begin
            for (integer golden_j = 0; golden_j < OFMAP_COLS; golden_j++) begin
                $display("%m Your 7th mem val = %b", ofMapMem[6][golden_i][golden_j]);
            end // golden_i		
            end
            
            for (integer golden_i = 0; golden_i < OFMAP_ROWS; golden_i++) begin
            for (integer golden_j = 0; golden_j < OFMAP_COLS; golden_j++) begin
                $display("%m Your 8th mem val = %b", ofMapMem[7][golden_i][golden_j]);
            end // golden_i	
            end
            
            for (integer golden_i = 0; golden_i < OFMAP_ROWS; golden_i++) begin
            for (integer golden_j = 0; golden_j < OFMAP_COLS; golden_j++) begin
                $display("%m Your 9th mem val = %b", ofMapMem[8][golden_i][golden_j]);
            end // golden_i	
            end
    
        // golden_i
        #5;
        $display("%m User reports completion");
        $stop;
    end
  endmodule