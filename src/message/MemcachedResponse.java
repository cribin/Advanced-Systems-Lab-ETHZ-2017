package message;


/**
 * Represents a memcached response with it's corresponding variables
 */
public class MemcachedResponse extends MemcachedMessage {

    public void setRequestWorkerId(int requestWorkerId) {
        this.requestWorkerId = requestWorkerId;
    }

    //Some logging data
    private int requestWorkerId;

    private long bufferCopyTime;

    public long getBufferCopyTime() {
        return bufferCopyTime;
    }

    public void setBufferCopyTime(long bufferCopyTime) {
        this.bufferCopyTime = bufferCopyTime;
    }

    public enum ResponseFlag{
        SUCCESS,
        ERROR,
        UNKNOWN
    }

    ResponseFlag responseFlag;

    public MemcachedResponse()
    {

    }

    public MemcachedResponse(int messageLength)
    {
        messageContent = new byte[messageLength];
    }

    public void setResponseFlag(ResponseFlag responseFlag) {
        this.responseFlag = responseFlag;
    }

    public ResponseFlag getResponseFlag() {
        return responseFlag;
    }





}
