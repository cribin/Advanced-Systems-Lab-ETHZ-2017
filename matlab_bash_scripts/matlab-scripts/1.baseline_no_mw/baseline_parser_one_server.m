clear();
%Parse baseline files with 3 clients connecting to 1 memcached instance

fileprefix = 'LogData/one_server/baseline_write_';
filesuffix = '.txt';

numOfVCs = [1,8,16,20,24,32];
clientMachines = 0:2;
rounds = 1:3;
runTime = 70;

roundSize = size(rounds);
VCSize = size(numOfVCs);
machineSize = size(clientMachines);

tTPS = zeros(VCSize);
tTPS_std = zeros(VCSize);
tResp = zeros(VCSize);
tResp_std = zeros(VCSize);

counterOffSet = 4;
realRunTime=60;

tCounter = 1;

for t = numOfVCs
    
    rTPS = zeros(roundSize);
    rTPS_std = zeros(roundSize);
    rResp = zeros(roundSize);
    rResp_std = zeros(roundSize);
    
    tString = num2str(t);
    
    for r = rounds
        mTPS = zeros(machineSize(2),realRunTime);
        mTPS_mean = zeros(machineSize);
        mTPS_std = zeros(machineSize);
        mResp = zeros(machineSize(2),realRunTime);
        mResp_mean = zeros(machineSize);
        mResp_std = zeros(machineSize);
        
        rString = num2str(r);
        
        for m = clientMachines

            mString = num2str(m);
            filename = strcat(fileprefix, tString,'-', mString,'-', rString, filesuffix); 
            fileId = fopen(filename);

            %skip first two lines of the file
            fgets(fileId);
            fgets(fileId);
            
            counter = 0;
            while(counter < runTime)
                endOffSet = runTime - counterOffSet;
                currline = fgets(fileId);
                counter = counter + 1;
                if(counter > counterOffSet && counter < endOffSet)
                    data = strsplit(currline,',');
                    tps = strsplit(char(data(1,3)));
                    tps = str2double(tps(1,2));
                    mTPS(m+1, counter - counterOffSet) = tps;
                    resp = strsplit(char(data(1,5)));
                    resp = str2double(resp(1,2));
                    mResp(m+1, counter - counterOffSet) = resp;
                end
                
            end
            mTPS_mean(m+1) = mean(mTPS(m+1,:));
            mTPS_std(m+1) = sqrt(sum((mTPS(m+1,:) - mTPS_mean(m+1)).^2)/(realRunTime-1));
            mResp_mean(m+1) = mean(mResp(m+1,:));
            mResp_std(m+1) = sqrt(sum((mResp(m+1,:) - mResp_mean(m+1)).^2)/(realRunTime-1));
            fclose(fileId);

        end
            
        %compute aggregated throughput 
        rTPS(r) = sum(mTPS_mean);
        rTPS_std(r) = sqrt(mean(mTPS_std.^2));
        %compute average response time
        rResp(r) = mean(mResp_mean);
        rResp_std(r) = sqrt(mean(mResp_std.^2));
        %compute average std of response time
        %rStd(r) = sqrt((mStd(1)^2 + mStd(2)^2)/2);
        
    end
    
    %compute averages of each round 
    tTPS(tCounter) = mean(rTPS);
    tTPS_std(tCounter) = sqrt(mean(rTPS_std.^2));
    %tStdThrp(tInd) = std(rTPS);
    tResp(tCounter) = mean(rResp);
    tResp_std(tCounter) = sqrt(mean(rResp_std.^2));
    %tStd(tCounter) = sqrt((sum(rStd.^2))/5);
    
    tCounter = tCounter + 1;
    
end
