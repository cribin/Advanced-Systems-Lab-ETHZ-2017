
import utils.MyLogger;
import utils.Utils;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.*;

/**
 * Main class responsible for initiating all necessary worker threads and client handlers
 * After initialization this class then starts and runs the net-thread.
 */
public class MyMiddleware implements Runnable {


    int numOfServers;

    int numThreadsPTP;

    ExecutorService executorService;

    //WorkerThreadPool workerThreadPool;

    RequestWorker[] requestWorkers;

    ClientConnectionHandler clientConnectionHandler;

    public MyMiddleware(String myIp, int myPort, List<String> mcAddresses, int numThreadsPTP, boolean readSharded)
    {
        this.numOfServers = mcAddresses.size();

        this.numThreadsPTP = numThreadsPTP;

        //stores the clients with requests
        BlockingQueue<ClientHandler> clientHandlerQueue = new LinkedBlockingQueue<>();

        executorService = Executors.newFixedThreadPool(numThreadsPTP);

        //prepare addresses for each server
        String[] serverIps = new String[numOfServers];

        int[] serverPorts = new int[numOfServers];

        for(int i = 0; i < numOfServers; i++)
        {
            String[] serverAddress = mcAddresses.get(i).split(":");
            serverIps[i] = serverAddress[0];
            serverPorts[i] = Integer.parseInt(serverAddress[1]);
        }

        //Start worker thread pool (using Executor service)
       requestWorkers = new RequestWorker[numThreadsPTP];
        for(int i = 0; i < numThreadsPTP; i++)
        {
            requestWorkers[i] = new RequestWorker(i, clientHandlerQueue, serverIps, serverPorts, readSharded);
            executorService.submit(requestWorkers[i]);
        }

        //Init server connection handler
        clientConnectionHandler = new ClientConnectionHandler(myIp, myPort, clientHandlerQueue);

        //!!!Shutdown hook is called, when the program is terminated normally using kill pid(kill -9 won't work) or upon System.exit(0);
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            //Merge logs and write to file
            this.stop();
            System.out.println("Terminating the Middleware !");
        }));
    }

    /**
     *This constructor is only used for testing purposes by the MyMiddlewareTests class
     */
    public MyMiddleware(String myIp, int myPort, String[] mcAddresses, int numThreadsPTP, boolean readSharded)
    {
        this.numOfServers = mcAddresses.length;

        this.numThreadsPTP = numThreadsPTP;

        //stores the clients with requests
        BlockingQueue<ClientHandler> clientHandlerQueue = new LinkedBlockingQueue<>();

        executorService = Executors.newFixedThreadPool(numThreadsPTP);

        //prepare addresses for each server
        String[] serverIps = new String[numOfServers];

        int[] serverPorts = new int[numOfServers];

        for(int i = 0; i < numOfServers; i++)
        {
            String[] serverAddress = mcAddresses[i].split(":");
            serverIps[i] = serverAddress[0];
            serverPorts[i] = Integer.parseInt(serverAddress[1]);
        }

        //Start worker thread pool (using Executor service)
        requestWorkers = new RequestWorker[numThreadsPTP];
        for(int i = 0; i < numThreadsPTP; i++)
        {
            requestWorkers[i] = new RequestWorker(i, clientHandlerQueue, serverIps, serverPorts, readSharded);
            executorService.execute(requestWorkers[i]);
        }

        //Init server connection handler
        clientConnectionHandler = new ClientConnectionHandler(myIp, myPort, clientHandlerQueue);
        //executorService.submit(clientConnectionHandler);

        //!!!Shutdown hook is called, when the program is terminated normally using kill pid(kill -9 won't work) or upon System.exit(0);
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            //System.out.println("Shutdown Hook is running !");
            //Merge logs and write to file
            this.stop();
            System.out.println("Terminating the Middleware !");
        }));
    }

    /**
     * This method runs the net thread
     */
    @Override
    public void run() {

       clientConnectionHandler.run();

    }

    private void stop()
    {
        //close workers
        int totalNumOfKeysSent;
        int totalGetMultiGetSent;
        int numOfEmtpyResponses;
        int numOfSets;
        int numOfGets;
        int numOfMultiGets;
        int unknownMessageTypeCount;

        //Aggregate response time histogram
        int[] responseTimeHistogram = requestWorkers[0].getResponseTimeHistogram();
        totalNumOfKeysSent = requestWorkers[0].getTotalNumOfKeysSent();
        totalGetMultiGetSent = requestWorkers[0].getTotalGetMultiGetSent();
        numOfEmtpyResponses = requestWorkers[0].getNumOfEmptyResponses();
        numOfSets = requestWorkers[0].getNumOfSets();
        numOfGets = requestWorkers[0].getNumOfGets();
        numOfMultiGets = requestWorkers[0].getNumOfMultiGets();

        unknownMessageTypeCount = requestWorkers[0].getUnknownMessageTypeCount();

        int[] sumHashCount = requestWorkers[0].getServerHashCount();

        MyLogger.log(0, requestWorkers[0].getLogDataList());
        for(int i = 1; i < numThreadsPTP; i++) {
            totalNumOfKeysSent += requestWorkers[i].getTotalNumOfKeysSent();
            totalGetMultiGetSent += requestWorkers[i].getTotalGetMultiGetSent();
            numOfEmtpyResponses += requestWorkers[i].getNumOfEmptyResponses();
            numOfSets += requestWorkers[i].getNumOfSets();
            numOfGets += requestWorkers[i].getNumOfGets();
            numOfMultiGets += requestWorkers[i].getNumOfMultiGets();
            responseTimeHistogram = Utils.addIntArrays(responseTimeHistogram, requestWorkers[i].getResponseTimeHistogram());
            unknownMessageTypeCount += requestWorkers[i].getUnknownMessageTypeCount();
            sumHashCount = Utils.addIntArrays(sumHashCount, requestWorkers[i].getServerHashCount());
            MyLogger.log(i, requestWorkers[i].getLogDataList());
        }


        double cacheMissRatio = numOfEmtpyResponses/(double)totalNumOfKeysSent;
        double avgNumOfKeys = totalNumOfKeysSent/(double)totalGetMultiGetSent;
        MyLogger.log(responseTimeHistogram, cacheMissRatio, avgNumOfKeys, numOfSets, numOfGets, numOfMultiGets, sumHashCount, unknownMessageTypeCount);

        //close net-thread
        try {
            clientConnectionHandler.close();
        } catch (IOException e) {
            e.printStackTrace();
        }

        executorService.shutdown();

    }
}
