clear();
%Parse mw files with 1 client connecting to one mw, which connects to one server

fileprefix = 'One_MW_LogFiles/MWLogs/one_mw_read_';
filesuffix = '.log';

numOfVCs = [4,8,16,20,24,32];
workerThreads = [8,16,32,64];
rounds = 1:3;
fieldSize = 5;

roundSize = size(rounds);
VCSize = size(numOfVCs);
workersSize = size(workerThreads);

avgTPS = zeros(workersSize(2), VCSize(2));
finalData = zeros(workersSize(2), VCSize(2), fieldSize);
finalDataStd = zeros(workersSize(2), VCSize(2), fieldSize);


startOffset = 3;

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
            
            filename = strcat(fileprefix, tString,'-', rString,'-', wString, filesuffix); 
            fileId = fopen(filename);
            
            %read number of lines to read per worker
            currline = fgets(fileId);
            linesPerWorker = str2double(currline);
            %skip first line, which contains first worker Id number
            fgets(fileId);
          
            endOffset = linesPerWorker - startOffset + 1;
            realWorkerDataSize = linesPerWorker - 2 * startOffset;
            
            workerData = zeros(w, 5);
            workerDataStd = zeros(w, 5);

            for workers = 1:w
    
                workerDataTmp = zeros(realWorkerDataSize, 5);
                counter = 0;
                while(counter < linesPerWorker)

                    currline = fgets(fileId);
                    counter = counter + 1;
      
                    if(counter > startOffset && counter < endOffset)
                        data = textscan(currline,'%f %f %f %f %f','Delimiter',',');
                        workerDataTmp(counter - startOffset,:) = cell2mat(data);
                    end
            
                end
         
                workerData(workers,:) = mean(workerDataTmp,1);
                workerDataStd(workers,:) = sqrt(sum((workerDataTmp - workerData(workers,:)).^2,1)/(realWorkerDataSize -1));   
                %skip worker Id number
                fgets(fileId);
            end
            
            %compute aggregated data 
            avgTPS(wCounter, tCounter) = avgTPS(wCounter, tCounter) + mean(workerData(:,1));
            rData(r,:) = [sum(workerData(:,1)),mean(workerData(:,2:5))] ;
            rDataStd(r,1) = sqrt(sum(workerDataStd(:,1).^2,1));
            rDataStd(r,2:5) = sqrt(mean(workerDataStd(:,2:5).^2,1));
           
        end
        
        avgTPS(wCounter, tCounter) = avgTPS(wCounter, tCounter)/3;
        %compute averages of each round 
        finalData(wCounter, tCounter, :) = mean(rData,1);
        finalDataStd(wCounter, tCounter,1) = sqrt(mean(rDataStd(:,1).^2,1));
        finalDataStd(wCounter, tCounter,2 :5) = sqrt(mean(rDataStd(:,2:5).^2,1));
        
        tCounter = tCounter + 1;
        
    end
    
    wCounter = wCounter + 1;
    
end

