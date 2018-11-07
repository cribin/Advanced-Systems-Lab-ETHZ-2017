package utils;

import java.util.logging.Formatter;
import java.util.logging.LogRecord;

/**
 * Formatter class used by the MyLogger class.
 */
public class BriefFormatter  extends Formatter
{
    public BriefFormatter() { super(); }

    @Override
    public String format(final LogRecord record)
    {
        return record.getMessage()+"\n";
    }
}
