clear();
%Parse client files with 1 client connecting to two mws, which connects to one server

fileprefix = 'Two_MW_LogFiles/ClientLogs/client_two_mw_write_';
filesuffix = '.txt';

numOfVCs = [8,16,20,24,32];
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
realRunTime =runTime - 2* counterOffSet;
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
            rString = num2str(r);
            
            %%%%%%%%
            mwTPS = zeros(2,1);
            mwTPS_std = zeros(2,1);
            mwResp = zeros(2,1);
            mwResp_std = zeros(2,1);
            for mw = 1:2
                
                mTPS = zeros(realRunTime,1);   
                mResp = zeros(realRunTime,1);
                
                mwString = num2str(mw);
                filename = strcat(fileprefix, tString,'-', rString,'-', wString,'-',mwString, filesuffix); 
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
                
             
                %compute average response time
             
                threshold = 50;
                mwResp(mw) = mean(mResp);
                testResp = mResp - mwResp(mw);
                outlierResp = abs(testResp) >   threshold;
                mwResp(mw) = mean(mResp(abs(testResp) <=   threshold));
                mwTPS(mw) = mean(mTPS(abs(testResp) <=   threshold)); 
                testTPS = mTPS(abs(testResp) <=   threshold) - mwTPS(mw);
                mwTPS_std(mw) = sqrt(sum((testTPS).^2)/(size(testTPS,1)-1));
                testResp = mResp(abs(testResp) <=   threshold) - mwResp(mw);
                
                outliersResp = sum(outlierResp);
                testRespSize = size(testResp,1);
                if testRespSize > 1
                    mwResp_std(mw) = sqrt(sum((testResp).^2)/(testRespSize-1));
                else
                    mwResp_std(mw) = sqrt(sum((testResp).^2));
                end
            end
            %%%%%%%%%%%%
            %compute aggregated data 
            rTPS(r) = sum(mwTPS);
            rTPS_std(r) = sqrt(mean(mwTPS_std.^2));
            %compute average response time
            rResp(r) = mean(mwResp);
            rResp_std(r) = sqrt(mean(mwResp_std.^2));
           
        end
        
        %compute averages of each round 
         %compute averages of each round 
        tTPS(wCounter, tCounter) = mean(rTPS);
        tTPS_std(wCounter, tCounter) = sqrt(mean(rTPS_std.^2));
        %tStdThrp(tInd) = std(rTPS);
        tResp(wCounter, tCounter) = mean(rResp);
        tResp_std(wCounter, tCounter) = sqrt(mean(rResp_std.^2));
        
        tCounter = tCounter + 1;
        
    end
    
    wCounter = wCounter + 1;
    
end
