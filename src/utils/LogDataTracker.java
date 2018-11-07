package utils;

import message.MemcachedRequest;

/**
 * This class stores all the timestamps made per request, in order to get the logging information
 * Additionally it returns a RequestLogData object, which contains all the logging data computed by taking the difference between the time stamps.
 */
public class LogDataTracker {

    public long requestIn = 0;
    public long responseOut = 0;
    public long queueIn = 0;
    public long queueOut = 0;
    public long serverRequestOut = 0;
    public long serverResponseIn = 0;


    //only used for multi-get
    public long shardStart = 0;
    public long shardEnd = 0;
    public long joinStart = 0;
    public long joinEnd = 0;
    public long bufferCopyTime;

    MemcachedRequest.RequestType requestType = MemcachedRequest.RequestType.UNKNOWN;

    public void setRequestIn() {
        this.requestIn = getTime();
    }

    public void setResponseOut() {
        this.responseOut = getTime();
    }

    public void setQueueIn() {

        this.queueIn = getTime();
    }

    public void setBufferCopyTime(long bufferCopyTime)
    {
        this.bufferCopyTime = bufferCopyTime;
    }

    public void setQueueOut() {
        this.queueOut = getTime();
    }

    public void setServerRequestOut() {
        this.serverRequestOut = getTime();
    }

    public void setServerResponseIn() {
        this.serverResponseIn = getTime();
    }

    public void setShardStart() {
        this.shardStart = getTime();
    }

    public void setShardEnd() {
        this.shardEnd = getTime();
    }

    public void setJoinStart() {
        this.joinStart = getTime();
    }

    public void setJoinEnd() {
        this.joinEnd = getTime();
    }

    private static long getTime() {
        return System.nanoTime();
    }

    public synchronized RequestLogData getCurrLogData(MemcachedRequest.RequestType requestType)
    {
        return new RequestLogData(queueOut - queueIn, serverResponseIn - serverRequestOut, responseOut- requestIn, requestType);
    }

    public synchronized RequestLogData getCurrMultiGetLogData()
    {
        return new RequestLogData(queueOut - queueIn, serverResponseIn - serverRequestOut, responseOut- requestIn, shardEnd - shardStart, joinEnd - joinStart, bufferCopyTime);
    }
}
