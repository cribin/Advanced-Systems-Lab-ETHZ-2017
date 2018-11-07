package utils;

import message.MemcachedRequest;

/**
 * This class holds the logging information for a particular request worker.
 * This logging information was aggregated over a logging window(currently 2 seconds)
 * The aggregated data is not used currently, as aggregation is entirely done using an external program(matlab)
 */
public class WorkerAggregateLogData {

    public double avgThrp;
    public double avgQueueLength;
    public double avgQueueWaitingTime;
    public double avgServerProcessingTime;
    public double avgResponseTime;
    public double avgJoinTime;
    public double avgShardTime;
    public double avgBufferCopyTime;

    public double avgThrpStd;
    public double avgQueueLengthStd;
    public double avgQueueWaitingTimeStd;
    public double avgServerProcessingTimeStd;
    public double avgResponseTimeStd;

    //public boolean multiGet = false;

    public MemcachedRequest.RequestType requestType;

    public WorkerAggregateLogData(double avgThrp, double avgQueueLength, double avgQueueWaitingTime, double avgServerProcessingTime, double avgResponseTime, MemcachedRequest.RequestType requestType) {
        this.avgThrp = avgThrp;
        this.avgQueueLength = avgQueueLength;
        this.avgQueueWaitingTime = avgQueueWaitingTime;
        this.avgServerProcessingTime = avgServerProcessingTime;
        this.avgResponseTime = avgResponseTime;
        this.requestType = requestType;
    }

    public WorkerAggregateLogData(double avgThrp, double avgQueueLength, double avgQueueWaitingTime, double avgServerProcessingTime, double avgResponseTime, double avgShardTime, double avgJoinTime, double avgBufferCopyTime) {
        this.avgThrp = avgThrp;
        this.avgQueueLength = avgQueueLength;
        this.avgQueueWaitingTime = avgQueueWaitingTime;
        this.avgServerProcessingTime = avgServerProcessingTime;
        this.avgResponseTime = avgResponseTime;
        this.avgShardTime = avgShardTime;
        this.avgJoinTime = avgJoinTime;
        this.avgBufferCopyTime = avgBufferCopyTime;

        //this.multiGet = true;
        this.requestType = MemcachedRequest.RequestType.MULTI_GET;
    }

    public WorkerAggregateLogData() {
        this.avgThrp = 0;
        this.avgQueueLength = 0;
        this.avgQueueWaitingTime = 0;
        this.avgServerProcessingTime = 0;
        this.avgResponseTime = 0;
        this.avgShardTime = 0;
        this.avgJoinTime = 0;
        this.avgBufferCopyTime = 0;
        this.avgThrpStd = 0;
        this.avgQueueLengthStd = 0;
        this.avgQueueWaitingTimeStd = 0;
        this.avgServerProcessingTimeStd = 0;
        this.avgResponseTimeStd = 0;
    }

    public void addWorkerAggregateLogData(WorkerAggregateLogData newWorkerAggregateLogData)
    {
        this.avgThrp += newWorkerAggregateLogData.avgThrp;
        this.avgQueueLength += newWorkerAggregateLogData.avgQueueLength;
        this.avgQueueWaitingTime += newWorkerAggregateLogData.avgQueueWaitingTime;
        this.avgServerProcessingTime += newWorkerAggregateLogData.avgServerProcessingTime;
        this.avgResponseTime += newWorkerAggregateLogData.avgResponseTime;
    }

    public void addWorkerAggregateLogDataWithStd(WorkerAggregateLogData newWorkerAggregateLogData)
    {
        this.avgThrp += newWorkerAggregateLogData.avgThrp;
        this.avgQueueLength += newWorkerAggregateLogData.avgQueueLength;
        this.avgQueueWaitingTime += newWorkerAggregateLogData.avgQueueWaitingTime;
        this.avgServerProcessingTime += newWorkerAggregateLogData.avgServerProcessingTime;
        this.avgResponseTime += newWorkerAggregateLogData.avgResponseTime;

        this.avgThrpStd += (newWorkerAggregateLogData.avgThrpStd * newWorkerAggregateLogData.avgThrpStd);
        this.avgQueueLengthStd += (newWorkerAggregateLogData.avgQueueLengthStd * newWorkerAggregateLogData.avgQueueLengthStd);
        this.avgQueueWaitingTimeStd += (newWorkerAggregateLogData.avgQueueWaitingTimeStd * newWorkerAggregateLogData.avgQueueWaitingTimeStd);
        this.avgServerProcessingTimeStd += (newWorkerAggregateLogData.avgServerProcessingTimeStd * newWorkerAggregateLogData.avgServerProcessingTimeStd);
        this.avgResponseTimeStd += (newWorkerAggregateLogData.avgResponseTimeStd * newWorkerAggregateLogData.avgResponseTimeStd);

    }

    public void addData(double avgThrp, double avgQueueLength, double avgQueueWaitingTime, double avgServerProcessingTime, double avgResponseTime)
    {
        this.avgThrp += avgThrp;
        this.avgQueueLength += avgQueueLength;
        this.avgQueueWaitingTime += avgQueueWaitingTime;
        this.avgServerProcessingTime += avgServerProcessingTime;
        this.avgResponseTime += avgResponseTime;
    }

    public void normalize(double totalLogDataSize)
    {
        avgThrp /= totalLogDataSize;
        avgQueueLength /= totalLogDataSize;
        avgQueueWaitingTime /= totalLogDataSize;
        avgServerProcessingTime /= totalLogDataSize;
        avgResponseTime /= totalLogDataSize;
    }

    public void finalNormalize(int numThreadsPTP)
    {
        avgQueueLength /= numThreadsPTP;
        avgQueueWaitingTime /= numThreadsPTP;
        avgServerProcessingTime /= numThreadsPTP;
        avgResponseTime /= numThreadsPTP;

        avgThrpStd = Math.sqrt(avgThrpStd);
        avgQueueLengthStd = Math.sqrt(avgQueueLengthStd);
        avgQueueWaitingTimeStd = Math.sqrt(avgQueueWaitingTimeStd);
        avgServerProcessingTimeStd = Math.sqrt(avgServerProcessingTimeStd);
        avgResponseTimeStd = Math.sqrt(avgResponseTimeStd);

    }

    public void printLogData()
    {
        System.out.println("Final Throughput:" + avgThrp + " std:" + avgThrpStd);
        System.out.println("Final QueueLength:" + avgQueueLength + "  std:" + avgQueueLengthStd);
        System.out.println("Final QueueWaitingTime:" + avgQueueWaitingTime + " std:" + avgQueueWaitingTimeStd);
        System.out.println("Final ServerProcessingTime:" + avgServerProcessingTime + " std:" + avgServerProcessingTimeStd);
        System.out.println("Final ResponseTime:" + avgResponseTime + " Thrp std:" + avgResponseTimeStd);
    }

}
