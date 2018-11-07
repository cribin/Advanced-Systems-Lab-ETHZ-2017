clear();
%Parse client files for 2k experiment

fileprefix = '2k/read/clientLog/client_2k_';
filesuffix = '.txt';

numServers = [2,3];
numMWs = [1,2];
workerThreads = [8,32];
clientMachines = [0,1,2];
rounds = 1:3;
runTime = 60;

roundSize = size(rounds);
numMWSize = size(numMWs);
numServerSize = size(numServers);
workersSize = size(workerThreads);
clientsSize = size(clientMachines);

tTPS = zeros(numServerSize(2), numMWSize(2), workersSize(2));
tTPS_std = zeros(numServerSize(2), numMWSize(2), workersSize(2));
tResp = zeros(numServerSize(2), numMWSize(2), workersSize(2));
tResp_std = zeros(numServerSize(2), numMWSize(2), workersSize(2));
tTPS_rep = zeros(numServerSize(2), numMWSize(2), workersSize(2),3);
tTPS_std_rep = zeros(numServerSize(2), numMWSize(2), workersSize(2),3);
tResp_rep = zeros(numServerSize(2), numMWSize(2), workersSize(2),3);
tResp_std_rep = zeros(numServerSize(2), numMWSize(2), workersSize(2),3);

counterOffSet = 4;
realRunTime =runTime - 2* counterOffSet;
endOffSet = runTime - counterOffSet;

serverCounter = 1;
for numServer = numServers
    
    mwCounter = 1;
    
    sString = num2str(numServer);

    for numMW = numMWs
        
        workerCounter = 1;
        
        mwString = num2str(numMW);
    
        for worker = workerThreads
        
            rTPS = zeros(roundSize);
            rTPS_std = zeros(roundSize);
            rResp = zeros(roundSize);
            rResp_std = zeros(roundSize);
        
            workerString = num2str(worker);
        
            for r = rounds
                rString = num2str(r);
            
                cTPS = zeros(clientsSize);
                cTPS_std = zeros(clientsSize);
                cResp = zeros(clientsSize);
                cResp_std = zeros(clientsSize);
                for c = clientMachines
                
                    cString = num2str(c);
                    %%%%%%%%
                    mwTPS = zeros(numMW,1);
                    mwTPS_std = zeros(numMW,1);
                    mwResp = zeros(numMW,1);
                    mwResp_std = zeros(numMW,1);
                    for mw = 1:numMW
                
                        mTPS = zeros(realRunTime,1);   
                        mResp = zeros(realRunTime,1);
                
                        mwString = num2str(mw);
                        filename = strcat(fileprefix, sString,'-',mwString,'-',workerString,'-',rString,'-',cString,'-',mwString, filesuffix); 
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
                
                     %compute aggregated data 
                    cTPS(c+1) = sum(mwTPS);
                    cTPS_std(c+1) = sqrt(mean(mwTPS_std.^2));
                    %compute average response time
                    cResp(c+1) = mean(mwResp);
                    cResp_std(c+1) = sqrt(mean(mwResp_std.^2));
            
                end
                %%%%%%%%%%%%
                %compute aggregated data 
                rTPS(r) = sum(cTPS);
                rTPS_std(r) = sqrt(mean(cTPS_std.^2));
                %compute average response time
                rResp(r) = mean(cResp);
                rResp_std(r) = sqrt(mean(cResp_std.^2));
           
            end
        
            %compute averages of each round 
            %compute averages of each round 
            tTPS(serverCounter, mwCounter, workerCounter) = mean(rTPS);
            tTPS_std(serverCounter, mwCounter, workerCounter) = sqrt(mean(rTPS_std.^2));
            %tStdThrp(tInd) = std(rTPS);
            tResp(serverCounter, mwCounter, workerCounter) = mean(rResp);
            tResp_std(serverCounter, mwCounter, workerCounter) = sqrt(mean(rResp_std.^2));
            
            tTPS_rep(serverCounter, mwCounter, workerCounter,:) = rTPS;
            tTPS_std_rep(serverCounter, mwCounter, workerCounter,:) = rTPS_std;
            %tStdThrp(tInd) = std(rTPS);
            tResp_rep(serverCounter, mwCounter, workerCounter,:) = rResp;
            tResp_std_rep(serverCounter, mwCounter, workerCounter,:) = rResp_std;
        
            workerCounter = workerCounter + 1;
        
        end
    
        mwCounter = mwCounter + 1;
    
    end
    
    serverCounter = serverCounter + 1;
end
