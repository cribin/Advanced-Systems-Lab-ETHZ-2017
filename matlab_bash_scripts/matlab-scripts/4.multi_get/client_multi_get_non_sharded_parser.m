clear();
%Parse client files for the multi-get non sharded experiments.!!Needs to be called before the sharded client parser file

fileprefix = 'Multi_Get/NonSharded/ClientLog/client_multi_get_non_shard_';
filesuffix = '.txt';

numOfVCs = 2;%[8,16,24,32];
workerThread = 64;
wString = num2str(workerThread);
clientMachines = [0,1,2];
rounds = 1:3;
runTime = 60;
maxKeys = [3,6,9];
percentiles = [25,50,75,90,99];

roundSize = size(rounds);
VCSize = size(numOfVCs);
maxKeysSize = size(maxKeys);
clientsSize = size(clientMachines);
numPercentiles = size(percentiles,2);

tTPS_non_shard = zeros(maxKeysSize(2), VCSize(2));
tTPS_non_shard_std = zeros(maxKeysSize(2), VCSize(2));
tResp_non_shard = zeros(maxKeysSize(2), VCSize(2));
tResp_non_shard_std = zeros(maxKeysSize(2), VCSize(2));

tRespPercentiles_non_shard = zeros(maxKeysSize(2), numPercentiles);
completeRespData_6_keys_non_shard = 0;

counterOffSet = 4;
realRunTime =runTime - 2* counterOffSet;
endOffSet = runTime - counterOffSet;

keyCounter = 1;

for maxKey = maxKeys
    
    tCounter = 1;

    maxKeyString = num2str(maxKey);
    completeRespData = 0;
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
                    inlierIndex = logical(1 - outlierIndex);
                    mResp = mResp(inlierIndex);
                    mTPS = mTPS(inlierIndex);
                    
                    dataSize = size(mResp,1);
                    
                    completeRespData = [mResp; completeRespData];
                     
                    mwTPS(mw) = mean(mTPS);
                    mwTPS_std(mw) = sqrt(sum((mTPS - mwTPS(mw)).^2)/(dataSize-1));
                    
                    mwResp(mw) = mean(mResp);
                    mwResp_std(mw) = sqrt(sum((mResp - mwResp(mw)).^2)/(dataSize-1));
             
%                     threshold = 30;
%                     mwResp(mw) = mean(mResp);
%                     testResp_non_shard = mResp - mwResp(mw);
%                     outlierResp = abs(testResp_non_shard) >   threshold;
%                     mwResp(mw) = mean(mResp(abs(testResp_non_shard) <=   threshold));
%                     mwTPS(mw) = mean(mTPS(abs(testResp_non_shard) <=   threshold)); 
%                     testTPS_non_shard = mTPS(abs(testResp_non_shard) <=   threshold) - mwTPS(mw);
%                     mwTPS_std(mw) = sqrt(sum((testTPS_non_shard).^2)/(size(testTPS_non_shard,1)-1));
%                     testResp_non_shard = mResp(abs(testResp_non_shard) <=   threshold) - mwResp(mw);
%                 
%                     outliersResp = sum(outlierResp);
%                     testResp_non_shardSize = size(testResp_non_shard,1);
%                     if testResp_non_shardSize > 1
%                         mwResp_std(mw) = sqrt(sum((testResp_non_shard).^2)/(testResp_non_shardSize-1));
%                     else
%                         mwResp_std(mw) = sqrt(sum((testResp_non_shard).^2));
%                     end
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
        tTPS_non_shard(keyCounter, tCounter) = mean(rTPS);
        tTPS_non_shard_std(keyCounter, tCounter) = sqrt(mean(rTPS_std.^2));
        %tStdThrp(tInd) = std(rTPS);
        tResp_non_shard(keyCounter, tCounter) = mean(rResp);
        tResp_non_shard_std(keyCounter, tCounter) = sqrt(mean(rResp_std.^2));
        
        tCounter = tCounter + 1;
        
    end
    
     %compute percentiles
    completeRespData = sort(completeRespData);
    dataSize = size(completeRespData,1);
    percentileCounter = 1;
    for percentile = percentiles
        percentileIndex = (dataSize*percentile)/100 + 0.5;
        if(floor(percentileIndex) == percentileIndex)
            tRespPercentiles_non_shard(keyCounter, percentileCounter) = completeRespData(percentileIndex);
        else
            %interpolate percentile the index is not an integer
            integ=floor(percentileIndex);
            fract=percentileIndex-integ;
            tRespPercentiles_non_shard(keyCounter, percentileCounter) = (1-fract)*completeRespData(integ) + fract*completeRespData(integ+1);
        end
        percentileCounter = percentileCounter + 1;
    end
    if(maxKey == 6)
        completeRespData_6_keys_non_shard = completeRespData;
    end
    keyCounter = keyCounter + 1;
    
end

