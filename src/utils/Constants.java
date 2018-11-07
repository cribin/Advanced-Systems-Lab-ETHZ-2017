package utils;

/**
 * Utility class, which stores commonly used constants
 */
public final class Constants {

    public static final int MAX_BUFFER_SIZE = 2048;

    public static final int MAX_NUM_OF_KEYS = 10;

    public static double VALUE_SIZE = 1024;

    public static final String getResponseTag = "VALUE";

    public static final int RESP_HIST_SIZE = 100;


    private Constants(){
        //this prevents even the native class from
        //calling this ctor as well :
        throw new AssertionError();
    }
}
