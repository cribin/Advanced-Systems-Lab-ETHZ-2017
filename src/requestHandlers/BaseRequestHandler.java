package requestHandlers;

import connection.SynConnection;
import message.MemcachedRequest;
import message.MemcachedResponse;

/**
 * Base class for all request handler classes
 */
public abstract class BaseRequestHandler {

    protected SynConnection[] synConnections;

    protected int numOfServers;

    protected int totalMessagesSent = 0;
    protected int numOfEmptyResponses = 0;
    protected int totalNumOfKeys = 0;
    //indicates how many time each of the servers have been hashed(only used for get and multi-get)
    protected int[] serverHashCount;

    public BaseRequestHandler(SynConnection[] synConnections)
    {
        this.synConnections = synConnections;
        numOfServers = synConnections.length;
        if(numOfServers < 1)
            System.out.println("Error: Number of servers can't be 0 !!!");

        serverHashCount = new int[numOfServers];
    }

    public abstract MemcachedResponse handleRequest(MemcachedRequest clientRequest);

    public int getTotalMessagesSent()
    {
        return totalMessagesSent;
    }

    public int getNumOfEmptyResponses()
    {
        return numOfEmptyResponses;
    }

   public int getTotalNumOfKeys()
   {
       return totalNumOfKeys;
   }

   public int[] getServerHashCount()
   {
       return serverHashCount;
   }
}
