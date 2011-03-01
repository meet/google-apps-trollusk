package edu.mit.meet.googleapps;

import java.io.IOException;
import java.util.*;

import com.gargoylesoftware.htmlunit.ElementNotFoundException;
import com.gargoylesoftware.htmlunit.html.*;

/**
 * Email routing settings for a single user.
 */
public class UserEmailRouting {
    
    /**
     * User's username.
     */
    public final String username;
    /**
     * Will mail be delivered to the user's Google Apps inbox?
     */
    public final boolean deliverToInbox;
    /**
     * Will mail be routed to additional domain-level destinations?
     */
    public final boolean inheritRoutes;
    /**
     * User-level routing destinations.
     */
    public final List<UserEmailRoute> routes;
    
    private final HtmlPage page;
    
    UserEmailRouting(final String username, final HtmlPage page) throws IOException {
        this.username = username;
        page.getWebClient().waitForBackgroundJavaScriptStartingBefore(10000);
        this.page = page;
        
        final HtmlElement error = routeErrorElt();
        if (error != null) {
            throw new PageError(error.getTextContent());
        }
        
        this.deliverToInbox = deliverToInboxElt().isChecked();
        this.inheritRoutes = inheritRoutesElt().isChecked();
        final List<UserEmailRoute> routes = new ArrayList<UserEmailRoute>();
        try {
            for (int idx = 1; true; idx++) {
                routes.add(new UserEmailRoute(routeDestinationElt(idx).getText(),
                                              routeRewriteToElt(idx).isChecked(),
                                              routeEnabledElt(idx).isChecked()));
            }
        } catch (ElementNotFoundException enfe) { }
        this.routes = Collections.unmodifiableList(routes);
    }
    
    /**
     * Set whether mail will be delivered to the user's Google Apps inbox.
     */
    public UserEmailRouting deliverToInbox(final boolean deliverToInbox) throws IOException {
        if (this.deliverToInbox != deliverToInbox) {
            deliverToInboxElt().click();
            return saveChanges();
        }
        return this;
    }
    
    /**
     * Add a user-level routing destination.
     */
    public UserEmailRouting add(final String destination, final boolean rewriteEnvelopeTo) throws IOException {
        if (destination == null) { throw new IllegalArgumentException("Destination cannot be null"); }
        
        final int idx = routes.size() + 1;
        addDestinationElt().click();
        final HtmlTextInput destinationInput = routeDestinationElt(idx);
        if ( ! destinationInput.getText().isEmpty()) {
            throw new IOException("Expected to find empty destination input at index " + idx);
        }
        destinationInput.type(destination);
        final HtmlCheckBoxInput rewriteInput = routeRewriteToElt(idx);
        if (rewriteInput.isChecked() != rewriteEnvelopeTo) {
            rewriteInput.click();
        }
        return saveChanges();
    }
    
    /**
     * Remove a user-level routing destination.
     */
    public UserEmailRouting remove(final String destination) throws IOException {
        if (destination == null) { throw new IllegalArgumentException("Destination cannot be null"); }
        
        removeDestinationElt(routeDestinationElt(destination)).click();
        return saveChanges();
    }
    
    /**
     * Update a user-level routing destination.
     */
    public UserEmailRouting update(final String oldDestination, final String newDestination) throws IOException {
        if (oldDestination == null) { throw new IllegalArgumentException("Old destination cannot be null"); }
        if (newDestination == null) { throw new IllegalArgumentException("New destination cannot be null"); }
        
        final HtmlTextInput textbox = routeDestinationElt(oldDestination);
        textbox.select();
        textbox.type(newDestination);
        textbox.blur();
        return saveChanges();
    }
    
    // Finding elements of interest
    
    private HtmlCheckBoxInput deliverToInboxElt() {
        return page.getElementByName("googleAppsEmailEnabled");
    }
    
    private HtmlCheckBoxInput inheritRoutesElt() {
        return page.getElementByName("inheritRoutesEnabled");
    }
    
    private HtmlTextInput routeDestinationElt(String destination) throws IOException {
        for (int idx = 1; idx <= routes.size(); idx++) {
            if (routes.get(idx-1).destination.equals(destination)) {
                final HtmlTextInput textbox = routeDestinationElt(idx);
                if ( ! textbox.getText().equals(destination)) {
                    throw new IOException("Expected to find destination in input at index " + idx);
                }
                return textbox;
            }
        }
        throw new IllegalArgumentException("No such destination " + destination);
    }
    
    private HtmlTextInput routeDestinationElt(int idx) {
        return page.getElementByName("routeDestination" + idx);
    }
    
    private HtmlCheckBoxInput routeRewriteToElt(int idx) {
        return page.getElementByName("routeRewriteTo" + idx);
    }
    
    private HtmlCheckBoxInput routeEnabledElt(int idx) {
        return page.getElementByName("routeEnabled" + idx);
    }
    
    private HtmlElement addDestinationElt() {
        return page.getFirstByXPath("//div[.='Email routing']/ancestor::tr[1]//div[.='Add another destination']");
    }
    
    private HtmlElement removeDestinationElt(HtmlTextInput routeDestinationElt) {
        return page.getFirstByXPath("//input[@name='" + routeDestinationElt.getNameAttribute() + "']/ancestor::tr[1]//div[.='Remove']");
    }
    
    private HtmlElement routeErrorElt() {
        return page.getFirstByXPath("//div[.='Email routing']/ancestor::tr[1]//div[contains(@class, 'errormsg') and normalize-space()!='']");
    }
    
    private UserEmailRouting saveChanges() throws IOException {
        final HtmlElement save = page.getFirstByXPath("//div[contains(@class, 'pendingPanel')]//div[.='Save changes']");
        return new UserEmailRouting(username, (HtmlPage)save.click());
    }
    
    @Override public String toString() {
        return getClass().getSimpleName() + "<" +
            username + ":" +
            (deliverToInbox ? "inbox" : "-") + "," +
            (inheritRoutes ? "inherit" : "-") + "," +
            routes + ">";
    }
    
    public static class PageError extends IOException {
        private static final long serialVersionUID = 1L;
        PageError(final String message) {
            super(message);
        }
    }
}
