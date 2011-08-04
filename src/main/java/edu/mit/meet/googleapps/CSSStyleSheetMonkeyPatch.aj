import com.gargoylesoftware.htmlunit.BrowserVersion;
import com.gargoylesoftware.htmlunit.html.HtmlElement;
import com.gargoylesoftware.htmlunit.javascript.host.css.CSSStyleSheet;

import org.w3c.css.sac.Selector;

aspect CSSStyleSheetMonkeyPatch {
    pointcut selects(Selector s, HtmlElement e):
        execution(boolean CSSStyleSheet.selects(..)) && args(BrowserVersion, s, e);
    
    boolean around(Selector s, HtmlElement e): selects(s, e) {
        if (s.getSelectorType() == Selector.SAC_CHILD_SELECTOR && ! (e.getParentNode() instanceof HtmlElement)) {
            // XXX ClassCastException when HtmlUnit tries to cast parent to HtmlElement!
            return false;
        }
        return proceed(s, e);
    }
}
