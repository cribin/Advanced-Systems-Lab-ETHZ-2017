clear();
%Parse client files for the sharded multi-get experiment.Needs to be called after the non sharded parser file

fileprefix = 'Multi_Get/Sharded/ClientLog/client_multi_get_shard_';
filesuffix = '.txt';

numOfVCs = 2;%[8,16,24,32];
workerThread = 64;
wString = num2str(workerThread);
clientMachines = [0,1,2];
rounds = 1:3;
runTime = 60;
maxKeys = [1,3,6,9];

roundSize = size(rounds);
VCSize = size(numOfVCs);
maxKeysSize = size(maxKeys);
clientsSize = size(clientMachines);

tTPS = zeros(maxKeysSize(2), VCSize(2));
tTPS_std = zeros(maxKeysSize(2), VCSize(2));
tResp = zeros(maxKeysSize(2), VCSize(2));
tResp_std = zeros(maxKeysSize(2), VCSize(2));

counterOffSet = 4;
realRunTime =runTime - 2* counterOffSet;
endOffSet = runTime - counterOffSet;

keyCounter = 1;

for maxKey = maxKeys
    
    tCounter = 1;

    maxKeyString = num2str(maxKey);
    for t = numOfVCs
        
        rTPS = zeros(roundSize);
        rTPS_std = zeros(roundSize);
        rResp = zeros(roundSize);
        rResp_std = zeros(roundSize);
        
        tString = num2str(t);
        
        for r = rounds
            rString = num2str(r);
            
            cTPS = zeros(clientsSize);
            cTPS_std = zeros(clientsSize);
            cResp = zeros(clientsSize);
            cResp_std = zeros(clientsSize);
            for c = clientMachines
                
                cString = num2str(c);
                %%%%%%%%
                mwTPS = zeros(2,1);
                mwTPS_std = zeros(2,1);
                mwResp = zeros(2,1);
                mwResp_std = zeros(2,1);
                for mw = 1:2
                
                    mTPS = zeros(realRunTime,1);   
                    mResp = zeros(realRunTime,1);
                
                    mwString = num2str(mw);
                    filename = strcat(fileprefix, tString,'-',cString,'-',rString,'-', wString,'-',maxKeyString,'-',mwString, filesuffix); 
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
                
                     outlierIndex = isoutlier(mResp);
                     inlierIndex = 1 - outlierIndex;
                     mResp = mResp(inlierIndex);
                     
                     mTPS = mTPS(inlierIndex);
                     
                    
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
        tTPS(keyCounter, tCounter) = mean(rTPS);
        tTPS_std(keyCounter, tCounter) = sqrt(mean(rTPS_std.^2));
        %tStdThrp(tInd) = std(rTPS);
        tResp(keyCounter, tCounter) = mean(rResp);
        tResp_std(keyCounter, tCounter) = sqrt(mean(rResp_std.^2));
        
        tCounter = tCounter + 1;
        
    end
    
    keyCounter = keyCounter + 1;
    
end
