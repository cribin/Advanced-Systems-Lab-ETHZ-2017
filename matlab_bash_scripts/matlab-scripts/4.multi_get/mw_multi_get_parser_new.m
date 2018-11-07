%clear();
%!!!Important first call sharded and then non sharded version!!!!This script parses the mw data for the sharded and nonsharded case
sharded = false;
shardedPrefix = 'Multi_Get/Sharded/MWLog/mw_multi_get_shard_2-';
nonshardedPrefix = 'Multi_Get/NonSharded/MWLog/mw_multi_get_non_shard_2-';

filesuffix = '.log';

numOfVCs = 2;
workerThreads = 64;
rounds = 1:3;
fieldSize = 5;

roundSize = size(rounds);
numOfKeySizes = 4;%size(maxKeySizes);
workersSize = size(workerThreads);

requestTypes = 2;

if(sharded)
    fileprefix = shardedPrefix;
    maxKeySizes = [1,3,6,9];
    finalData = zeros(requestTypes, numOfKeySizes, fieldSize);
    finalDataStd = zeros(requestTypes, numOfKeySizes, fieldSize);

else
    fileprefix = nonshardedPrefix;
    maxKeySizes = [3,6,9];
    finalData(:,end,:) = finalData(:,1,:);
    finalDataStd(:,end,:) = finalDataStd(:,1,:);

end

startOffset = 4;

w = workerThreads;
keyCounter = 1;

wString = num2str(w);

for key = maxKeySizes

    rData = zeros(requestTypes, roundSize(2), fieldSize);
    rDataStd = zeros(requestTypes, roundSize(2), fieldSize);
    
    keyString = num2str(key);
    
    for r = rounds
        rString = num2str(r);
        
        mwData = zeros(requestTypes, 2, fieldSize);
        mwDataStd = zeros(requestTypes, 2, fieldSize);
        
        for mw = 1:2
        
            mwString = num2str(mw);
            filename = strcat(fileprefix, rString,'-', wString,'-',keyString,'-', mwString, filesuffix); 
            fileId = fopen(filename);
            %read number of lines to read per worker
            currline = fgets(fileId);
            linesPerWorker = strsplit(currline,',');
            linesPerWorker = str2double(linesPerWorker(2));
           
            workerData = zeros(requestTypes, w,5);
            workerDataStd = zeros(requestTypes,w, 5);
            
            for workers = 1:w
            
                workerDataTmp = zeros(linesPerWorker, 6);
                
                currline = fgets(fileId);
                counter = 1;
                while(size(currline,2) > 10)
                
                    data = textscan(currline,'%s %f %f %f %f %f %*[^\n]','Delimiter',',');
                    workerDataTmp(counter,2:end) = cell2mat(data(2:end));
                    workerDataTmp(counter,1) = data{1,1}{1};
                    
                    currline = fgets(fileId);
                    counter = counter + 1;
                end
                
                endOffset = counter - startOffset;
                
                %skip worker Id number
                %fgets(fileId);
                workerDataTmp = workerDataTmp(startOffset:endOffset,:);
                workerDataTmp = removeOutliers(workerDataTmp);
                realWorkerDataSize = size(workerDataTmp,1);
                %initialize set data
                setReqIndices = workerDataTmp(:,1)=='S';
                workerData(1,workers,:) = mean(workerDataTmp(setReqIndices,2:end),1);
                workerDataStd(1,workers,:) = sqrt(sum((workerDataTmp(setReqIndices,2:end) - reshape(workerData(1,workers,:),[1,5])).^2,1)/(realWorkerDataSize - 1)); 
                %initialize multi-get data
                getReqIndices = (workerDataTmp(:,1)=='M' | workerDataTmp(:,1)=='G');
                workerData(2,workers,:) = mean(workerDataTmp(getReqIndices,2:end),1);
                workerDataStd(2,workers,:) = sqrt(sum((workerDataTmp(getReqIndices,2:end) - reshape(workerData(2,workers,:),[1,5])).^2,1)/(realWorkerDataSize - 1));   
                
            end
            
            mwData(1,mw,:) = [sum(workerData(1,:,1)),mean(reshape(workerData(1,:,2:5),[w,4]))];
            mwDataStd(1,mw,:) = sqrt(sum(reshape(workerDataStd(1,:,:),[w,5]).^2,1)/w);
            mwData(2,mw,:) = [sum(workerData(2,:,1)),mean(reshape(workerData(2,:,2:5),[w,4]))];
            mwDataStd(2,mw,:) = sqrt(sum(reshape(workerDataStd(2,:,:),[w,5]).^2,1)/w);
        
        end
        %compute aggregated data 
        rData(1,r,:) = [sum(mwData(1,:,1)),reshape(mean(mwData(1,:,2:5),2),[1,4])] ;
        rDataStd(1,r,:) = sqrt(sum(reshape(mwDataStd(1,:,:),[2,5]).^2,1)/2);
        rData(2,r,:) = [sum(mwData(2,:,1)),reshape(mean(mwData(2,:,2:5),2),[1,4])] ;
        rDataStd(2,r,:) = sqrt(sum(reshape(mwDataStd(2,:,:),[2,5]).^2,1)/2);
    
    end
    
    %compute averages of each round 
    finalData(1, keyCounter, :) = mean(reshape(rData(1,:,:),[roundSize(2),fieldSize]),1);
    finalDataStd(1, keyCounter, :) = sqrt(sum(reshape(rDataStd(1,:,:),[roundSize(2),fieldSize]).^2,1)/roundSize(2));
    
    finalData(2, keyCounter, :) = mean(reshape(rData(2,:,:),[roundSize(2),fieldSize]),1);
    finalDataStd(2, keyCounter, :) = sqrt(sum(reshape(rDataStd(2,:,:),[roundSize(2),fieldSize]).^2,1)/roundSize(2));
    
    keyCounter = keyCounter + 1;

end
    

function newWorkerData = removeOutliers(oldWorkerData)
   
    outlierIndex = isoutlier(oldWorkerData(:,2:end));
    majorityOutlierIndex = sum(outlierIndex,2) > 2;
    inlierIndex = logical(1- majorityOutlierIndex);
    newWorkerData = oldWorkerData(inlierIndex,:);
    
end

