<%@ page import="java.sql.*" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Combined login guard (section 2.5) + staff-role guard, for
    every event-management page. Include this as the VERY FIRST thing in the
    file, before any other scriptlet code and before any HTML:

        <%@ include file="/WEB-INF/common/require_staff.jsp" %>

    - If there is no userId in the session, redirects to login.jsp (section 2.5).
    - Otherwise re-looks-up the role from the DB by userId (never trusts
      anything other than userId out of the session) and redirects to
      home.jsp if the signed-in user is not staff.

    Leaves these local variables behind for the rest of the page to reuse:
      userId     (Integer) - the signed-in user's id
      jdbcDriver, connURL  - from dbconfig.jsp, already included here

    Because dbconfig.jsp is already included by this file, a page that
    includes require_staff.jsp must NOT also include dbconfig.jsp itself.
--%>
<%
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        response.sendRedirect(request.getContextPath() + "/login/login.jsp?errCode=notLoggedIn");
        return;
    }
%>
<%@ include file="/WEB-INF/common/dbconfig.jsp" %>
<%
    boolean isStaff = false;
    Connection guardConn = null;
    try {
        Class.forName(jdbcDriver);
        guardConn = DriverManager.getConnection(connURL);
        String guardSql = "SELECT role FROM users WHERE user_id = ?";
        PreparedStatement guardPs = guardConn.prepareStatement(guardSql);
        guardPs.setInt(1, userId);
        ResultSet guardRs = guardPs.executeQuery();
        if (guardRs.next() && "staff".equals(guardRs.getString("role"))) {
            isStaff = true;
        }
    } catch (Exception e) {
        System.err.println("require_staff.jsp - " + e);
    } finally {
        if (guardConn != null) {
            try { guardConn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
    if (!isStaff) {
        response.sendRedirect(request.getContextPath() + "/home/home.jsp?errCode=notAuthorized");
        return;
    }
%>
