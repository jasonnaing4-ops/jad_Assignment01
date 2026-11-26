
//<%--
//    Author: Pyae Phyo Maung (P2535128)
//    Date: 22/11/2026
//Description: Global Servlet Filter that disables browser caching across all routes
//so protected pages cannot be viewed via the Back button after logout.
// 
//--%>


package Filter;

import jakarta.servlet.Filter; 
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;


//Filter Registration: intercept every incoming request URL across the application
@WebFilter("/*")
public class NoCacheFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
    	// Cache-Control Headers: instruct browsers not to store or reuse cached page snapshots
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        httpResponse.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
        httpResponse.setHeader("Pragma", "no-cache");
        httpResponse.setDateHeader("Expires", 0);

     // Request Forwarding: pass the request and response along to the target servlet or JSP
        chain.doFilter(request, response);
    }
}