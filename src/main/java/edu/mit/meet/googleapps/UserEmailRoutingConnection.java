package edu.mit.meet.googleapps;

import java.io.IOException;

import com.gargoylesoftware.htmlunit.*;
import com.gargoylesoftware.htmlunit.html.HtmlForm;
import com.gargoylesoftware.htmlunit.html.HtmlPage;

/**
 * Email routing.
 */
public class UserEmailRoutingConnection {
    
    /**
     * Google Apps control panel location.
     */
    public static final String CPANEL = "https://www.google.com/a/cpanel/";
    
    /**
     * Google Apps domain.
     */
    public final String domain;
    
    private final WebClient web = new WebClient();
    
    /**
     * Connect to the email routing control panel.
     */
    public UserEmailRoutingConnection(final String domain, final String username, final String password) throws IOException {
        if (domain == null) { throw new IllegalArgumentException("Domain cannot be null"); }
        if (username == null) { throw new IllegalArgumentException("Username cannot be null"); }
        if (password == null) { throw new IllegalArgumentException("Password cannot be null"); }
        
        this.domain = domain;
        web.setRedirectEnabled(true);
        web.setPopupBlockerEnabled(true);
        web.setIncorrectnessListener(new IncorrectnessListener() {
            public void notify(String message, Object origin) { }
        });
        web.setCssErrorHandler(new SilentCssErrorHandler());
        
        final HtmlPage dashboard = login(CPANEL + domain, username, password);
        if ( ! dashboard.getUrl().toString().equals(CPANEL + domain + "/Dashboard")) {
            throw new IOException("Expected dashboard, got " + dashboard.getUrl());
        }
    }
    
    /**
     * Find email routing settings for the given user.
     */
    public UserEmailRouting find(final String username) throws IOException {
        final HtmlPage user = web.getPage(CPANEL + domain + "/Organization?userEmail=" + username + "@" + domain);
        return new UserEmailRouting(username, user);
    }
    
    private HtmlPage login(final String destination, final String username, final String password) throws IOException {
        final HtmlPage login = web.getPage(destination);
        for (HtmlForm form : login.getForms()) {
            try {
                form.getInputByName("Email").type(username);
                form.getInputByName("Passwd").type(password);
            } catch (ElementNotFoundException enfe) {
                continue;
            }
            return form.getInputByName("signIn").click();
        }
        throw new IOException("No login form found");
    }
        
}
