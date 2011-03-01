package edu.mit.meet.googleapps;

import java.io.BufferedReader;
import java.io.InputStreamReader;

import org.apache.commons.logging.LogFactory;

/**
 * Main class designed to be driven programmatically via stdin and stdout.
 */
public class UserEmailRoutingMain {
    
    enum Action { inbox, get, add, update, remove, only }
    
    public static void main(String[] args) throws Exception {
        final BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
        
        final String domain = args[0];
        final String username = args[1];
        
        System.out.println("password");
        final String password = in.readLine();
        
        LogFactory.getFactory().setAttribute("org.apache.commons.logging.Log", "org.apache.commons.logging.impl.NoOpLog");
        
        final UserEmailRoutingConnection conn = new UserEmailRoutingConnection(domain, username, new String(password));
        System.out.println("ok");
        
        String input;
        while ((input = in.readLine()) != null) {
            try {
                final String[] params = input.split("\\s+");
                UserEmailRouting user = conn.find(params[0]);
                switch (Action.valueOf(params[1])) {
                case inbox:
                    user = user.deliverToInbox(Boolean.parseBoolean(params[2]));
                    break;
                case add:
                    user = user.add(params[2], true);
                    break;
                case update:
                    user = user.update(params[2], params[3]);
                    break;
                case remove:
                    user = user.remove(params[2]);
                    break;
                case only:
                    final boolean inbox = params[2].equals("inbox");
                    boolean missing = true;
                    for (UserEmailRoute route : user.routes) {
                        if (route.destination.equals(params[2])) {
                            missing = false;
                        }
                    }
                    if (( ! inbox) && missing) {
                        user = user.add(params[2], true);
                    }
                    for (UserEmailRoute route : user.routes) {
                        if ( ! route.destination.equals(params[2])) {
                            user = user.remove(route.destination);
                        }
                    }
                    user = user.deliverToInbox(inbox);
                    break;
                }
                System.out.println(user);
            } catch (Exception e) {
                System.out.println("Exception:" + e.toString());
                e.printStackTrace();
            }
        }
    }
}
