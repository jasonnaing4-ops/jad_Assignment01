<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Confirm step before a destructive event action (delete or
    deactivate) - section 7 (L03c pattern): list -> confirm -> action ->
    redirect back to list?msg=. Reached only by the small POST forms on
    list_events.jsp. Looks the event up, checks whether it has registrations,
    then shows a locked confirm form that posts on to event_status_action.jsp.
--%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>
<%
    // Step 1: Existence
    String idParam = request.getParameter("id");
    String mode = request.getParameter("mode");
    if (idParam == null || mode == null) {
        response.sendRedirect("list_events.jsp");
        return;
    }

    // Step 2: Validate
    int eventId;
    try {
        eventId = Integer.parseInt(idParam.trim());
    } catch (Exception e) {
        response.sendRedirect("list_events.jsp?errCode=invalidAction");
        return;
    }
    if (!mode.equals("delete") && !mode.equals("deactivate")) {
        response.sendRedirect("list_events.jsp?errCode=invalidAction");
        return;
    }

    // Step 3: Process - look the event up and check for registrations
    String eventName = null;
    java.sql.Date eventDate = null;
    int registrationCount = 0;
    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        String sql = "SELECT event_name, event_date FROM events WHERE event_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, eventId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            eventName = rs.getString("event_name");
            eventDate = rs.getDate("event_date");
        } else {
            response.sendRedirect("list_events.jsp?errCode=notFound");
            return;
        }

        String countSql = "SELECT COUNT(*) AS cnt FROM event_registrations WHERE event_id = ? AND status = 'registered'";
        PreparedStatement countPs = conn.prepareStatement(countSql);
        countPs.setInt(1, eventId);
        ResultSet countRs = countPs.executeQuery();
        if (countRs.next()) {
            registrationCount = countRs.getInt("cnt");
        }
    } catch (Exception e) {
        System.err.println("confirm_event_action.jsp - " + e);
        response.sendRedirect("list_events.jsp?errCode=dbError");
        return;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }

    boolean blockDelete = mode.equals("delete") && registrationCount > 0;
%>
<%@ include file="/WEB-INF/common/header.jsp" %>

<h1 class="h2 text-primary mb-4">Confirm <%= mode.equals("delete") ? "Delete" : "Deactivate" %> Event</h1>

<p>Event: <strong><%= esc(eventName) %></strong> (<%= eventDate %>)</p>
<p><%= registrationCount %> participant(s) currently registered.</p>

<% if (blockDelete) { %>
    <div class="alert alert-danger">
        This event has participants registered and cannot be deleted.
        You can deactivate it instead so it stops accepting new sign-ups.
    </div>
    <form method="post" action="event_status_action.jsp">
        <input type="hidden" name="id" value="<%= eventId %>" class="form-control w-auto mb-3">
        <input type="hidden" name="mode" value="deactivate">
        <button type="submit" class="btn btn-primary">Deactivate Instead</button>
    </form>
<% } else { %>
    <p>Are you sure? This cannot be undone<%= mode.equals("deactivate") ? " easily" : "" %>.</p>
    <form method="post" action="event_status_action.jsp">
        <input type="hidden" name="id" value="<%= eventId %>" class="form-control w-auto mb-3">
        <input type="hidden" name="mode" value="<%= mode %>">
        <button type="submit" class="btn btn-danger">Yes, <%= mode.equals("delete") ? "Delete" : "Deactivate" %></button>
    </form>
<% } %>
<a href="list_events.jsp" class="btn btn-link text-secondary text-decoration-none px-0 mt-2">Cancel</a>

<%@ include file="/WEB-INF/common/footer.jsp" %>