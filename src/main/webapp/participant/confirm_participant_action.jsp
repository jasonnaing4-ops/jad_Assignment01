<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Confirm step before a participant's account is deactivated
    (section 3.2: deactivate only after a clear confirmation step; section 7
    list -> confirm -> action -> redirect pattern, same as
    event/confirm_event_action.jsp). Reached only by the small POST form on
    list_participants.jsp. Looks the participant up, shows who it is and how
    many upcoming sign-ups they have, then a locked form that posts on to
    participant_status_action.jsp. Nothing changes until Yes is pressed.
--%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>
<%
    // Step 1: Existence
    String idParam = request.getParameter("id");
    String mode = request.getParameter("mode");
    if (idParam == null || mode == null) {
        response.sendRedirect("list_participants.jsp");
        return;
    }

    // Step 2: Validate
    int participantId = util.Validator.parseId(idParam);
    if (participantId < 0 || !mode.equals("deactivate")) {
        response.sendRedirect("list_participants.jsp?errCode=invalidAction");
        return;
    }

    // Step 3: Process - look the participant up
    String name = null, code = null, email = null, status = null;
    int upcomingCount = 0;
    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        String sql = "SELECT p.full_name, p.participant_code, p.email, u.status "
                   + "FROM participants p JOIN users u ON u.user_id = p.user_id WHERE p.participant_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, participantId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            name = rs.getString("full_name");
            code = rs.getString("participant_code");
            email = rs.getString("email");
            status = rs.getString("status");
        } else {
            response.sendRedirect("list_participants.jsp?errCode=notFound");
            return;
        }

        String countSql = "SELECT COUNT(*) AS cnt FROM event_registrations r JOIN events e ON e.event_id = r.event_id "
                        + "WHERE r.participant_id = ? AND r.status = 'registered' AND e.event_date >= CURDATE()";
        PreparedStatement countPs = conn.prepareStatement(countSql);
        countPs.setInt(1, participantId);
        ResultSet countRs = countPs.executeQuery();
        if (countRs.next()) {
            upcomingCount = countRs.getInt("cnt");
        }
    } catch (Exception e) {
        System.err.println("confirm_participant_action.jsp - " + e);
        response.sendRedirect("list_participants.jsp?errCode=dbError");
        return;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }

    if (!"active".equals(status)) {
        response.sendRedirect("list_participants.jsp?errCode=alreadyInactive");
        return;
    }
%>
<%@ include file="/WEB-INF/common/header.jsp" %>

<h1 class="h2 text-primary mb-4">Confirm Deactivate Participant</h1>

<div style="max-width: 640px;">
    <dl class="row">
        <dt class="col-sm-4 text-muted fw-normal">Name</dt><dd class="col-sm-8 fw-semibold"><%= esc(name) %></dd>
        <dt class="col-sm-4 text-muted fw-normal">Participant code</dt><dd class="col-sm-8"><%= esc(code) %></dd>
        <dt class="col-sm-4 text-muted fw-normal">Email</dt><dd class="col-sm-8"><%= esc(email) %></dd>
        <dt class="col-sm-4 text-muted fw-normal">Upcoming sign-ups</dt><dd class="col-sm-8"><%= upcomingCount %> event(s)</dd>
    </dl>

    <div class="alert alert-warning">
        <%= esc(name) %> will no longer be able to log in. Their details and sign-ups are kept,
        and you can activate the account again at any time from the participant list.
    </div>

    <p>Are you sure you want to deactivate this account?</p>
    <form method="post" action="participant_status_action.jsp">
        <input type="hidden" name="id" value="<%= participantId %>">
        <input type="hidden" name="mode" value="deactivate">
        <button type="submit" class="btn btn-danger">Yes, Deactivate</button>
    </form>
    <a href="list_participants.jsp" class="btn btn-link text-secondary text-decoration-none px-0 mt-2">Cancel</a>
</div>

<%@ include file="/WEB-INF/common/footer.jsp" %>
