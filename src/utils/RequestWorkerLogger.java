package utils;

import message.MemcachedRequest;

import java.util.ArrayList;
import java.util.concurrent.TimeUnit;

public class RequestWorkerLogger {

    //When computing the average ignore the firstx and last x values from the computation
    private final int warmUpCoolDownDuration = 5;
    private long startLogTime;
    private long endLogTime;
    private final long logWindow = 2;

    private int numOfSets = 0;
    private int numOfGets = 0;
    private int numOfMultiGets = 0;

    //List stores all the logging information of the requests processed during the logWindow period
    //private RequestLogData aggregateRequestLogData;
    private RequestLogData aggregateSetLogData;
    private RequestLogData aggregateGetLogData;
    //log data only used to aggregate multi-get requests
    private RequestLogData aggregateMultiGetLogData;
    private int aggregateQueueLength = 0;
    private ArrayList<WorkerAggregateLogData> logDataList;

    private int[] responseTimeHistogram;

    private int workerId;

    public RequestWorkerLogger(int workerId)
    {
        this.workerId = workerId;

        aggregateSetLogData = new RequestLogData(0, 0, 0, MemcachedRequest.RequestType.SET);

        aggregateGetLogData = new RequestLogData(0, 0, 0, MemcachedRequest.RequestType.GET);

        aggregateMultiGetLogData = new RequestLogData(0, 0, 0, 0, 0, 0);

        logDataList = new ArrayList<>();

        responseTimeHistogram = new int[Constants.RESP_HIST_SIZE];

        startLogTime = System.nanoTime();
    }

    public void updateWorkerLogData(RequestLogData newRequestLogData, int queueSize)
    {
        if(newRequestLogData == null)
            return;

        switch(newRequestLogData.requestType)
        {

            case SET:
                aggregateSetLogData.addRequestLogData(newRequestLogData);
                break;
            case GET:
                aggregateGetLogData.addRequestLogData(newRequestLogData);
                break;
            case MULTI_GET:
                aggregateMultiGetLogData.addRequestLogData(newRequestLogData);
                break;
            case UNKNOWN:
                break;
        }
        aggregateQueueLength += queueSize;

        endLogTime = System.nanoTime();

        double deltaLogTimeSec = TimeUnit.NANOSECONDS.toSeconds(endLogTime - startLogTime);

        if(deltaLogTimeSec > logWindow)
        {
            //aggregate log results if logWindow seconds have passed
            aggregateLoggingData(deltaLogTimeSec, MemcachedRequest.RequestType.SET);
            aggregateLoggingData(deltaLogTimeSec, MemcachedRequest.RequestType.GET);
            aggregateLoggingData(deltaLogTimeSec, MemcachedRequest.RequestType.MULTI_GET);
            //aggregateMultiGetLoggingData(deltaLogTimeSec);
            resetLoggingData();
        }
    }

    public void incremenNumOfGets()
    {
        numOfGets++;
    }

    public void incrementNumOfMultiGets()
    {
        numOfMultiGets++;
    }

    public void incrementNumOfSets()
    {
        numOfSets++;
    }

    private void resetLoggingData()
    {
        numOfSets = 0;
        numOfGets = 0;
        numOfMultiGets = 0;
        aggregateQueueLength = 0;

        //aggregateRequestLogData.reset();
        aggregateSetLogData.reset();
        aggregateGetLogData.reset();
        aggregateMultiGetLogData.reset();

        startLogTime = System.nanoTime();
    }

   /* private void aggregateLoggingData(double deltaLogTimeSec)
    {
        //compute average throughput = (#successful requests)/(elapsed time)
        double totalProcessedRequests = numOfSets + numOfGets;// + numOfMultiGets;
        if(totalProcessedRequests <= 0)
            return;
        double avgThrp = totalProcessedRequests / deltaLogTimeSec;
        double avgQueueLength = aggregateQueueLength / totalProcessedRequests;
        double avgQueueWaitingTime = TimeUnit.NANOSECONDS.toMillis(aggregateRequestLogData.queueTotal) / totalProcessedRequests;
        double avgServerProcessingTime = TimeUnit.NANOSECONDS.toMillis(aggregateRequestLogData.serverTotal) / totalProcessedRequests;
        double avgResponseTime = TimeUnit.NANOSECONDS.toMillis(aggregateRequestLogData.mwTotal) / totalProcessedRequests;

        WorkerAggregateLogData workerAggregateLogData = new WorkerAggregateLogData(avgThrp, avgQueueLength, avgQueueWaitingTime, avgServerProcessingTime, avgResponseTime);
        logDataList.add(workerAggregateLogData);

        int responseTimeIndex = (int) (avgResponseTime*10);
        if (responseTimeIndex >= Constants.RESP_HIST_SIZE || responseTimeIndex < 0)
            responseTimeIndex = Constants.RESP_HIST_SIZE - 1;
        responseTimeHistogram[responseTimeIndex]++;

        //System.out.println("Worker: " + workerId + " Avg Thrp: " + avgThrp + " ServerProcessingTime: " + avgServerProcessingTime + " QueueWaitingTime: " + avgQueueWaitingTime+ " ResponseTime: " + avgResponseTime);
    }*/

    private void aggregateLoggingData(double deltaLogTimeSec, MemcachedRequest.RequestType requestType)
    {
        //compute average throughput = (#successful requests)/(elapsed time)
        double totalProcessedRequests = -1;
        RequestLogData aggregateRequestLogData = null;
        switch (requestType)
        {

            case SET:
                totalProcessedRequests = numOfSets;
                aggregateRequestLogData = aggregateSetLogData;
                break;
            case GET:
                totalProcessedRequests = numOfGets;
                aggregateRequestLogData = aggregateGetLogData;
                break;
            case MULTI_GET:
                totalProcessedRequests = numOfMultiGets;
                aggregateRequestLogData = aggregateMultiGetLogData;
                break;
            case UNKNOWN:
                //ERROR
                break;
        }

        if(totalProcessedRequests <= 0)
            return;
        double avgThrp = totalProcessedRequests / deltaLogTimeSec;
        double avgQueueLength = aggregateQueueLength / totalProcessedRequests;
        double avgQueueWaitingTime = TimeUnit.NANOSECONDS.toMillis(aggregateRequestLogData.queueTotal) / totalProcessedRequests;
        double avgServerProcessingTime = TimeUnit.NANOSECONDS.toMillis(aggregateRequestLogData.serverTotal) / totalProcessedRequests;
        double avgResponseTime = TimeUnit.NANOSECONDS.toMillis(aggregateRequestLogData.mwTotal) / totalProcessedRequests;

        WorkerAggregateLogData workerAggregateLogData;
        if(requestType == MemcachedRequest.RequestType.MULTI_GET)
        {
            double avgShardTime = TimeUnit.NANOSECONDS.toMillis(aggregateRequestLogData.shardTotal)/totalProcessedRequests;
            double avgJoinTime = TimeUnit.NANOSECONDS.toMillis(aggregateRequestLogData.joinTotal)/totalProcessedRequests;
            double avgBufferCopyTime = TimeUnit.NANOSECONDS.toMillis(aggregateRequestLogData.bufferCopyTime)/totalProcessedRequests;

            workerAggregateLogData = new WorkerAggregateLogData(avgThrp, avgQueueLength, avgQueueWaitingTime, avgServerProcessingTime, avgResponseTime, avgShardTime, avgJoinTime, avgBufferCopyTime);

        }else
            workerAggregateLogData = new WorkerAggregateLogData(avgThrp, avgQueueLength, avgQueueWaitingTime, avgServerProcessingTime, avgResponseTime, requestType);

        logDataList.add(workerAggregateLogData);

        int responseTimeIndex = (int) (avgResponseTime*10);
        if (responseTimeIndex >= Constants.RESP_HIST_SIZE || responseTimeIndex < 0)
            responseTimeIndex = Constants.RESP_HIST_SIZE - 1;
        responseTimeHistogram[responseTimeIndex]++;

        //System.out.println("Worker: " + workerId + " Avg Thrp: " + avgThrp + " ServerProcessingTime: " + avgServerProcessingTime + " QueueWaitingTime: " + avgQueueWaitingTime+ " ResponseTime: " + avgResponseTime);
    }

    private void aggregateMultiGetLoggingData(double deltaLogTimeSec)
    {
        //compute average throughput = (#successful requests)/(elapsed time)
        if(numOfMultiGets <= 0)
            return;
        double totalProcessedRequests = numOfMultiGets;
        double avgThrp = numOfMultiGets/deltaLogTimeSec;
        double avgQueueLength = aggregateQueueLength/totalProcessedRequests;
        double avgQueueWaitingTime = TimeUnit.NANOSECONDS.toMillis(aggregateMultiGetLogData.queueTotal)/totalProcessedRequests;
        double avgServerProcessingTime = TimeUnit.NANOSECONDS.toMillis(aggregateMultiGetLogData.serverTotal)/totalProcessedRequests;
        double avgResponseTime = TimeUnit.NANOSECONDS.toMillis(aggregateMultiGetLogData.mwTotal)/totalProcessedRequests;
        double avgShardTime = TimeUnit.NANOSECONDS.toMillis(aggregateMultiGetLogData.shardTotal)/totalProcessedRequests;
        double avgJoinTime = TimeUnit.NANOSECONDS.toMillis(aggregateMultiGetLogData.joinTotal)/totalProcessedRequests;
        double avgBufferCopyTime = TimeUnit.NANOSECONDS.toMillis(aggregateMultiGetLogData.bufferCopyTime)/totalProcessedRequests;

        WorkerAggregateLogData workerAggregateLogData = new WorkerAggregateLogData(avgThrp, avgQueueLength, avgQueueWaitingTime, avgServerProcessingTime, avgResponseTime, avgShardTime, avgJoinTime, avgBufferCopyTime);
        logDataList.add(workerAggregateLogData);

        int responseTimeIndex = (int)(avgResponseTime*10);
        if(responseTimeIndex >= Constants.RESP_HIST_SIZE || responseTimeIndex < 0)
            responseTimeIndex = Constants.RESP_HIST_SIZE - 1;
        responseTimeHistogram[responseTimeIndex]++;

        //System.out.println("Worker: " + workerId + " Avg Thrp: " + avgThrp + " ServerProcessingTime: " + avgServerProcessingTime + " QueueWaitingTime: " + avgQueueWaitingTime+ " ResponseTime: " + avgResponseTime);
    }

    public int[] getResponseTimeHistogram()
    {
        return responseTimeHistogram;
    }

    public WorkerAggregateLogData getWorkerAverageLogData()
    {
        WorkerAggregateLogData finalWorkerAggregateLogData = new WorkerAggregateLogData();
        int totalLogDataSize = logDataList.size();
        int endDuration = totalLogDataSize - warmUpCoolDownDuration - 1;
        double realLogDataSize = totalLogDataSize - 2* warmUpCoolDownDuration;

        //Compute mean
        int counter = 0;
        for(WorkerAggregateLogData log : logDataList)
        {
            if(counter < warmUpCoolDownDuration)
            {
                counter++;
                continue;
            }

            if(counter > endDuration)
                break;

            finalWorkerAggregateLogData.addWorkerAggregateLogData(log);

            counter++;
        }

        finalWorkerAggregateLogData.normalize(realLogDataSize);

        //Compute std
        counter = 0;
        WorkerAggregateLogData tmpWorkerAggregateLogData = new WorkerAggregateLogData();
        for(WorkerAggregateLogData log : logDataList)
        {
            if(counter < warmUpCoolDownDuration)
            {
                counter++;
                continue;
            }

            if(counter > endDuration)
                break;

            tmpWorkerAggregateLogData.addData(Math.pow(log.avgThrp - finalWorkerAggregateLogData.avgThrp, 2f), Math.pow(log.avgQueueLength - finalWorkerAggregateLogData.avgQueueLength, 2f),
                    Math.pow(log.avgQueueWaitingTime - finalWorkerAggregateLogData.avgQueueWaitingTime, 2f), Math.pow(log.avgServerProcessingTime - finalWorkerAggregateLogData.avgServerProcessingTime, 2f),
                    Math.pow(log.avgResponseTime- finalWorkerAggregateLogData.avgResponseTime, 2f));

            counter++;
        }

        tmpWorkerAggregateLogData.normalize(realLogDataSize - 1);

        finalWorkerAggregateLogData.avgThrpStd = Math.sqrt(tmpWorkerAggregateLogData.avgThrp);
        finalWorkerAggregateLogData.avgQueueLengthStd = Math.sqrt(tmpWorkerAggregateLogData.avgQueueLength);
        finalWorkerAggregateLogData.avgQueueWaitingTimeStd = Math.sqrt(tmpWorkerAggregateLogData.avgQueueWaitingTime);
        finalWorkerAggregateLogData.avgServerProcessingTimeStd = Math.sqrt(tmpWorkerAggregateLogData.avgServerProcessingTime);
        finalWorkerAggregateLogData.avgResponseTimeStd = Math.sqrt(tmpWorkerAggregateLogData.avgResponseTime);

        return  finalWorkerAggregateLogData;
    }

    public ArrayList<WorkerAggregateLogData> getLogDataList()
    {
        return logDataList;
    }


}
