package requestHandlers;

import connection.SynConnection;
import message.MemcachedRequest;
import message.MemcachedResponse;
import utils.Hasher;

/**
 * This class handles incoming get requests
 */
public class GetRequestHandler extends BaseRequestHandler{

    private Hasher hasher;

    public GetRequestHandler(SynConnection[] synConnections) {

        super(synConnections);
        hasher = new Hasher(numOfServers);
    }

    @Override
    public MemcachedResponse handleRequest(MemcachedRequest clientRequest) {

        //Hash the key to get the corresponding server
        int serverId = hasher.getServerId(clientRequest.getKey());
        serverHashCount[serverId]++;

        //Logging data:TNetIn

        //write request to the server
        synConnections[serverId].write(clientRequest.getMessageContent());
        clientRequest.logDataTracker.setServerRequestOut();

        //receive response from the server
        MemcachedResponse serverResponse = synConnections[serverId].readResponse(MemcachedRequest.RequestType.GET, 1);
        clientRequest.logDataTracker.setServerResponseIn();

        //int matches = Utils.countMatches(new String(serverResponse.getMessageContent()), Constants.getResponseTag);

        //Logging data:TNetOut => TNet = TNetOut - TNetIn

        totalMessagesSent++;
        if(serverResponse.getMessageContentLength() < 6)
        {
            numOfEmptyResponses++;
        }

        return serverResponse;
    }


}
