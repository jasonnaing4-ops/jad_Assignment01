<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*, java.util.*" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Participant's events page - explore events, sign up and
    withdraw (associates each registration with an event, section 3.3).
      - "My sign-ups": events this participant is registered for, with a
        Withdraw button while the event has not happened yet.
      - "Open events": active events from today onwards that they have not
        joined yet, with a Sign Up button.
    Both buttons are small POST forms to signup_action.jsp. Everything is
    looked up by the userId in the session.
--%>
<%@ include file="/WEB-INF/common/require_participant.jsp" %>
<%
    // {event_id, name, date, start-end, venue, state}   state: upcoming / past / inactive
    List<String[]> joined = new ArrayList<>();
    // {event_id, name, date, start-end, venue, description}
    List<String[]> open = new ArrayList<>();
    boolean loadFailed = false;

    // Pagination: My Sign-ups 5 per page (sp), Open Events 10 per page (op).
    // Separate parameters, so moving through one list does not reset the other.
    int signPageSize = 5;
    int openPageSize = 10;
    int signPage = Math.max(1, util.Validator.parseId(request.getParameter("sp")));
    int openPage = Math.max(1, util.Validator.parseId(request.getParameter("op")));
    int signTotal = 0, openTotal = 0;
    int signPages = 1, openPages = 1;

    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        // totals first, so a page number that is too high can be pulled back into range
        PreparedStatement signCountPs = conn.prepareStatement(
                "SELECT COUNT(*) FROM event_registrations r JOIN participants p ON p.participant_id = r.participant_id "
              + "WHERE p.user_id = ? AND r.status = 'registered'");
        signCountPs.setInt(1, userId);
        ResultSet signCountRs = signCountPs.executeQuery();
        if (signCountRs.next()) { signTotal = signCountRs.getInt(1); }
        signPages = Math.max(1, (signTotal + signPageSize - 1) / signPageSize);
        if (signPage > signPages) { signPage = signPages; }

        PreparedStatement openCountPs = conn.prepareStatement(
                "SELECT COUNT(*) FROM events e WHERE e.status = 'active' AND e.event_date >= CURDATE() "
              + "AND e.event_id NOT IN (SELECT r.event_id FROM event_registrations r "
              + "  JOIN participants p ON p.participant_id = r.participant_id "
              + "  WHERE p.user_id = ? AND r.status = 'registered')");
        openCountPs.setInt(1, userId);
        ResultSet openCountRs = openCountPs.executeQuery();
        if (openCountRs.next()) { openTotal = openCountRs.getInt(1); }
        openPages = Math.max(1, (openTotal + openPageSize - 1) / openPageSize);
        if (openPage > openPages) { openPage = openPages; }

        String joinedSql = "SELECT e.event_id, e.event_name, e.event_date, e.start_time, e.end_time, e.venue, e.status, "
                         + "(e.event_date < CURDATE()) AS is_past "
                         + "FROM event_registrations r "
                         + "JOIN participants p ON p.participant_id = r.participant_id "
                         + "JOIN events e ON e.event_id = r.event_id "
                         + "WHERE p.user_id = ? AND r.status = 'registered' ORDER BY e.event_date, e.event_id LIMIT ? OFFSET ?";
        PreparedStatement joinedPs = conn.prepareStatement(joinedSql);
        joinedPs.setInt(1, userId);
        joinedPs.setInt(2, signPageSize);
        joinedPs.setInt(3, (signPage - 1) * signPageSize);
        ResultSet joinedRs = joinedPs.executeQuery();
        while (joinedRs.next()) {
            String state = joinedRs.getBoolean("is_past") ? "past"
                         : ("active".equals(joinedRs.getString("status")) ? "upcoming" : "inactive");
            joined.add(new String[] { String.valueOf(joinedRs.getInt("event_id")), joinedRs.getString("event_name"),
                    String.valueOf(joinedRs.getDate("event_date")),
                    timeRange(joinedRs.getTime("start_time"), joinedRs.getTime("end_time")),
                    joinedRs.getString("venue"), state });
        }

        String openSql = "SELECT e.event_id, e.event_name, e.event_date, e.start_time, e.end_time, e.venue, e.description "
                       + "FROM events e WHERE e.status = 'active' AND e.event_date >= CURDATE() "
                       + "AND e.event_id NOT IN (SELECT r.event_id FROM event_registrations r "
                       + "  JOIN participants p ON p.participant_id = r.participant_id "
                       + "  WHERE p.user_id = ? AND r.status = 'registered') "
                       + "ORDER BY e.event_date, e.event_id LIMIT ? OFFSET ?";
        PreparedStatement openPs = conn.prepareStatement(openSql);
        openPs.setInt(1, userId);
        openPs.setInt(2, openPageSize);
        openPs.setInt(3, (openPage - 1) * openPageSize);
        ResultSet openRs = openPs.executeQuery();
        while (openRs.next()) {
            open.add(new String[] { String.valueOf(openRs.getInt("event_id")), openRs.getString("event_name"),
                    String.valueOf(openRs.getDate("event_date")),
                    timeRange(openRs.getTime("start_time"), openRs.getTime("end_time")),
                    openRs.getString("venue"), openRs.getString("description") });
        }
    } catch (Exception e) {
        System.err.println("my_signups.jsp - " + e);
        loadFailed = true;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>
<%!
    // "09:00 - 12:00", or "-" for events created before times existed
    private String timeRange(java.sql.Time start, java.sql.Time end) {
        if (start == null || end == null) { return "-"; }
        return start.toString().substring(0, 5) + " - " + end.toString().substring(0, 5);
    }
%>
<%@ include file="/WEB-INF/common/header.jsp" %>
<%@ include file="/WEB-INF/common/pagination.jsp" %>

<h1 class="h2 text-primary mb-3">My Events</h1>
<%@ include file="/WEB-INF/common/messages.jsp" %>
<% if (loadFailed) { %><div class="alert alert-danger">Could not load events right now. Please try again.</div><% } %>

<h2 class="h5 mt-4 mb-3">My Sign-ups</h2>
<% if (joined.isEmpty()) { %>
    <p class="text-muted">You have not signed up for any events yet. Choose one from the open events below.</p>
<% } else { %>
<%= pagerBar("sign-ups", "my_signups.jsp?op=" + openPage + "&sp=", signPage, signPages, signPageSize, signTotal) %>
<div class="table-responsive">
<table class="table table-bordered table-hover align-middle">
    <caption class="visually-hidden">Events you have signed up for</caption>
    <thead class="table-light">
        <tr><th scope="col">Event</th><th scope="col">Date</th><th scope="col">Time</th><th scope="col">Venue</th><th scope="col">Status</th><th scope="col">Action</th></tr>
    </thead>
    <tbody>
    <% for (String[] ev : joined) { %>
        <tr>
            <td class="fw-semibold"><%= esc(ev[1]) %></td>
            <td class="text-nowrap"><%= esc(ev[2]) %></td>
            <td class="text-nowrap"><%= esc(ev[3]) %></td>
            <td><%= esc(ev[4]) %></td>
            <td>
                <% if (ev[5].equals("past")) { %><span class="badge rounded-pill text-bg-secondary">completed</span>
                <% } else if (ev[5].equals("inactive")) { %><span class="badge rounded-pill text-bg-warning">not running</span>
                <% } else { %><span class="badge rounded-pill text-bg-success">registered</span><% } %>
            </td>
            <td>
                <% if (!ev[5].equals("past")) { %>
                    <form method="post" action="signup_action.jsp" class="m-0">
                        <input type="hidden" name="eventId" value="<%= esc(ev[0]) %>">
                        <input type="hidden" name="mode" value="withdraw">
                        <input type="hidden" name="sp" value="<%= signPage %>">
                        <input type="hidden" name="op" value="<%= openPage %>">
                        <button type="submit" class="btn btn-sm btn-outline-danger text-nowrap">Withdraw</button>
                    </form>
                <% } else { %>-<% } %>
            </td>
        </tr>
    <% } %>
    </tbody>
</table>
</div>
<% } %>

<h2 class="h5 mt-4 mb-1">Open Events</h2>
<p class="form-text mt-0 mb-3">Upcoming events you can still sign up for.</p>
<% if (open.isEmpty()) { %>
    <p class="text-muted">There are no other open events right now. Please check again later.</p>
<% } else { %>
<%= pagerBar("events", "my_signups.jsp?sp=" + signPage + "&op=", openPage, openPages, openPageSize, openTotal) %>
<div class="table-responsive">
<table class="table table-bordered table-hover align-middle">
    <caption class="visually-hidden">Events you can sign up for</caption>
    <thead class="table-light">
        <tr><th scope="col">Event</th><th scope="col">Date</th><th scope="col">Time</th><th scope="col">Venue</th><th scope="col">Description</th><th scope="col">Action</th></tr>
    </thead>
    <tbody>
    <% for (String[] ev : open) { %>
        <tr>
            <td class="fw-semibold"><%= esc(ev[1]) %></td>
            <td class="text-nowrap"><%= esc(ev[2]) %></td>
            <td class="text-nowrap"><%= esc(ev[3]) %></td>
            <td><%= esc(ev[4]) %></td>
            <td class="text-break" style="max-width: 260px;"><%= (ev[5] == null || ev[5].isEmpty()) ? "-" : esc(ev[5]) %></td>
            <td>
                <form method="post" action="signup_action.jsp" class="m-0">
                    <input type="hidden" name="eventId" value="<%= esc(ev[0]) %>">
                    <input type="hidden" name="mode" value="signup">
                    <input type="hidden" name="sp" value="<%= signPage %>">
                    <input type="hidden" name="op" value="<%= openPage %>">
                    <button type="submit" class="btn btn-sm btn-primary text-nowrap">Sign Up</button>
                </form>
            </td>
        </tr>
    <% } %>
    </tbody>
</table>
</div>
<% } %>

<%@ include file="/WEB-INF/common/footer.jsp" %>