clear();
%Parse client files with 1 client connecting to one mw, which connects to one server

fileprefix = 'One_MW_LogFiles/ClientLogs/client_one_mw_read_';
filesuffix = '.txt';

numOfVCs = [4,8,16,20,24,32];
workerThreads = [8,16,32,64];
rounds = 1:3;
runTime = 60;

roundSize = size(rounds);
VCSize = size(numOfVCs);
workersSize = size(workerThreads);

tTPS = zeros(workersSize(2), VCSize(2));
tTPS_std = zeros(workersSize(2), VCSize(2));
tResp = zeros(workersSize(2), VCSize(2));
tResp_std = zeros(workersSize(2), VCSize(2));

counterOffSet = 4;
realRunTime=runTime - 2* counterOffSet;
endOffSet = runTime - counterOffSet;

wCounter = 1;

for w = workerThreads
    
    tCounter = 1;

    wString = num2str(w);

    for t = numOfVCs
        
        rTPS = zeros(roundSize);
        rTPS_std = zeros(roundSize);
        rResp = zeros(roundSize);
        rResp_std = zeros(roundSize);
        
        tString = num2str(t);
        
        for r = rounds
            mTPS = zeros(realRunTime,1);   
            mResp = zeros(realRunTime,1);
              
            rString = num2str(r);
            
            filename = strcat(fileprefix, tString,'-', rString,'-', wString, filesuffix); 
            fileId = fopen(filename);

            %skip first two lines of the file
            fgets(fileId);
            fgets(fileId);
            
            counter = 0;
            while(counter < runTime)
                currline = fgets(fileId);
                counter = counter + 1;
                if(counter > counterOffSet && counter < endOffSet)
                    data = strsplit(currline,',');
                    tps = strsplit(char(data(1,3)));
                    tps = str2double(tps(1,2));
                    mTPS(counter - counterOffSet) = tps;
                    resp = strsplit(char(data(1,5)));
                    resp = str2double(resp(1,2));
                    mResp(counter - counterOffSet) = resp;
                end
                
            end
           
            fclose(fileId);
%             threshold = 10;
%             rResp(r) = mean(mResp);
%             testResp = mResp - rResp(r);
%             outlierResp = abs(testResp) >   threshold;
%             rResp(r) = mean(mResp(abs(testResp) <=   threshold));
%             rTPS(r)  = mean(mTPS(abs(testResp) <=   threshold)); 
%             testTPS = mTPS(abs(testResp) <=   threshold) - rTPS(r);
%             rTPS_std(r) = sqrt(mean(testTPS.^2));
%             testResp = mResp(abs(testResp) <=   threshold) - rResp(r);
%         
%             outliersResp = sum(outlierResp);
%             testRespSize = size(testResp,1);
%             if testRespSize > 1
%                 rResp_std(r) = sqrt(sum((testResp).^2)/(testRespSize-1));
%             else
%                 rResp_std(r) = sqrt(sum((testResp).^2));
%             end
            
            %compute aggregated throughput 
            rTPS(r) = mean(mTPS);
            rTPS_std(r) = sqrt(sum((mTPS - rTPS(r)).^2)/(realRunTime-1));
            %compute average response time
            rResp(r) = mean(mResp);
            rResp_std(r) = sqrt(sum((mResp -  rResp(r)).^2)/(realRunTime-1));
            
        end
        
        %compute averages of each round 
        tTPS(wCounter, tCounter) = mean(rTPS);
        tTPS_std(wCounter, tCounter) = sqrt(mean(rTPS_std.^2));
        %tStdThrp(tInd) = std(rTPS);
        tResp(wCounter, tCounter) = mean(rResp);
        tResp_std(wCounter, tCounter) = sqrt(mean(rResp_std.^2));
        %tStd(tCounter) = sqrt((sum(rStd.^2))/5);
        
        tCounter = tCounter + 1;
        
    end
    
    wCounter = wCounter + 1;
    
end



