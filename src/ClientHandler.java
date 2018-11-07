
import message.MemcachedRequest;
import message.MemcachedResponse;
import utils.Constants;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;

/**
 * This class stores the connection and the current request of a specific client.
 * Furthermore this class is offers methods to read a complete request from the client and write the corresponding response back.
 */
public class ClientHandler {


    private MemcachedRequest clientRequest;

    private SocketChannel clientSocketChannel;

    private ByteBuffer requestBuffer;


    public ClientHandler(SocketChannel clientSocketChannel)
    {
        this.clientSocketChannel = clientSocketChannel;
        requestBuffer = ByteBuffer.allocate(Constants.MAX_BUFFER_SIZE);
        clientRequest = new MemcachedRequest(requestBuffer);
    }

    public MemcachedRequest getClientRequest()
    {
        return clientRequest;
    }

    /**
     *
     * @param serverResponse: Response from the server to be sent back to the client
     */
    public void sendResponse(MemcachedResponse serverResponse)
    {
        ByteBuffer responseBuffer = ByteBuffer.wrap(serverResponse.getMessageContent(),0, serverResponse.getMessageContentLength());
        //System.out.print("Curr Response from server " + serverResponse.getRequestWorkerId() +":" + new String(serverResponse.getMessageContent()));
        try {

            while (responseBuffer.hasRemaining())
            {
               clientSocketChannel.write(responseBuffer);
            }

        } catch (IOException e) {
            e.printStackTrace();
            System.out.println("Can't send response to client");
        }

    }

    /**
     *
     * @return
     */
    public boolean readRequest()
    {
        if(clientRequest.isRequestComplete())
        {
            //Create a new request
            requestBuffer.clear();
            clientRequest = new MemcachedRequest(requestBuffer);
        }

       clientRequest.writeToRequest(clientSocketChannel);
        /*if(clientRequest.isRequestComplete())
        {
            setRequestIn();
            //Logging data:TReqIn
            //System.out.print("Curr Request:" + new String(clientRequest.getMessageContent()));
        }*/

       return clientRequest.isRequestComplete();
    }

    public void setQueueIn()
    {
        clientRequest.logDataTracker.setQueueIn();
    }

    public void setQueueOut()
    {
        clientRequest.logDataTracker.setQueueOut();
    }

    public void setRequestIn()
    {

        clientRequest.logDataTracker.setRequestIn();
    }

    public void setResponseOut()
    {
        clientRequest.logDataTracker.setResponseOut();
    }

    public MemcachedRequest.RequestType getRequestType()
    {
        return clientRequest.getRequestType();
    }

}
