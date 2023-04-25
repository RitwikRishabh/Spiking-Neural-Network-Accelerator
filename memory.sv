`timescale 1ns/1ps
import SystemVerilogCSP::*;

//TODO : make array of adder address
module memory_interface(interface toMemRead, toMemWrite, toMemT, toMemXfilter, toMemYfilter, toMemXofmap, toMemYofmap, fromMemGetData, toNOCfilter, toNOCifmap, fromNOC); 

    parameter MEM_LATENCY = 5;
    parameter WIDTH = 8;
    parameter WIDTH_NOC = 64;
    parameter IFMAP_WIDTH = 25;
    parameter FILTER_WIDTH = 40;

    localparam addrPE1 = 4'b0001, addrPE2 = 4'b0101, addrPE3 = 4'b0011, addrPE4 = 4'b0111, addrPE5 = 4'b1100;
    localparam interfaceAddr=4'b0000;

    localparam inputType = 2'b00, kernelType = 2'b01, outputType = 2'b11;
    localparam zerosLong = 29'b0, zerosShort = 14'b0;
    localparam DONE=10'b1_1111_1111;

    int filterX = 5;
    int filterY = 5;

    int ifMapx = 25;
    int ifMapy = 25;

    int readFilts = 2;
    int readIFmaps = 1;
    int writeOfmaps = 0;
    int timestepCounter = 0;
    int t = 0;

    logic [WIDTH-1:0] byteVal = 0;
    logic [WIDTH-1:0] byte1, byte2, byte3, byte4, byte5;
    logic [WIDTH_NOC-1:0] nocVal;
    logic [IFMAP_WIDTH-1:0] ifMapValue;
    logic [FILTER_WIDTH-1:0] filterValue;
    logic spikeValue = 0;;
    
    // Weight stationary design
    initial begin
        // Get filters
        for (int i = 0; i < filterX; i++) begin
            for (int j = 0; j < filterY; j++) begin
                fork
                    toMemRead.Send(readFilts);
                    toMemXfilter.Send(i);
                    toMemYfilter.Send(j);
                join
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
            $display("%m Filter Value is %b", filterValue);
            case(i)
                0: nocVal = {addrPE1, interfaceAddr, kernelType, zerosShort, filterValue};
                1: nocVal = {addrPE2, interfaceAddr, kernelType, zerosShort, filterValue};
                2: nocVal = {addrPE3, interfaceAddr, kernelType, zerosShort, filterValue};
                3: nocVal = {addrPE4, interfaceAddr, kernelType, zerosShort, filterValue};
                4: nocVal = {addrPE5, interfaceAddr, kernelType, zerosShort, filterValue};
            endcase
            $display("%m Sending value %b to NOC", nocVal);
            toNOCfilter.Send(nocVal);
        end
    end

    always begin
        // get the new ifmaps
        #(MEM_LATENCY*25);
        toMemT.Send(t); // timestep
        for (int i = 0; i < ifMapx; i++) begin
            for (int j = 0; j < ifMapy; j++) begin
                // request the input spikes
                fork
                    toMemRead.Send(readIFmaps);
                    toMemXfilter.Send(i);
                    toMemYfilter.Send(j);
                join
                fromMemGetData.Receive(spikeValue);
                ifMapValue[j]=spikeValue;
            end
            $display("%m Ifmap value is %d", ifMapValue);
            //#MEM_LATENCY;
            case(i)
                0: nocVal = {addrPE1, interfaceAddr, inputType, zerosLong, ifMapValue};
                1: nocVal = {addrPE2, interfaceAddr, inputType, zerosLong, ifMapValue};
                2: nocVal = {addrPE3, interfaceAddr, inputType, zerosLong, ifMapValue};
                3: nocVal = {addrPE4, interfaceAddr, inputType, zerosLong, ifMapValue};
                4: nocVal = {addrPE5, interfaceAddr, inputType, zerosLong, ifMapValue};
            endcase
            $display("%m Sending value %b to NOC", nocVal);
            toNOCifmap.Send(nocVal);

        end
        #MEM_LATENCY;
    end
    always begin
        fromNOC.Receive(nocVal);
        #MEM_LATENCY;
        $display("%m Received value %b from NOC", nocVal);
        $display("NOCALVAL:::::%b",nocVal);
        if (nocVal[WIDTH_NOC-9:WIDTH_NOC-10] == outputType) begin
            
            // toMemWrite.Send(writeOfmaps);
            toMemXofmap.Send(nocVal[9:5]);
            $display("Sending nocalval");
            toMemYofmap.Send(nocVal[4:0]);
            toMemT.Send(t);
            $display("MEM TO X ROW::::%b",nocVal[9:5]);
            $display("MEM TO Y COLUMN::::%b",nocVal[4:0]);
        end
        if (nocVal[WIDTH_NOC-9:WIDTH_NOC-10] == outputType && nocVal[0+:10] == DONE) begin
            timestepCounter += 1;
        end
        if (timestepCounter == 7) begin
            timestepCounter = 0;
            t += 1;
        end
    end
    
endmodule


module memory(interface memRead, memWrite, T, memRowfilter, memColfilter, memRowofmap, memColofmap, data); 
    parameter TIMESTEPS = 2;
    
    parameter FILTER_ROWS = 5; 
    parameter FILTER_COLS = 5; 
    parameter FILTER_WIDTH = 8; 
    logic [FILTER_WIDTH-1:0] filterMem[FILTER_ROWS-1:0][FILTER_COLS-1:0];
    
    parameter IFMAP_ROWS = 25; 
    parameter IFMAP_COLS = 25; 
    logic ifMapMem[TIMESTEPS-1:0][IFMAP_ROWS-1:0][IFMAP_COLS-1:0];
    
    parameter OFMAP_ROWS = 21; 
    parameter OFMAP_COLS = 21; 
    logic ofMapMem[TIMESTEPS-1:0][OFMAP_ROWS-1:0][OFMAP_COLS-1:0];

    int readType = 0, writeType = 0, row = 0, col = 0, t = 0;
    int i = 0, j = 0, fp = 0, status = 0;
    int fpi = 0, fpi_2=0;
  
    logic [FILTER_WIDTH-1:0] filterMemPre [0:FILTER_ROWS*FILTER_COLS-1];
    logic ifmapMemPre [0:IFMAP_COLS*IFMAP_ROWS*TIMESTEPS-1];

    localparam readFlits = 2;
    localparam readIfmaps = 1;
    localparam writeOfmaps = 0;
    logic [7:0]f_data;
    logic i_data;

    initial begin
        // Load filters
        fpi = $fopen("kernel_decimal.mem","r");
        //$readmemh("kernel_decimal.mem", filterMemPre);
        for (int fx = 0; fx < FILTER_ROWS; fx++) begin
            for (int fy = 0; fy < FILTER_COLS; fy++) begin
                if(!$feof(fpi)) begin
                status = $fscanf(fpi,"%d\n", f_data);
	            $display("filter data read:%d", f_data);
                end
                filterMem[fx][fy] = f_data;
            end
        end
        $fclose(fpi);
        // Load ifmaps
        fpi_2 = $fopen("ifmaps_bin.mem","r");
        status = 0;
        //$readmemb("ifmaps_bin.mem", ifmapMemPre);
        for (int ift = 0; ift < TIMESTEPS; ift++) begin 
            for (int ifx = 0; ifx < IFMAP_ROWS; ifx++) begin 
                for (int ify = 0; ify < IFMAP_COLS; ify++) begin
                    if(!$feof(fpi_2)) begin
                    status = $fscanf(fpi_2,"%b\n", i_data);
	                $display("IF Map data read:%d", i_data);
                    end
                    ifMapMem[ift][ifx][ify] = i_data;
                end
            end	  
        end
        $fclose(fpi_2); 
        // Initialize ofmap
        for (int i=0; i < TIMESTEPS; i++) begin
            for (int j=0; j < OFMAP_ROWS; j++) begin
                for (int k=0; k < OFMAP_COLS; k++) begin
                    ofMapMem[i][j][k] = 1'b0;
                end	
            end
        end
        // Send out filter values
        for (int fx = 0; fx < FILTER_ROWS; fx++) begin
            for (int fy = 0; fy < FILTER_COLS; fy++) begin
                fork
                    memRead.Receive(readType);
                    memRowfilter.Receive(row);
                    memColfilter.Receive(col);
                join
                if (readType == readFlits) begin
                    data.Send(filterMem[row][col]);
                end
            end
        end
    end

    always begin
        // Send out ifmap values
        T.Receive(t);
        for (int ifx = 0; ifx < IFMAP_ROWS; ifx++) begin
            for (int ify = 0; ify < IFMAP_COLS; ify++) begin
                fork
                    memRead.Receive(readType);
                    memRowfilter.Receive(row);
                    memColfilter.Receive(col);
                join
                if (readType == readIfmaps) begin
                    data.Send(ifMapMem[t][row][col]);
                end
            end
        end
    end

        // Get ofmap values
            // memWrite.Receive(writeType);
    always begin
        memRowofmap.Receive(row);
        memColofmap.Receive(col);
        T.Receive(t);
        $display("FINAL STEPP!!");
        // if (writeType == writeOfmaps) begin
        ofMapMem[t][row][col] = 1'b1;
        // end
    end
          
    initial begin
        wait(t==1);
        fp = $fopen("out1_test.txt");
        for(i = 0; i < 21; i+=1) begin
            for(j=0;j<21;j+=1) begin
                $fdisplay(fp,"OF MAP TIMESTEP 1 LOCATION %d, %d, OUTPUT:: %b", i, j, ofMapMem[0][i][j]);
            end
        end
        $fclose(fp);
        $stop;
        wait(t==2);
        fp = $fopen("out2_test.txt");
        for(i = 0; i < 21; i+=1) begin
            for(j=0;j<21;j+=1) begin
                $fdisplay(fp,"OF MAP TIMESTEP 2 LOCATION %d, %d, OUTPUT:: %b", i, j, ofMapMem[1][i][j]);
            end
        end 
        $fclose(fp);
        $stop;
    end


  endmodule


module memoryController(interface toFilter, toIfmap, fromOfmap);
    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(8)) intf [0:7]();

    memory #(.TIMESTEPS(2)) nocMem(.memRead(intf[0]), .memWrite(intf[1]), .T(intf[2]), .memRowfilter(intf[3]), .memColfilter(intf[4]), .memRowofmap(intf[5]), .memColofmap(intf[6]), .data(intf[7]));
    memory_interface #(.MEM_LATENCY(5)) nocMemInterface(.toMemRead(intf[0]), .toMemWrite(intf[1]), .toMemT(intf[2]), .toMemXfilter(intf[3]), .toMemYfilter(intf[4]), .toMemXofmap(intf[5]), .toMemYofmap(intf[6]), .fromMemGetData(intf[7]), .toNOCfilter(toFilter), .toNOCifmap(toIfmap), .fromNOC(fromOfmap));
endmodule