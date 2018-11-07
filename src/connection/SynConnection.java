package connection;

import message.MemcachedMessageParser;
import message.MemcachedRequest;
import message.MemcachedResponse;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.IOException;
import java.net.Socket;

/**
 * This class represents a synchronous connection to an endpoint
 * It is only used for the communication between the worker thread and the server
 */
public class SynConnection {

    private String targetIp;
    private Socket socket;

    private BufferedInputStream bufferedInputStream;
    private BufferedOutputStream bufferedOutputStream;

    private MemcachedMessageParser memcachedMessageParser;

    public SynConnection(String targetIp, int targetPort)
    {
        this.targetIp = targetIp;

        try {

            socket = new Socket(targetIp, targetPort);
            //socket.setSoTimeout(5000);
            bufferedInputStream = new BufferedInputStream(socket.getInputStream());
            bufferedOutputStream = new BufferedOutputStream(socket.getOutputStream());

            memcachedMessageParser = new MemcachedMessageParser();

        } catch (IOException e) {

            System.out.println("Failed to connect to server :" + targetIp);
        }
    }

    public void close()
    {
        try {

            bufferedInputStream.close();
            bufferedOutputStream.close();
            socket.close();

        } catch (IOException e) {

            System.out.println("Failed to close socket to server :" + targetIp);
        }
    }

    public MemcachedResponse readResponse(MemcachedRequest.RequestType requestType, int numOfKeys)
    {
        return memcachedMessageParser.parseResponseMessage(bufferedInputStream, requestType, numOfKeys);
    }

    public void write(byte[] outBuffer)
    {
        try {
            bufferedOutputStream.write(outBuffer);
            bufferedOutputStream.flush();
        } catch (IOException e) {
            System.out.println("Error can't sent message to server: " + targetIp);
        }

    }
}
