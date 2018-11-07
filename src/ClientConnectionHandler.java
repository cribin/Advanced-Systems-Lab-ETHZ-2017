

import java.io.Closeable;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.Iterator;
import java.util.Set;
import java.util.concurrent.BlockingQueue;

/**
 * Represents the net thread of the project
 * Executes the following steps asynchronously during each iteration:
 * 1) Accepting incoming connections from clients
 * 2) Process incoming client request
 * 3) Enqueue full request into the clientHandler queue
 */
public class ClientConnectionHandler implements Runnable, Closeable{

    private BlockingQueue<ClientHandler> clientHandlerQueue;

    private ServerSocketChannel serverSocketChannel = null;

    private Selector selector;

    private boolean isRunning = true;


    public ClientConnectionHandler(String myIp, int myPort, BlockingQueue<ClientHandler> clientHandlerQueue)
    {
        this.clientHandlerQueue = clientHandlerQueue;

        try {
            serverSocketChannel = ServerSocketChannel.open();

            serverSocketChannel.socket().bind(new InetSocketAddress(myIp, myPort));

            //In non-blocking mode the accept method returns immediately
            serverSocketChannel.configureBlocking(false);
            //The selector is responsible for finding channels with data to read from
            selector = Selector.open();

        } catch (IOException e) {
            e.printStackTrace();
            System.out.println("Can't open TCP connection on the MW Net thread");
            stop();
        }

    }

    public void run(){

        while(isRunning)
        {
            try {
                acceptConnections();
                readFromConnections();
            } catch (IOException e) {
                e.printStackTrace();
                stop();
            }

        }
    }

    public void stop()
    {
        System.out.println("Closing Net thread");
        isRunning = false;
        try {
            selector.close();
            serverSocketChannel.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void acceptConnections() throws IOException {

        SocketChannel socketChannel = serverSocketChannel.accept();

        if(socketChannel != null)
        {
            ClientHandler clientHandler = new ClientHandler(socketChannel);
            socketChannel.configureBlocking(false);
            SelectionKey newRequestKey = socketChannel.register(selector, SelectionKey.OP_READ);
            newRequestKey.attach(clientHandler);
        }
    }

    private void readFromConnections() throws IOException {

        //returns the number of channels, from which we can read from
        int numOfReadyChannels = selector.selectNow();

        if(numOfReadyChannels > 0)
        {
            Set<SelectionKey> selectedKeys = selector.selectedKeys();
            Iterator<SelectionKey> keyIterator = selectedKeys.iterator();

            while(keyIterator.hasNext())
            {
                SelectionKey key = keyIterator.next();

                ClientHandler clientHandler = (ClientHandler)key.attachment();

                boolean isRequestComplete = clientHandler.readRequest();

                if(isRequestComplete)
                {
                    try {
                        //Logging data:TQueueIn
                        clientHandler.setRequestIn();
                        clientHandler.setQueueIn();
                        clientHandlerQueue.put(clientHandler);

                        //clientHandler.getClientRequest().logDataTracker.setQueueIn();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                        System.out.println("Error: Can't add clientHandler to the request queue");
                    }
                }

                keyIterator.remove();
            }
        }

    }

    @Override
    public void close() throws IOException {
        System.out.println("Closing Net thread");
        isRunning = false;
        try {
            //selector.close();
            serverSocketChannel.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
