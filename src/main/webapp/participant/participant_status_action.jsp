<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Action page for activate / deactivate / delete - no HTML,
    every path ends in a redirect. Reachable from list_participants.jsp
    (activate only) or confirm_participant_action.jsp (deactivate, delete).
    POST only, so a link or a refresh cannot change an account. The account
    status lives on the users row, and only participant accounts can be
    changed here - never staff.
    Deactivating keeps every record (nothing is deleted), so it can be undone.
    Deleting removes the users row; the foreign keys (ON DELETE CASCADE) also
    remove the participants row and all of their event_registrations.
    Either way require_participant.jsp logs the participant out on their
    next click.
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

    // Where the staff member was on the list (tab, search, page) - so they land back there.
    // filter is whitelisted, q is URL-encoded, p must be a whole number.
    String backFilter = request.getParameter("filter");
    if (backFilter == null || !(backFilter.equals("active") || backFilter.equals("inactive"))) { backFilter = "all"; }
    String backQ = util.Validator.clean(request.getParameter("q"));
    if (backQ.length() > 100) { backQ = backQ.substring(0, 100); }
    int backPage = util.Validator.parseId(request.getParameter("p"));
    if (backPage < 1) { backPage = 1; }
    String backPart = "filter=" + backFilter
            + (backQ.isEmpty() ? "" : "&q=" + java.net.URLEncoder.encode(backQ, "UTF-8"))
            + "&p=" + backPage;

    // Step 2: Validate
    int participantId = util.Validator.parseId(idParam);
    if (participantId < 0 || !(mode.equals("activate") || mode.equals("deactivate") || mode.equals("delete"))) {
        response.sendRedirect("list_participants.jsp?errCode=invalidAction&" + backPart);
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
            response.sendRedirect("list_participants.jsp?errCode=notFound&" + backPart);
            return;
        }
        if (mode.equals("delete")) {
            // Deleting the users row cascades to participants and event_registrations (FKs)
            String delSql = "DELETE u FROM users u JOIN participants p ON p.user_id = u.user_id "
                          + "WHERE p.participant_id = ? AND u.role = 'participant'";
            PreparedStatement delPs = conn.prepareStatement(delSql);
            delPs.setInt(1, participantId);
            delPs.executeUpdate();
            response.sendRedirect("list_participants.jsp?msg=participantDeleted&" + backPart);
            return;
        }
        if (newStatus.equals(findRs.getString("status"))) {
            response.sendRedirect("list_participants.jsp?errCode=" + (mode.equals("activate") ? "alreadyActive" : "alreadyInactive") + "&" + backPart);
            return;
        }

        String sql = "UPDATE users u JOIN participants p ON p.user_id = u.user_id "
                   + "SET u.status = ? WHERE p.participant_id = ? AND u.role = 'participant'";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, newStatus);
        ps.setInt(2, participantId);
        ps.executeUpdate();
        response.sendRedirect("list_participants.jsp?msg=" + (mode.equals("activate") ? "participantActivated" : "participantDeactivated") + "&" + backPart);
        return;
    } catch (Exception e) {
        System.err.println("participant_status_action.jsp - " + e);
        response.sendRedirect("list_participants.jsp?errCode=dbError&" + backPart);
        return;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>