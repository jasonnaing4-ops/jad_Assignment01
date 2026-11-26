<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Confirm step before a participant's account is deactivated
    or deleted (section 3.2: deactivate only after a clear confirmation step;
    section 7 list -> confirm -> action -> redirect pattern, same as
    event/confirm_event_action.jsp). Reached only by the small POST forms on
    list_participants.jsp. Looks the participant up, shows who it is and how
    many sign-ups they have, then a locked form that posts on to
    participant_status_action.jsp. Nothing changes until Yes is pressed.
    Delete is allowed for active and inactive participants alike, and warns
    that it is permanent.
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
    boolean isDelete = mode.equals("delete");
    if (participantId < 0 || !(mode.equals("deactivate") || isDelete)) {
        response.sendRedirect("list_participants.jsp?errCode=invalidAction&" + backPart);
        return;
    }

    // Step 3: Process - look the participant up
    String name = null, code = null, email = null, status = null;
    int upcomingCount = 0, totalCount = 0;
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
            response.sendRedirect("list_participants.jsp?errCode=notFound&" + backPart);
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

        // every sign-up (any date or status) - all of them go if the participant is deleted
        PreparedStatement allPs = conn.prepareStatement(
                "SELECT COUNT(*) AS cnt FROM event_registrations WHERE participant_id = ?");
        allPs.setInt(1, participantId);
        ResultSet allRs = allPs.executeQuery();
        if (allRs.next()) {
            totalCount = allRs.getInt("cnt");
        }
    } catch (Exception e) {
        System.err.println("confirm_participant_action.jsp - " + e);
        response.sendRedirect("list_participants.jsp?errCode=dbError&" + backPart);
        return;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }

    if (!isDelete && !"active".equals(status)) {
        response.sendRedirect("list_participants.jsp?errCode=alreadyInactive&" + backPart);
        return;
    }
%>
<%@ include file="/WEB-INF/common/header.jsp" %>

<div class="mx-auto" style="max-width: 640px;">
    <h1 class="h2 text-primary mb-4"><%= isDelete ? "Confirm Delete Participant" : "Confirm Deactivate Participant" %></h1>

    <dl class="row">
        <dt class="col-sm-4 text-muted fw-normal">Name</dt><dd class="col-sm-8 fw-semibold"><%= esc(name) %></dd>
        <dt class="col-sm-4 text-muted fw-normal">Participant code</dt><dd class="col-sm-8"><%= esc(code) %></dd>
        <dt class="col-sm-4 text-muted fw-normal">Email</dt><dd class="col-sm-8"><%= esc(email) %></dd>
        <dt class="col-sm-4 text-muted fw-normal">Upcoming sign-ups</dt><dd class="col-sm-8"><%= upcomingCount %> event(s)</dd>
    </dl>

    <% if (isDelete) { %>
        <div class="alert alert-danger">
            This permanently deletes <%= esc(name) %>'s details, login and all <%= totalCount %> event sign-up(s).
            <strong>This cannot be undone.</strong> To keep the records, use Deactivate instead.
        </div>
        <p>Are you sure you want to delete this participant?</p>
    <% } else { %>
        <div class="alert alert-warning">
            <%= esc(name) %> will no longer be able to log in. Their details and sign-ups are kept,
            and you can activate the account again at any time from the participant list.
        </div>
        <p>Are you sure you want to deactivate this account?</p>
    <% } %>

    <form method="post" action="participant_status_action.jsp">
        <input type="hidden" name="id" value="<%= participantId %>">
        <input type="hidden" name="mode" value="<%= isDelete ? "delete" : "deactivate" %>">
        <input type="hidden" name="filter" value="<%= esc(backFilter) %>">
        <input type="hidden" name="q" value="<%= esc(backQ) %>">
        <input type="hidden" name="p" value="<%= backPage %>">
        <button type="submit" class="btn btn-danger"><%= isDelete ? "Yes, Delete Permanently" : "Yes, Deactivate" %></button>
    </form>
    <a href="list_participants.jsp?<%= esc(backPart) %>" class="btn btn-link text-secondary text-decoration-none px-0 mt-2">Cancel</a>
</div>

<%@ include file="/WEB-INF/common/footer.jsp" %>