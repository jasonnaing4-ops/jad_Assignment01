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

    IMPORTANT: common/require_staff.jsp already includes this file. A page
    that includes require_staff.jsp must NOT include dbconfig.jsp again -
    that would try to declare jdbcDriver/connURL twice in the same method and
    fail to compile. Just reuse the jdbcDriver/connURL that require_staff.jsp
    already brought in.

    Edit the username/password below to match your own MySQL setup before
    running this locally.
--%>
<%
    String jdbcDriver = "com.mysql.cj.jdbc.Driver";
    String connURL = "jdbc:mysql://localhost:3306/jad_assignment01_database?user=root&password=jason1224&serverTimezone=UTC";
%>
