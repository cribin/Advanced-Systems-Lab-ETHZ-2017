package message;


import utils.LogDataTracker;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.util.Arrays;

/**
 * Represents a memcached request with it's corresponding variables
 * This class offers additionally a method "writeToRequest" allowing to write to the request asynchronously, until the complete
 * requests has been read
 */
public class MemcachedRequest extends MemcachedMessage  {

    public enum RequestType {
        SET,
        GET,
        MULTI_GET,
        UNKNOWN
    }

    public LogDataTracker logDataTracker;

    private RequestType requestType;

    private boolean requestComplete;

    private boolean headerRead;

    private int headerLength;

    private int bodySize;

    private int totalBytesRead;

    private ByteBuffer requestBuffer;

    //Depending on the request, it can posses multiple keys
    private String[] keys;

    private MemcachedMessageParser requestParser;

    //This constructor is used for sharded request, where only the message content needs to be saved
    public MemcachedRequest()
    {
    }

    public MemcachedRequest(ByteBuffer requestBuffer)
    {
        this.requestType = RequestType.UNKNOWN;
        this.requestBuffer = requestBuffer;
        requestComplete = false;
        headerRead = false;
        bodySize = -1;
        totalBytesRead = 0;
        headerLength = -1;

        requestParser = new MemcachedMessageParser();
        logDataTracker = new LogDataTracker();
    }

    public void setRequestType(RequestType requestType) {
        this.requestType = requestType;
    }

    public RequestType getRequestType() {
        return requestType;
    }

    /**
     *
     * @param keysString All keys of a get or multi-get message as computed by the messageParser
     */
    public void setKeys(String keysString)
    {
        String[] messageSplit = keysString.split("\\s+");
        //omit the command name from the array and add the other values to the key array
        keys = Arrays.copyOfRange(messageSplit, 0, messageSplit.length);
    }

    public String getKey()
    {
        return keys[0];
    }

    public String getKeyAt(int index)
    {
        if(index > -1 && index < keys.length)
            return keys[index];
        else
        {
            System.out.println("Error: Index out of Range for Request Keys access");
            return null;
        }
    }

    public String[] getAllKeys()
    {
        return keys;
    }

    public int getNumOfKeys()
    {
        return keys.length;
    }


    public void writeToRequest(SocketChannel channel)
    {
        try {
            int bytesRead = channel.read(requestBuffer);

            if(bytesRead > 0)
            {
                totalBytesRead += bytesRead;
                //requestParses sets the corresponding header variables of this message, hence it sets the var:requestComplete
                requestParser.parseRequestMessage(this);

                if(requestComplete)
                {
                    //requestBuffer is in write mode(we can write to it), hence call flip in order to read from it
                    requestBuffer.flip();
                    setMessageContent(requestBuffer, totalBytesRead);

                }
            }

        } catch (IOException e) {
            e.printStackTrace();
            System.out.println("Error in parsing the request message");
        }


    }


    public void setRequestComplete(boolean requestComplete) {
        this.requestComplete = requestComplete;
    }

    public boolean isRequestComplete()
    {
        return  requestComplete;
    }

    public void setHeaderRead(boolean headerRead) {
        this.headerRead = headerRead;
    }

    public boolean isHeaderRead()
    {
        return headerRead;
    }

    public void setBodySize(int bodySize) {
        this.bodySize = bodySize;
    }

    public int getBodySize()
    {
        return bodySize;
    }

    public int getTotalBytesRead()
    {
        return totalBytesRead;
    }

    public ByteBuffer getRequestBuffer()
    {
        return requestBuffer;
    }

    public int getHeaderLength() {
        return headerLength;
    }

    public void setHeaderLength(int headerLength) {
        this.headerLength = headerLength;
    }


}
