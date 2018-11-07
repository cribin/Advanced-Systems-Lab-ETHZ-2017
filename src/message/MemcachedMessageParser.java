package message;

import utils.Constants;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.nio.ByteBuffer;

/**
 * Main class for parsing incoming requests and responses
 * Using the memcache protocol this class reads a complete requests from the client or the response from the server.
 */
public class MemcachedMessageParser {

    public MemcachedMessageParser()
    {

    }

    /**
     *
     * @param memcachedRequest
     * This method parses the incoming incoming request and sets the corresponding values of the request
     */
    public void parseRequestMessage(MemcachedRequest memcachedRequest)
    {
        if(memcachedRequest.isRequestComplete())
            return;

        int totalBytesRead = memcachedRequest.getTotalBytesRead();
        ByteBuffer byteBuffer = memcachedRequest.getRequestBuffer();

        MemcachedRequest.RequestType requestType = memcachedRequest.getRequestType();

        int bufferPos = byteBuffer.position();

        int headerLength = memcachedRequest.getHeaderLength();
        int bodyLength = memcachedRequest.getBodySize();

        if(!memcachedRequest.isHeaderRead())
        {
           char firstChar = (char) byteBuffer.get(0);
           if(requestType == MemcachedRequest.RequestType.UNKNOWN)
           {
               if(firstChar == 's')
                   requestType = MemcachedRequest.RequestType.SET;
           }

           int currBufferPos = 0;
           int passedWhiteSpaces = 0;
           StringBuilder bodySize = new StringBuilder();
           StringBuilder keys = new StringBuilder();

           while (currBufferPos < bufferPos)
           {
               char c = (char)byteBuffer.get(currBufferPos);

               currBufferPos++;

               if(c == ' ')
               {
                   passedWhiteSpaces++;
                   if(requestType != MemcachedRequest.RequestType.SET && passedWhiteSpaces > 1)
                       keys.append(c);
                   else
                       continue;
               }


               //We have finished reading the header
               if(c == '\n')
               {
                   headerLength = currBufferPos;
                   memcachedRequest.setHeaderLength(headerLength);

                   if(requestType == MemcachedRequest.RequestType.UNKNOWN && firstChar == 'g')
                   {
                       if(passedWhiteSpaces == 1)
                       {
                           requestType = MemcachedRequest.RequestType.GET;
                           memcachedRequest.setRequestComplete(true);
                           memcachedRequest.setKeys(keys.toString());
                       }
                       else if(passedWhiteSpaces > 1)
                       {
                           requestType = MemcachedRequest.RequestType.MULTI_GET;
                           memcachedRequest.setRequestComplete(true);
                           memcachedRequest.setKeys(keys.toString());
                       }
                   }else if(requestType == MemcachedRequest.RequestType.SET)
                   {
                       bodyLength = Integer.parseInt(bodySize.toString());
                       memcachedRequest.setBodySize(bodyLength);
                   }

                   memcachedRequest.setHeaderRead(true);
                   memcachedRequest.setRequestType(requestType);
                   break;
               }

               //If 4 spaces has been passed in a set request, we can read the bodySize of the message
               if(requestType == MemcachedRequest.RequestType.SET)
               {
                   if (passedWhiteSpaces == 4 && c != '\r')
                       bodySize.append(c);
               }else if(passedWhiteSpaces > 0 && c != '\r')
               {
                   keys.append(c);
               }

           }

        }

        if(requestType == MemcachedRequest.RequestType.SET && totalBytesRead == (headerLength + bodyLength + 2))
        {
            memcachedRequest.setRequestComplete(true);
        }

    }

    /**
     *
     * @param bufferedInputStream: Stream which receives data
     * @param requestType: The type of the request, this response corresponds to
     * @param numOfKeys : Indicates how many keys were contained in the request message
     * @return: The received response message, with it's corresponding data
     */
    public MemcachedResponse parseResponseMessage(BufferedInputStream bufferedInputStream, MemcachedRequest.RequestType requestType, int numOfKeys)
    {
        MemcachedResponse memcachedResponse = new MemcachedResponse();

        int bytesRead;
        int bytesTotalRead = 0;

        if(requestType == MemcachedRequest.RequestType.SET || requestType == MemcachedRequest.RequestType.GET)
            memcachedResponse.messageContent = new byte[Constants.MAX_BUFFER_SIZE];
        else if(requestType == MemcachedRequest.RequestType.MULTI_GET)
            memcachedResponse.messageContent = new byte[numOfKeys * Constants.MAX_BUFFER_SIZE];
        else
        {
            System.out.println("Error: Unknown Request Type");
            return null;
        }


        try
        {
            while((bytesRead = bufferedInputStream.read(memcachedResponse.messageContent, bytesTotalRead, memcachedResponse.messageContent.length - bytesTotalRead)) >= 0)
            {
                bytesTotalRead += bytesRead;

                if(bytesTotalRead > 4)
                {
                    if (requestType == MemcachedRequest.RequestType.SET)
                    {
                        if (memcachedResponse.messageContent[bytesTotalRead - 2] == '\r' && memcachedResponse.messageContent[bytesTotalRead - 1] == '\n')
                        {
                            memcachedResponse.setMessageContentLength(bytesTotalRead);
                            if(memcachedResponse.messageContent[0] == 'S' && memcachedResponse.messageContent[1] == 'T')
                                memcachedResponse.setResponseFlag(MemcachedResponse.ResponseFlag.SUCCESS);
                            else
                                memcachedResponse.setResponseFlag(MemcachedResponse.ResponseFlag.ERROR);

                            break;
                        }

                    }else
                    {
                        if (memcachedResponse.messageContent[bytesTotalRead - 5] == 'E' && memcachedResponse.messageContent[bytesTotalRead - 4] == 'N' && memcachedResponse.messageContent[bytesTotalRead - 3] == 'D')
                        {
                            long bufferCopyStart = System.nanoTime();
                            memcachedResponse.setMessageContentLength(bytesTotalRead);
                            memcachedResponse.setResponseFlag(MemcachedResponse.ResponseFlag.SUCCESS);
                            long bufferCopyEnd = System.nanoTime();
                            memcachedResponse.setBufferCopyTime(bufferCopyEnd - bufferCopyStart);
                            break;
                        }
                    }
                }

            }

        } catch (IOException e) {

            e.printStackTrace();
        }

        return memcachedResponse;
    }
}
