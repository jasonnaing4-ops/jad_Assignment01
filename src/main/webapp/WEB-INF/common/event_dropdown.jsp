<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Reusable <option> list of active events, for any <select>
    that needs to associate something with an event (e.g. participant
    sign-up). Include it INSIDE your own <select> tags:

        <select name="eventId">
            <option value="">-- Select an event --</option>
            <%@ include file="/WEB-INF/common/event_dropdown.jsp" %>
        </select>

    Requirements for the including page:
      - Must already have esc() available, i.e. must already have included
        /WEB-INF/common/header.jsp (or /WEB-INF/common/esc.jsp directly)
        BEFORE this include. Do not include esc.jsp a second time here - it
        would redeclare the method and fail to compile.
      - Must NOT already have local variables named ddConn/ddStmt/ddRs/ddSql/
        ddConnURL/ddDriver in scope at this point (this file uses dd-prefixed
        names, and its OWN copy of the driver/connection string, precisely so
        it is safe to drop into a page that already declared jdbcDriver/connURL
        itself via dbconfig.jsp - it never includes dbconfig.jsp, to avoid a
        duplicate-variable compile error on pages that already did).

    If you change the DB credentials in common/dbconfig.jsp, update the copy
    below too (small, deliberate duplication - this file has to be safe to
    drop into ANY page, including ones that already included dbconfig.jsp).

    The query has no user input in it (status = 'active' is a hard-coded
    literal), so a plain Statement is acceptable here per section 6 of the
    coding conventions.
--%>
<%@ page import="java.sql.*" %>
<%
    Connection ddConn = null;
    try {
        String ddDriver = "com.mysql.cj.jdbc.Driver";
        String ddConnURL = "jdbc:mysql://localhost:3306/jad_assignment01_database?user=root&password=root&serverTimezone=UTC";
        Class.forName(ddDriver);
        ddConn = DriverManager.getConnection(ddConnURL);
        String ddSql = "SELECT event_id, event_name, event_date FROM events "
                     + "WHERE status = 'active' ORDER BY event_date";
        Statement ddStmt = ddConn.createStatement();
        ResultSet ddRs = ddStmt.executeQuery(ddSql);
        while (ddRs.next()) {
%>
            <option value="<%= ddRs.getInt("event_id") %>"><%= esc(ddRs.getString("event_name")) %> (<%= ddRs.getDate("event_date") %>)</option>
<%
        }
    } catch (Exception e) {
        System.err.println("event_dropdown.jsp - " + e);
%>
        <option value="" disabled>-- events unavailable, try again later --</option>
<%
    } finally {
        if (ddConn != null) {
            try { ddConn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>
