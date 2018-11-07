clear();
%parse mw log data for the throughput writes measurements
fileprefix = 'Thrp_Writes/MWLogs/mw_thrp_write_';
filesuffix = '.log';

numOfVCs = [8,16,20,24,32];
workerThreads = [8,16,32,64];
rounds = 1:3;
fieldSize = 5;

roundSize = size(rounds);
VCSize = size(numOfVCs);
workersSize = size(workerThreads);

finalData = zeros(workersSize(2), VCSize(2), fieldSize);
finalDataStd = zeros(workersSize(2), VCSize(2), fieldSize);


startOffset = 4;

wCounter = 1;
for w = workerThreads
    
    tCounter = 1;

    wString = num2str(w);

    for t = numOfVCs
        
        rData = zeros(roundSize(2), fieldSize);
        rDataStd = zeros(roundSize(2), fieldSize);
        
        tString = num2str(t);
        
        for r = rounds
            rString = num2str(r);
              
            mwData = zeros(2, fieldSize);
            mwDataStd = zeros(2, fieldSize);
            
            for mw = 1:2
                
                mwString = num2str(mw);
                filename = strcat(fileprefix, tString,'-', rString,'-', wString,'-',mwString, filesuffix); 
                fileId = fopen(filename);
                %read number of lines to read per worker
                currline = fgets(fileId);
                linesPerWorker = str2double(currline);
                %skip first line, which contains first worker Id number
                fgets(fileId);
            
                workerData = zeros(w, 5);
                workerDataStd = zeros(w, 5);

                for workers = 1:w
    
                    workerDataTmp = zeros(linesPerWorker + 2, 5);
                  
                    currline = fgets(fileId);
                    counter = 1;
                    sizeTest = size(currline,2);
                    while(size(currline,2)> 10)

                        data = textscan(currline,'%f %f %f %f %f','Delimiter',',');
                        workerDataTmp(counter,:) = cell2mat(data);
                     
                        currline = fgets(fileId);
                        counter = counter + 1;
                    end
                    
                     endOffset = counter - startOffset;
                     
                     %skip worker Id number
                    %fgets(fileId);
                    workerDataTmp = workerDataTmp(startOffset:endOffset,:);
                    realWorkerDataSize = size(workerDataTmp,1);
                    workerData(workers,:) = mean(workerDataTmp,1);
                    workerDataStd(workers,:) = sqrt(sum((workerDataTmp - workerData(workers,:)).^2,1)/(realWorkerDataSize - 1));   
                   
                end
                
                mwData(mw,:) = [sum(workerData(:,1)),mean(workerData(:,2:5))];
                mwDataStd(mw,:) = sqrt(sum(workerDataStd.^2,1)/w);
            
            end
            %compute aggregated data 
            rData(r,:) = [sum(mwData(:,1)),mean(mwData(:,2:5))] ;
            rDataStd(r,:) = sqrt(sum(mwDataStd.^2,1)/2);
           
        end
        
        %compute averages of each round 
        finalData(wCounter, tCounter, :) = mean(rData,1);
        finalDataStd(wCounter, tCounter, :) = sqrt(sum(rDataStd.^2,1)/roundSize(2));
        
        tCounter = tCounter + 1;
        
    end
    
    wCounter = wCounter + 1;
    
end

