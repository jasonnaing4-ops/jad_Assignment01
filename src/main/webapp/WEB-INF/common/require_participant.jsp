<%@ page import="java.sql.*" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Login guard + participant-role guard for the participant's own
    pages (account/). Same idea as require_staff.jsp. Include this as the VERY
    FIRST thing in the file, before any other scriptlet code and before any HTML:

        <%@ include file="/WEB-INF/common/require_participant.jsp" %>

    - No userId in the session: back to login.jsp. If the browser sent a
      session id the server no longer knows, the session timed out, so the
      message says "session expired" instead of "please log in".
    - Re-looks-up role AND status from the DB by userId (only userId is ever
      trusted out of the session). A staff user goes to home.jsp
      (notAuthorized). If staff deactivated this account after the participant
      logged in, the session is ended straight away (accountInactive).
    - If the user row no longer exists (staff deleted the participant while
      they were logged in) or the database cannot be reached, the session is
      ended and the user goes to login.jsp (notLoggedIn / dbError) - never
      bounced on to require_staff.jsp, which would loop back here.
    - Protected pages are marked "no-store", so Back after logout cannot show
      a cached copy.

    - Forced password change: while users.must_change_password = 1 (a staff-
      created account still on its demo password) every participant page
      redirects to account/change_password.jsp. Only that page and its decision
      page save_password.jsp are let through, so typing another page's URL
      cannot skip the change.

    Leaves these local variables behind for the rest of the page to reuse:
      userId     (Integer) - the signed-in user's id
      jdbcDriver, connURL  - from dbconfig.jsp, already included here

    A page that includes this file must NOT also include dbconfig.jsp.
--%>
<%
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        boolean guardExpired = request.getRequestedSessionId() != null && !request.isRequestedSessionIdValid();
        response.sendRedirect(request.getContextPath() + "/login/login.jsp?errCode="
                + (guardExpired ? "sessionExpired" : "notLoggedIn"));
        return;
    }
%>
<%@ include file="/WEB-INF/common/dbconfig.jsp" %>
<%
    String guardRole = null;
    String guardStatus = null;
    boolean guardMustChange = false;
    boolean guardDbFailed = false;
    Connection guardConn = null;
    try {
        Class.forName(jdbcDriver);
        guardConn = DriverManager.getConnection(connURL);
        String guardSql = "SELECT role, status, must_change_password FROM users WHERE user_id = ?";
        PreparedStatement guardPs = guardConn.prepareStatement(guardSql);
        guardPs.setInt(1, userId);
        ResultSet guardRs = guardPs.executeQuery();
        if (guardRs.next()) {
            guardRole = guardRs.getString("role");
            guardStatus = guardRs.getString("status");
            guardMustChange = guardRs.getBoolean("must_change_password");
        }
    } catch (Exception e) {
        System.err.println("require_participant.jsp - " + e);
        guardDbFailed = true;
    } finally {
        if (guardConn != null) {
            try { guardConn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }

    // No user row (the account was deleted while logged in) or the database could
    // not be reached: end the session and go to login. Without this, a null role
    // would bounce between this guard and require_staff.jsp ("too many redirects").
    if (guardRole == null) {
        session.invalidate();
        response.sendRedirect(request.getContextPath() + "/login/login.jsp?errCode="
                + (guardDbFailed ? "dbError" : "notLoggedIn"));
        return;
    }

    if ("participant".equals(guardRole) && !"active".equals(guardStatus)) {
        session.invalidate();
        response.sendRedirect(request.getContextPath() + "/login/login.jsp?errCode=accountInactive");
        return;
    }
    if (!"participant".equals(guardRole)) {
        response.sendRedirect(request.getContextPath() + "/event/list_events.jsp");
        return;
    }

    // Still on a demo password: only the change-password pages may be used
    String guardPath = request.getServletPath();
    boolean guardOnPasswordPage = guardPath.equals("/account/change_password.jsp")
                               || guardPath.equals("/account/save_password.jsp");
    if (guardMustChange && !guardOnPasswordPage) {
        response.sendRedirect(request.getContextPath() + "/account/change_password.jsp");
        return;
    }

    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
%>