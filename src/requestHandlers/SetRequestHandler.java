package requestHandlers;

import connection.SynConnection;
import message.MemcachedRequest;
import message.MemcachedResponse;

/**
 *  This class handles incoming set requests.
 */
public class SetRequestHandler extends BaseRequestHandler {

    public SetRequestHandler(SynConnection[] synConnections) {
        super(synConnections);
    }

    @Override
    public MemcachedResponse handleRequest(MemcachedRequest clientRequest) {

        MemcachedResponse[] serverResponses = new MemcachedResponse[numOfServers];

        totalMessagesSent++;
        //Logging data:TNetIn
        int errorResponseIndex = 0;

        //Write set requests to each of the servers
        for(int i = 0; i < numOfServers; i++)
        {
            synConnections[i].write(clientRequest.getMessageContent());
        }
        clientRequest.logDataTracker.setServerRequestOut();

        //Receive responses from each server
        for(int i = 0; i < numOfServers; i++)
        {
            serverResponses[i] = synConnections[i].readResponse(MemcachedRequest.RequestType.SET, 1);
            if(serverResponses[i].getResponseFlag() == MemcachedResponse.ResponseFlag.ERROR)
            {
                errorResponseIndex = i;
            }
        }

        clientRequest.logDataTracker.setServerResponseIn();
        //Logging data:TNetOut => TNet = TNetOut - TNetIn


        return serverResponses[errorResponseIndex];
    }


}
