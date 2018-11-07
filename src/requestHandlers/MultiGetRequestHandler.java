package requestHandlers;

import connection.SynConnection;
import message.MemcachedRequest;
import message.MemcachedResponse;
import utils.Constants;
import utils.Hasher;
import utils.Utils;

import java.util.Arrays;
import java.util.concurrent.*;

/**
 * This class handles incoming multi-get requests.
 * It also takes care of sharding the request if necessary and reassembling the responses together.
 */
public class MultiGetRequestHandler extends BaseRequestHandler {

    private boolean readSharded;

    private Hasher hasher;

    public MultiGetRequestHandler(SynConnection[] synConnections, boolean readSharded) {

        super(synConnections);

        this.readSharded = readSharded;

        hasher = new Hasher(numOfServers);
    }


    @Override
    public MemcachedResponse handleRequest(MemcachedRequest clientRequest) {

        int numOfKeys = clientRequest.getNumOfKeys();

        totalNumOfKeys += numOfKeys;
        totalMessagesSent++;

        if(readSharded && numOfServers > 1)
        {
            //Receive responses
            int totalMessageLen = 0;
            //determine how many keys each server gets
            int[] parts = getParts(numOfKeys, numOfServers);
            //shards given by the parts above
            MemcachedRequest[] shardedRequests = shardRequest(clientRequest, parts);
            MemcachedResponse[] serverResponses = new MemcachedResponse[shardedRequests.length];

            //Send sharded requests to the corresponding servers

            for(int i = 0; i < shardedRequests.length; i++)
            {
                synConnections[i].write(shardedRequests[i].getMessageContent());
            }
            clientRequest.logDataTracker.setServerRequestOut();

            long totalBufferCopyTime = 0;

            for(int i = 0; i < shardedRequests.length; i++) {

                serverResponses[i] = synConnections[i].readResponse(MemcachedRequest.RequestType.MULTI_GET, parts[i]);
                totalMessageLen += serverResponses[i].getMessageContentLength();
                totalBufferCopyTime += serverResponses[i].getBufferCopyTime();
            }

            clientRequest.logDataTracker.setServerResponseIn();
            clientRequest.logDataTracker.setBufferCopyTime(totalBufferCopyTime);

            double numOfResponses = totalMessageLen/ Constants.VALUE_SIZE;
            numOfEmptyResponses += numOfKeys - numOfResponses;

            //assemble responses together
            return joinResponses(clientRequest, serverResponses, totalMessageLen);

        }else
        {
            //randomly pick one key
            int keyIndex = ThreadLocalRandom.current().nextInt(0, numOfKeys);
            int serverId = hasher.getServerId(clientRequest.getKeyAt(keyIndex));
            serverHashCount[serverId]++;

            synConnections[serverId].write(clientRequest.getMessageContent());
            clientRequest.logDataTracker.setServerRequestOut();

            MemcachedResponse memcachedResponse = synConnections[serverId].readResponse(MemcachedRequest.RequestType.MULTI_GET, numOfKeys);
            clientRequest.logDataTracker.setServerResponseIn();

            double numOfResponses = memcachedResponse.getMessageContentLength()/ Constants.VALUE_SIZE;
            numOfEmptyResponses += numOfKeys - numOfResponses;

            return memcachedResponse;
        }

    }

    /**
     *
     * @param clientRequest : Current request
     * @param parts : Element i indicates how many keys server i receives
     * @return The array containing the sharded requests for each server
     */
    private MemcachedRequest[] shardRequest(MemcachedRequest clientRequest, int[] parts)
    {
        clientRequest.logDataTracker.setShardStart();
        String[] keys = clientRequest.getAllKeys();
        //long test = System.nanoTime();
        int numOfKeys = keys.length;

        String prefix = "get ";
        String suffix = "\r\n";

        //Init arrays
        MemcachedRequest[] shardedRequests;
        if(numOfKeys < numOfServers)
        {
            shardedRequests = new MemcachedRequest[numOfKeys];
        }else
        {
            shardedRequests = new MemcachedRequest[numOfServers];
        }

        int startIndex = 0;
        int endIndex;
        String joinedKeys;
        //join keys together according to the parts array
        for(int i = 0; i < parts.length; i++)
        {
            endIndex = startIndex + parts[i];
            //join all keys from startIndex to (exclusive)endIndex
            joinedKeys = Utils.join(keys, " ", startIndex, endIndex);
            shardedRequests[i] = new MemcachedRequest();
            shardedRequests[i].setMessageContent(prefix + joinedKeys + suffix);

            startIndex = endIndex;
        }

       // long delta = System.nanoTime() - test;
       // System.out.println(delta);
        clientRequest.logDataTracker.setShardEnd();
        return shardedRequests;

    }

    private MemcachedResponse joinResponses(MemcachedRequest clientRequest, MemcachedResponse[] shardedResponses, int totalMessageLen)
    {
        clientRequest.logDataTracker.setJoinStart();
        //Take away the "END\r\n"=5 bytes from each of the sharded requests except the last one
        int endOffset = (shardedResponses.length - 1)*5;
        MemcachedResponse joinedResponse = new MemcachedResponse(totalMessageLen - endOffset);
        byte[] joinedMessageContent = joinedResponse.getMessageContent();

        int startIndex = 0;
        int lastIndex = shardedResponses.length - 1;
        for(int i = 0; i < lastIndex; i++)
        {
            int currLen = shardedResponses[i].getMessageContentLength() - 5;
            System.arraycopy(shardedResponses[i].getMessageContent(), 0, joinedMessageContent, startIndex, currLen);
            startIndex += currLen;
        }

        System.arraycopy(shardedResponses[lastIndex].getMessageContent(), 0, joinedMessageContent, startIndex, shardedResponses[lastIndex].getMessageContentLength());

        //joinedResponse.setMessageContent(joinedMessageContent, joinedMessageContent.length);

        joinedResponse.setResponseFlag(MemcachedResponse.ResponseFlag.SUCCESS);
        joinedResponse.setMessageContentLength(joinedMessageContent.length);

        clientRequest.logDataTracker.setJoinEnd();
        return joinedResponse;
    }

    /**
     *
     * @param numOfKeys
     * @param numOfShards
     * @return An array , where an element i determines how many keys server i has to handle
     */
    private int[] getParts(int numOfKeys, int numOfShards)
    {
        int[] parts;

        if(numOfKeys >= numOfShards) {

            parts = new int[numOfShards];
            int remainder = numOfKeys % numOfShards;
            int mean = numOfKeys / numOfShards;

            Arrays.fill(parts, mean);

            //distribute remainder evenly among the servers
            for(int i = 0; i < remainder; i++)
                parts[i] += 1;

        }else
        {
            parts = new int[numOfKeys];
            Arrays.fill(parts, 1);
        }

        return parts;

    }


}
