<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: One shared place for the JDBC driver class and connection URL
    (open item #2 in the coding conventions doc - "consider one shared include
    so there's one place to change it"). Include with:

        <%@ include file="/WEB-INF/common/dbconfig.jsp" %>

    inside a page's OWN scriptlet, immediately before its own try block.
    jdbcDriver/connURL become ordinary local variables in whatever page
    includes this - never class-level fields - so this is safe to include
    on as many pages as you like.

    Include it ONCE per page, before require_staff.jsp and header.jsp (both
    use jdbcDriver/connURL from here and do not include this file
    themselves). It is the only place the DB credentials live.

    Edit the username/password below to match your own MySQL setup before
    running this locally.
--%>
<%
    String jdbcDriver = "com.mysql.cj.jdbc.Driver";
    String connURL = util.DbConfig.getConnURL(application);
%>
