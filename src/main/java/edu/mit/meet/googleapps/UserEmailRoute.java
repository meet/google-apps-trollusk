package edu.mit.meet.googleapps;

/**
 * A single user-level email route.
 */
public class UserEmailRoute {
    
    /**
     * Destination email address.
     */
    public final String destination;
    /**
     * Will the <code>to</code> address be rewritten?
     */
    public final boolean rewriteTo;
    /**
     * Is this route enabled?
     */
    public final boolean enabled;
    
    UserEmailRoute(final String destination, final boolean rewriteTo, final boolean enabled) {
        if (destination == null) { throw new IllegalArgumentException("Destination cannot be null"); }
        
        this.destination = destination;
        this.rewriteTo = rewriteTo;
        this.enabled = enabled;
    }
    
    @Override public String toString() {
        return getClass().getSimpleName() + "<" + destination + "," + (rewriteTo ? "rewrite" : "-") + "," + enabled + ">";
    }
}
