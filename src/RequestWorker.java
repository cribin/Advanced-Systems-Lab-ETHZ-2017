import connection.SynConnection;
import message.MemcachedRequest;
import message.MemcachedResponse;
import requestHandlers.BaseRequestHandler;
import requestHandlers.GetRequestHandler;
import requestHandlers.MultiGetRequestHandler;
import requestHandlers.SetRequestHandler;
import utils.RequestLogData;
import utils.RequestWorkerLogger;
import utils.WorkerAggregateLogData;

import java.util.ArrayList;
import java.util.concurrent.BlockingQueue;

/**
 * Main worker thread class executes the following cycle during each iteration:
 * 1) Dequeue pending requests from the request queue.
 * 2) Send the request to the corresponding server(s).
 * 3) Send the response back to the client.
 */
public class RequestWorker implements Runnable {

    private boolean isStopped;

    private int workerId;

    private BlockingQueue<ClientHandler> clientHandlerQueue;

    private int numOfServers;

    private SynConnection[] synServerConnections;

    private BaseRequestHandler setRequestHandler, getRequestHandler, multiGetRequestHandler;

    private RequestWorkerLogger requestWorkerLogger;

    private int unknownMessageTypeCount;

    public RequestWorker(int workerId, BlockingQueue<ClientHandler> clientHandlerQueue, String[] targetIps, int[] targetPorts, boolean readSharded)
    {
        this.workerId = workerId;

        this.isStopped = false;

        this.clientHandlerQueue = clientHandlerQueue;

        this.numOfServers = targetIps.length;

        //Init synchronous connections to each of the servers
        synServerConnections = new SynConnection[numOfServers];
        for(int i = 0; i < numOfServers; i++)
            synServerConnections[i] = new SynConnection(targetIps[i], targetPorts[i]);

        //Init request handlers with the syn. connection to the servers
        setRequestHandler = new SetRequestHandler(synServerConnections);
        getRequestHandler = new GetRequestHandler(synServerConnections);
        multiGetRequestHandler = new MultiGetRequestHandler(synServerConnections, readSharded);

        requestWorkerLogger = new RequestWorkerLogger(workerId);

        unknownMessageTypeCount = 0;

    }

    @Override
    public void run() {

        while(!isStopped)
        {
            try {

                ClientHandler newClient = clientHandlerQueue.take();
                handleNewClient(newClient);

            } catch (InterruptedException e) {

                stop();
                System.out.println("Failed to handle request for client:");
            }
        }

    }

    public int getNumOfSets()
    {
        return setRequestHandler.getTotalMessagesSent();
    }

    public int getNumOfGets()
    {
        return getRequestHandler.getTotalMessagesSent();
    }

    public int getNumOfMultiGets()
    {
        return multiGetRequestHandler.getTotalMessagesSent();
    }

    public int getTotalNumOfKeysSent()
    {
        return multiGetRequestHandler.getTotalNumOfKeys() + getRequestHandler.getTotalMessagesSent();
    }

    public int getNumOfEmptyResponses()
    {
        return multiGetRequestHandler.getNumOfEmptyResponses() + getRequestHandler.getNumOfEmptyResponses();
    }

    public int getTotalGetMultiGetSent()
    {
        return multiGetRequestHandler.getTotalMessagesSent() + getRequestHandler.getTotalMessagesSent();
    }

    public int[] getResponseTimeHistogram()
    {
        return requestWorkerLogger.getResponseTimeHistogram();
    }

    public WorkerAggregateLogData getWorkerAverageLogData()
    {
        return requestWorkerLogger.getWorkerAverageLogData();
    }

    public ArrayList<WorkerAggregateLogData> getLogDataList()
    {
        return requestWorkerLogger.getLogDataList();
    }

    public int[] getServerHashCount()
    {
        int[] getHashCount = getRequestHandler.getServerHashCount();
        int[] multiGetHashCount = multiGetRequestHandler.getServerHashCount();
        int[] sumHashCount = new int[numOfServers];

        for(int i = 0; i < numOfServers; i++)
            sumHashCount[i] = getHashCount[i] + multiGetHashCount[i];

        return sumHashCount;
    }

    public int getUnknownMessageTypeCount()
    {
        return  unknownMessageTypeCount;
    }

    public void stop()
    {
        //System.out.println("Closing Request worker: " + workerId);
        isStopped = true;

        for(int i = 0; i < numOfServers; i++)
            synServerConnections[i].close();

    }

    private void handleNewClient(ClientHandler newClient)
    {
        MemcachedRequest clientRequest = newClient.getClientRequest();

        clientRequest.logDataTracker.setQueueOut();

        MemcachedRequest.RequestType clientRequestType = clientRequest.getRequestType();

        MemcachedResponse serverResponse;

        switch (clientRequestType)
        {

            case SET:

                serverResponse = setRequestHandler.handleRequest(clientRequest);
                if(serverResponse.getResponseFlag() == MemcachedResponse.ResponseFlag.SUCCESS)
                {
                    requestWorkerLogger.incrementNumOfSets();
                }
                break;
            case GET:
                serverResponse = getRequestHandler.handleRequest(clientRequest);
                if(serverResponse.getResponseFlag() == MemcachedResponse.ResponseFlag.SUCCESS)
                {
                    requestWorkerLogger.incremenNumOfGets();
                }
                break;
            case MULTI_GET:
                serverResponse = multiGetRequestHandler.handleRequest(clientRequest);
                if(serverResponse.getResponseFlag() == MemcachedResponse.ResponseFlag.SUCCESS)
                {
                    requestWorkerLogger.incrementNumOfMultiGets();
                }
                break;
            default:
                System.out.println("Error: Unknown request type");
                unknownMessageTypeCount++;
                serverResponse = null;
        }


        RequestLogData newRequestLogData = null;
        if(serverResponse != null)
        {
            serverResponse.setRequestWorkerId(workerId);
            newClient.sendResponse(serverResponse);
            clientRequest.logDataTracker.setResponseOut();
            //!!We count queue length and the logging data only, if the current request was successfully handled
            if(serverResponse.getResponseFlag() == MemcachedResponse.ResponseFlag.SUCCESS)
            {
                if(clientRequestType == MemcachedRequest.RequestType.MULTI_GET)
                    newRequestLogData = clientRequest.logDataTracker.getCurrMultiGetLogData();
                else
                    newRequestLogData = clientRequest.logDataTracker.getCurrLogData(clientRequestType);

            }else
            {
                System.out.println("ERROR: Response was not successfully received!!!!");
            }
        }

        requestWorkerLogger.updateWorkerLogData(newRequestLogData, clientHandlerQueue.size());

    }

}
