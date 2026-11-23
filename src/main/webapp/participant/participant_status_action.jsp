<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Action page for activate / deactivate - no HTML, every path
    ends in a redirect. Reachable from list_participants.jsp (activate only)
    or confirm_participant_action.jsp (deactivate). POST only, so a link or a
    refresh cannot change an account. The account status lives on the users
    row, and only participant accounts can be changed here - never staff.
    Deactivating keeps every record (nothing is deleted), so it can be undone,
    and require_participant.jsp logs the participant out on their next click.
--%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>
<%
    // Step 1: Existence
    String idParam = request.getParameter("id");
    String mode = request.getParameter("mode");
    if (!"POST".equalsIgnoreCase(request.getMethod()) || idParam == null || mode == null) {
        response.sendRedirect("list_participants.jsp");
        return;
    }

    // Step 2: Validate
    int participantId = util.Validator.parseId(idParam);
    if (participantId < 0 || (!mode.equals("activate") && !mode.equals("deactivate"))) {
        response.sendRedirect("list_participants.jsp?errCode=invalidAction");
        return;
    }
    String newStatus = mode.equals("activate") ? "active" : "inactive";

    // Step 3: Process
    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        String findSql = "SELECT u.status FROM participants p JOIN users u ON u.user_id = p.user_id "
                       + "WHERE p.participant_id = ? AND u.role = 'participant'";
        PreparedStatement findPs = conn.prepareStatement(findSql);
        findPs.setInt(1, participantId);
        ResultSet findRs = findPs.executeQuery();
        if (!findRs.next()) {
            response.sendRedirect("list_participants.jsp?errCode=notFound");
            return;
        }
        if (newStatus.equals(findRs.getString("status"))) {
            response.sendRedirect("list_participants.jsp?errCode=" + (mode.equals("activate") ? "alreadyActive" : "alreadyInactive"));
            return;
        }

        String sql = "UPDATE users u JOIN participants p ON p.user_id = u.user_id "
                   + "SET u.status = ? WHERE p.participant_id = ? AND u.role = 'participant'";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, newStatus);
        ps.setInt(2, participantId);
        ps.executeUpdate();
        response.sendRedirect("list_participants.jsp?msg=" + (mode.equals("activate") ? "participantActivated" : "participantDeactivated"));
        return;
    } catch (Exception e) {
        System.err.println("participant_status_action.jsp - " + e);
        response.sendRedirect("list_participants.jsp?errCode=dbError");
        return;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>