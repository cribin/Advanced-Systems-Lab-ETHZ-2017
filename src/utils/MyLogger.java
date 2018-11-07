package utils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.logging.FileHandler;
import java.util.logging.Formatter;
import java.util.logging.Handler;
import java.util.logging.Logger;

import static java.util.logging.Level.INFO;

/**
 * Main logger class. It receives all the logging data from the MyMiddleware class, when the program is killed and stores
 * everything into a log file.
 */
public class MyLogger {

    static Logger logger;
    public Handler fileHandler;
    Formatter plainText;
    static int  writeCounter = 0;
    static int readCounter = 0;

    private MyLogger() throws IOException {

        //instance the logger
        logger = Logger.getLogger(MyLogger.class.getName());

        logger.setUseParentHandlers(false);
        //instance the filehandler
        fileHandler = new FileHandler("mw_log.log",false);
        //instance formatter, set formatting, and handler
        plainText = new BriefFormatter();
        fileHandler.setFormatter(plainText);
        logger.addHandler(fileHandler);
        logger.setLevel(INFO);

    }

    private static Logger getLogger(){
        if(logger == null){
            try {
                new MyLogger();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return logger;
    }


    public static void log(String msg){
        getLogger().info(msg);
        //System.out.println(msg);
    }

    public static void log(int workerId, ArrayList<WorkerAggregateLogData> logDataList)
    {
        Logger logger = getLogger();
        String workerHeader = String.format(" %d, %d",workerId, logDataList.size());
        logger.info(workerHeader);

        for(WorkerAggregateLogData log: logDataList)
        {
            String logMsg;
            /*if(log.multiGet)
                logMsg = String.format(" %f, %f, %f, %f, %f, %f, %f, %f", log.avgThrp, log.avgQueueLength, log.avgQueueWaitingTime, log.avgServerProcessingTime, log.avgResponseTime, log.avgShardTime, log.avgJoinTime, log.avgBufferCopyTime);
            else
                logMsg = String.format(" %f, %f, %f, %f, %f", log.avgThrp, log.avgQueueLength, log.avgQueueWaitingTime, log.avgServerProcessingTime, log.avgResponseTime);
            */
            switch(log.requestType)
            {

                case SET:
                    logMsg = String.format("%s, %f, %f, %f, %f, %f", "S", log.avgThrp, log.avgQueueLength, log.avgQueueWaitingTime, log.avgServerProcessingTime, log.avgResponseTime);
                    break;
                case GET:
                    logMsg = String.format("%s, %f, %f, %f, %f, %f", "G", log.avgThrp, log.avgQueueLength, log.avgQueueWaitingTime, log.avgServerProcessingTime, log.avgResponseTime);
                    break;
                case MULTI_GET:
                    logMsg = String.format("%s, %f, %f, %f, %f, %f, %f, %f, %f", "M", log.avgThrp, log.avgQueueLength, log.avgQueueWaitingTime, log.avgServerProcessingTime, log.avgResponseTime, log.avgShardTime, log.avgJoinTime, log.avgBufferCopyTime);
                    break;
                default:
                    logMsg = "ERROR";
            }

            logger.info(logMsg);
        }

    }

    public static void log(int[] responseHistogram, double cacheMissRatio, double avgNumOfKeys, int numOfSets, int numOfGets, int numOfMultiGets, int[] sumHashCount, int unknownMessageTypeCount)
    {
        Logger logger = getLogger();
        logger.info("Histogram");
        StringBuilder responseHistStringBuilder = new StringBuilder();
        for(int i = 0; i < Constants.RESP_HIST_SIZE; i++)
        {
            responseHistStringBuilder.append(responseHistogram[i]).append(" ");
        }
        //log entire histogram on one line
        logger.info(responseHistStringBuilder.toString());

        logger.info("Cache Miss Ratio");
        logger.info(String.valueOf(cacheMissRatio));

        logger.info("Average number of keys");
        logger.info(String.valueOf(avgNumOfKeys));

        logger.info("numOfSets");
        logger.info(String.valueOf(numOfSets));

        logger.info("numOfGets");
        logger.info(String.valueOf(numOfGets));

        logger.info("numOfMultiGets");
        logger.info(String.valueOf(numOfMultiGets));

        logger.info("Server Hash Count");
        for (int aSumHashCount : sumHashCount) logger.info(String.valueOf(aSumHashCount));

        logger.info("Number of unknown request types found:");
        logger.info(String.valueOf(unknownMessageTypeCount));
    }

}
