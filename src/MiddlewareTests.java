import junit.framework.TestCase;
import org.junit.Test;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.Socket;
import java.util.Random;
import java.util.concurrent.Semaphore;
import java.util.concurrent.ThreadLocalRandom;


/**
 * This class is used for testing the middleware and ensuring that it behaves according to the project requirements
 */
public class MiddlewareTests extends TestCase
{
    private static char[] chars = "abcdefghijklmnopqrstuvwxyz".toCharArray();
    private static int id=0;
    private static Random random = new Random();

    public static String generateRandomString(int len) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < len; i++) {
            char c = chars[random.nextInt(chars.length)];
            sb.append(c);
        }
        return sb.toString();
    }

    public static String generateWriteCMD(int len, String key) {
        StringBuilder sb = new StringBuilder();
        sb.append("set ").append(key).append(" 0 0 ").append(len).append("\r\n");
        sb.append(generateRandomString(len));
        sb.append("\r\n");
        return sb.toString();
    }

    private static String generateReadCMD(String key) {
        StringBuilder sb = new StringBuilder();
        int randomInt = random.nextInt(100);
        sb.append("get ").append(key);
        sb.append("\r\n");
        return sb.toString();
    }

    private static void startMiddelWareTest(int numPartitions, int numClientThreads, int numIter, boolean multiget) {
        int localPort = 11400;
        String localIp = "127.0.0.1";
        String[] ips = new String[numPartitions];
        Process[] processes = new Process[numPartitions];
        ClientThread[] threads = new ClientThread[numClientThreads];
        Semaphore sem = new Semaphore(-numClientThreads + 1);
        int[] ports = new int[numPartitions];


        for(int i=1; i<=numPartitions;i++) {
            ports[i-1]=localPort+i;
            ips[i-1] = "localhost:" + ports[i - 1];
        }

        for(int i=0; i<numPartitions;i++) {
            Runtime rt = Runtime.getRuntime();
            try {
                processes[i] = rt.exec("memcached -p "+ports[i]+" -t 1");
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        MyMiddleware m = null;
        try {
            Thread mwThread = new Thread(new MyMiddleware(localIp, localPort, ips ,32,true));
            mwThread.start();
            for(int i=0; i<numClientThreads;i++) {
                threads[i] = new ClientThread(i, localPort, numIter, sem, multiget);
                threads[i].start();
            }


            sem.acquire();

            for(int i=0; i<numClientThreads;i++) {
                assertTrue(threads[i].success && threads[i].finished);
            }

        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {

            for(int i=0; i<numPartitions;i++) {
                if(processes[i]!=null)
                    processes[i].destroy();
            }
        }


    }

    @Test
    public void testMemcache() {

        startMiddelWareTest(3,200, 1000, true);
    }

    public static class ClientThread extends Thread {

        private int id;
        private int port;
        private int iter;

        private Semaphore sem;

        boolean success = true;
        boolean finished = false;
        boolean multiget = false;

        int messageSize = 1024;
        int numOfMultiGetKeys  = 10;
        int numOfMultiGetResponseLines = numOfMultiGetKeys*2 + 1;

        String[] emptyKeys = {"Queens","StarWars", "LotR", "Yoda", "Anakin", "Luke"};

        String[] keys;
        String[] values;

        public ClientThread(int id, int port, int iter, Semaphore sem, boolean multiget) {
            this.id = id;
            this.port = port;
            this.iter = iter;
            this.sem = sem;

            this.multiget = multiget;
        }

        @Override
        public void run() {
            super.run();


            if(multiget)
                runMultiGetTests();
            else
                runSimpleGetSetTests();
        }

        private void runSimpleGetSetTests()
        {
            Socket clientSocket = null;
            DataOutputStream outToServer = null;
            BufferedReader inFromServer = null;
            try {
                clientSocket = new Socket("localhost", port);
                inFromServer = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
                outToServer = new DataOutputStream(clientSocket.getOutputStream());

                for (int i = 0; i < iter; i++) {
                    String key = "t" + id + "k" + i;
                    String write = generateWriteCMD(messageSize, key);

                    outToServer.writeBytes(write);
                    outToServer.flush();
                    String response = inFromServer.readLine();


                    String readCMD = generateReadCMD(key);
                    outToServer.writeBytes(readCMD);
                    outToServer.flush();
                    response = inFromServer.readLine();
                    if (!response.contains("VALUE")) {

                        success = false;
                    } else {
                        String data = inFromServer.readLine();
                        inFromServer.readLine();
                        if (!write.contains(data))
                            success = false;
                    }

                }

                finished = true;

            } catch (IOException e) {
                e.printStackTrace();
            } finally {
                try {
                    if (clientSocket != null)
                        clientSocket.close();
                    if (outToServer != null)
                        outToServer.close();
                    if (inFromServer != null)
                        inFromServer.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
                sem.release();

            }
        }

        private void runMultiGetTests()
        {
            super.run();
            Socket clientSocket = null;
            DataOutputStream outToServer = null;
            BufferedReader inFromServer = null;
            try {
                clientSocket = new Socket("localhost", port);
                clientSocket.setSoTimeout(5000);
                inFromServer = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
                outToServer = new DataOutputStream(clientSocket.getOutputStream());
                keys = new String[iter];
                values = new String[iter];
                String response;

                for (int i = 0; i < iter; i++) {
                    keys[i] = "t" + id + "k" + i;
                    values[i] = generateWriteCMD(messageSize , keys[i]);
                    //String write = generateWriteCMD(20, String.valueOf(i));
                    outToServer.writeBytes(values[i]);
                    outToServer.flush();
                    response = inFromServer.readLine();
                    System.out.println("T" + id + " Response Store: " + response);
                }

                for (int i = 0; i < iter; i++) {

                    int numOfKeys = numOfMultiGetKeys;//ThreadLocalRandom.current().nextInt(1, 10);
                    String multiReadCMD = generateMultiReadCMD(numOfKeys);
                    outToServer.writeBytes(multiReadCMD);
                    outToServer.flush();

                    int linesRead = 0;

                    while(true)
                    {
                        response = inFromServer.readLine();
                        linesRead++;
                        //System.out.println("T" + id + " Response Read: " + response);
                        if (response.contains("END")){
                            /*if(linesRead != numOfMultiGetResponseLines)
                                success = false;*/
                            System.out.println(String.valueOf(linesRead));
                            break;
                        }

                    }

                }
                finished = true;

            } catch (IOException e) {
                e.printStackTrace();

            } finally {
                try {
                    if (clientSocket != null)
                        clientSocket.close();
                    if (outToServer != null)
                        outToServer.close();
                    if (inFromServer != null)
                        inFromServer.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
                sem.release();

            }
        }

        private String generateMultiReadCMD(int numOfKeys)
        {
            StringBuilder sb = new StringBuilder();
            sb.append("get ");
            for (int i = 0; i < numOfKeys; i++) {
                int length = keys.length;
                int halfLength = 3*(keys.length/5);
                String key = keys[ThreadLocalRandom.current().nextInt(halfLength, keys.length)];
                sb.append(key);
                if(i != numOfKeys-1)
                    sb.append(" ");
            }
            sb.append("\r\n");
            return sb.toString();
        }
    }
}
