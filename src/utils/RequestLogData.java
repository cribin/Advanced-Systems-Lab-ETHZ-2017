package utils;

import message.MemcachedRequest;

/**
 * Contains the logging data of one request.
 */
public class RequestLogData {

    public long serverTotal;

    public long queueTotal;

    public long mwTotal;

    //only used for multi-gets
    MemcachedRequest.RequestType requestType;
    //boolean multiget = false;
    public long shardTotal;

    public long joinTotal;

    public long bufferCopyTime;

    public RequestLogData(long queueTotal, long serverTotal, long mwTotal, MemcachedRequest.RequestType requestType)
    {
        this.queueTotal = queueTotal;
        this.serverTotal = serverTotal;
        this.mwTotal = mwTotal;
        this.requestType = requestType;
    }

    public RequestLogData(long queueTotal, long serverTotal, long mwTotal, long shardTotal, long joinTotal, long bufferCopyTime)
    {
        this.queueTotal = queueTotal;
        this.serverTotal = serverTotal;
        this.mwTotal = mwTotal;
        this.shardTotal = shardTotal;
        this.joinTotal = joinTotal;
        this.bufferCopyTime = bufferCopyTime;

        this.requestType = MemcachedRequest.RequestType.MULTI_GET;
    }

    public void addRequestLogData(RequestLogData requestLogData)
    {
        this.queueTotal += requestLogData.queueTotal;
        this.serverTotal += requestLogData.serverTotal;
        this.mwTotal += requestLogData.mwTotal;

        if(requestType == MemcachedRequest.RequestType.MULTI_GET) {
            this.shardTotal += requestLogData.shardTotal;
            this.joinTotal += requestLogData.joinTotal;
            this.bufferCopyTime += requestLogData.bufferCopyTime;
        }
    }

    public void reset()
    {
        queueTotal = 0;
        serverTotal = 0;
        mwTotal = 0;
        if(requestType == MemcachedRequest.RequestType.MULTI_GET) {
            this.shardTotal = 0;
            this.joinTotal  = 0;
            this.bufferCopyTime = 0;
        }
    }
}
