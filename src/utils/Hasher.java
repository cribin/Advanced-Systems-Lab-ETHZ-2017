package utils;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * This class is responsible for hashing a given key(string) to the corresponding server id(int)
 */
public class Hasher {

    private static BigInteger intervalLimit = BigInteger.ONE.shiftLeft(128);

    private int numOfServers;

    public Hasher(int numOfServers)
    {
        this.numOfServers = numOfServers;
    }

    //This method uses interval hashing in order to determine the corresponding server given a key
    public int getServerId(String key) {

        MessageDigest m = null;
        try {
            m = MessageDigest.getInstance("MD5");
        } catch (NoSuchAlgorithmException e) {
            return 0;
        }

        m.reset();

        m.update(key.getBytes());

        byte[] digest = m.digest();

        BigInteger number = new BigInteger(1,digest);

        BigInteger interval = intervalLimit.divide(BigInteger.valueOf(numOfServers));

        int remainder = number.divide(interval).intValue();
        if(remainder>=numOfServers)
            remainder = numOfServers-1;
        return remainder;
    }
}
