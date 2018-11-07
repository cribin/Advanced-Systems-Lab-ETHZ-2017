package message;

import java.nio.ByteBuffer;
import java.util.Arrays;

/**
 * Base class for all message types (requests and responses)
 * It stores the message content as a byte array
 */
public abstract class MemcachedMessage {

    protected byte[] messageContent;
    protected int messageContentLength;

    public byte[] getMessageContent() {
        return messageContent;
    }

    public void setMessageContent(byte[] messageContent, int messageLength) {

        this.messageContent = Arrays.copyOf(messageContent, messageLength);
    }

    public void setMessageContent(ByteBuffer byteBuffer, int totalBytesRead) {

        messageContent = new byte[totalBytesRead];
        byteBuffer.get(messageContent, 0, messageContent.length);
    }

    public void setMessageContent(String messageContent) {

        this.messageContent = messageContent.getBytes();
    }

    public void setMessageContentLength(int messageContentLength)
    {
        this.messageContentLength = messageContentLength;
    }


    public int getMessageContentLength()
    {
        return messageContentLength;
    }




}
