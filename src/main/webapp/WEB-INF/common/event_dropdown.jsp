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
        ddConnURL/ddDriver in scope at this point 
--%>
<%@ page import="java.sql.*" %>
<%
	//Active Events Query & Option Rendering: fetch active events ordered by date and output HTML <option> tags
    Connection ddConn = null;
    try {
        String ddDriver = "com.mysql.cj.jdbc.Driver";
        String ddConnURL = util.DbConfig.getConnURL(application);        
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
    	// Error Fallback & Cleanup: render disabled placeholder option on DB failure and close connection
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
