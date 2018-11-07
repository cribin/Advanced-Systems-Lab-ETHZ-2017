clear();
%Parse baseline files with 1 client connecting to 2 memcached instances

fileprefix = 'LogData/two_servers/baseline_read_';
filesuffix = '.txt';

numOfVCs = [1,8,16,20,24,32];
clientMachine = 0;
mString = num2str(clientMachine);
serverMachines = 1:2;
rounds = 1:3;
runTime = 70;

roundSize = size(rounds);
VCSize = size(numOfVCs);
serversSize = size(serverMachines);

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
       
        sTPS_mean = zeros(serversSize);
        sTPS_std = zeros(serversSize);
        sResp_mean = zeros(serversSize);
        sResp_std = zeros(serversSize);
        
        rString = num2str(r);
        
        sTPS = zeros(serversSize(2), realRunTime);
        sResp = zeros(serversSize(2), realRunTime);
        for s = serverMachines

            sString = num2str(s);
            filename = strcat(fileprefix, tString,'-', mString,'-', rString,'-', sString, filesuffix); 
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
                    sTPS(s, counter - counterOffSet) = tps;
                    resp = strsplit(char(data(1,5)));
                    resp = str2double(resp(1,2));
                    sResp(s, counter - counterOffSet) = resp;
                end
                
            end
            sTPS_mean(s) = mean(sTPS(s,:));
            sTPS_std(s) = sqrt(sum((sTPS(s,:) - sTPS_mean(s)).^2)/(realRunTime-1));
            sResp_mean(s) = mean(sResp(s,:));
            sResp_std(s) = sqrt(sum((sResp(s,:) - sResp_mean(s)).^2)/(realRunTime-1));
            fclose(fileId);

        end
            
        %compute aggregated throughput 
        rTPS(r) = sum(sTPS_mean);
        rTPS_std(r) = sqrt(mean(sTPS_std.^2));
        %compute average response time
        rResp(r) = mean(sResp_mean);
        rResp_std(r) = sqrt(mean(sResp_std.^2));
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

