`timescale 1ns/1ps
import SystemVerilogCSP::*;

//TODO : make array of adder address
module memory_interface(interface toMemRead, toMemWrite, toMemT, toMemX, toMemY, fromMemGetData, toNOCfilter, toNOCifmap, fromNOC); 

    parameter MEM_LATENCY = 5;
    parameter WIDTH = 8;
    parameter WIDTH_NOC = 64;
    parameter IFMAP_WIDTH = 25;
    parameter FILTER_WIDTH = 40;

    localparam addrPE1 = 4'b0000, addrPE2 = 4'b0001, addrPE3 = 4'b0010, addrPE4 = 4'b0011, addrPE5 = 4'b1001;
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
                    toMemX.Send(i);
                    toMemY.Send(j);
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
            case(i)
                0: nocVal = {interfaceAddr, addrPE1, kernelType, zerosShort, filterValue};
                1: nocVal = {interfaceAddr, addrPE2, kernelType, zerosShort, filterValue};
                2: nocVal = {interfaceAddr, addrPE3, kernelType, zerosShort, filterValue};
                3: nocVal = {interfaceAddr, addrPE4, kernelType, zerosShort, filterValue};
                4: nocVal = {interfaceAddr, addrPE5, kernelType, zerosShort, filterValue};
            endcase
            toNOCfilter.Send(nocVal);
        end
    end

    always begin
        // get the new ifmaps
        #(MEM_LATENCY * 25);
        toMemT.Send(t); // timestep
        for (int i = 0; i < ifMapx; i++) begin
            for (int j = 0; j < ifMapy; j++) begin
                // request the input spikes
                fork
                    toMemRead.Send(readIFmaps);
                    toMemX.Send(i);
                    toMemY.Send(j);
                join
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
            toNOCifmap.Send(nocVal);
        end
        #MEM_LATENCY;

        fromNOC.Receive(nocVal);
        if (nocVal[WIDTH_NOC-9:WIDTH_NOC-10] == outputType) begin
            fork
                toMemWrite.Send(writeOfmaps);
                toMemX.Send(nocVal[9:5]);
                toMemY.Send(nocVal[4:0]);
                toMemT.Send(t);
            join
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


module memory(interface memRead, memWrite, T, memRow, memCol, data); 
    parameter TIMESTEPS = 10;
    
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
  
    logic [FILTER_WIDTH-1:0] filterMemPre [0:FILTER_ROWS*FILTER_COLS-1];
    logic ifmapMemPre [0:IFMAP_COLS*IFMAP_ROWS*TIMESTEPS-1];

    localparam readFlits = 2;
    localparam readIfmaps = 1;
    localparam writeOfmaps = 0;

    initial begin
        // Load filters
        $readmemh("kernel_hex.mem", filterMemPre);
        for (int fx = 0; fx < FILTER_ROWS; fx++) begin
            for (int fy = 0; fy < FILTER_COLS; fy++) begin
                filterMem[fx][fy] = filterMemPre[FILTER_COLS * fx * fy];
            end
        end
        // Load ifmaps
        $readmemb("ifmaps_bin.mem", ifmapMemPre);
        for (int ift = 0; ift < TIMESTEPS; ift++) begin 
            for (int ifx = 0; ifx < IFMAP_ROWS; ifx++) begin 
                for (int ify = 0; ify < IFMAP_COLS; ify++) begin
                    ifMapMem[ift][ifx][ify] = ifmapMemPre[(IFMAP_ROWS*IFMAP_COLS)*ift + (IFMAP_COLS*ifx) + ify];
                end
            end	  
        end
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
                    memRow.Receive(row);
                    memCol.Receive(col);
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
                    memRow.Receive(row);
                    memCol.Receie(col);
                join
                if (readType == readIfmaps) begin
                    data.Send(ifMapMem[t][row][col]);
                end
            end
        end

        // Get ofmap values
        fork
            memWrite.Receive(writeType);
            memRow.Receive(row);
            memCol.Receive(col);
            T.Receive(t);
            join
            if (writeType == writeOfmaps) begin
                ofMapMem[t][row][col] = 1'b1;
            end
    end
  endmodule