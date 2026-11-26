<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Confirm step before a destructive event action (delete or
    deactivate) Reached only by the small POST forms on
    list_events.jsp. Looks the event up, checks whether it has registrations,
    then shows a locked confirm form that posts on to event_status_action.jsp.
--%>

<%-- Access Control: verify staff session and load database configuration --%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>
<%
	//Parameter Validation: ensure event ID and mode exist, parse eventId, and whitelist delete/deactivate
    String idParam = request.getParameter("id");
    String mode = request.getParameter("mode");
    if (idParam == null || mode == null) {
        response.sendRedirect("list_events.jsp");
        return;
    }

    
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

 	// Database Lookup & Registration Check: fetch event details and count active registrations
    String eventName = null;
    String eventStatus = null;
    java.sql.Date eventDate = null;
    int registrationCount = 0;
    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        String sql = "SELECT event_name, event_date, status FROM events WHERE event_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, eventId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            eventName = rs.getString("event_name");
            eventDate = rs.getDate("event_date");
            eventStatus = rs.getString("status");
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

 	// Display State Formatting: determine delete eligibility and format date/status strings
    boolean blockDelete = mode.equals("delete") && registrationCount > 0;
    boolean isDelete = mode.equals("delete");
    boolean isActive = "active".equals(eventStatus);
    String prettyDate = new java.text.SimpleDateFormat("d MMMM yyyy").format(eventDate);
    String prettyStatus = eventStatus.substring(0, 1).toUpperCase() + eventStatus.substring(1);
%>

<%-- Header & Confirmation UI: render event summary card, warning banner, and form posting to event_status_action.jsp --%>
<%@ include file="/WEB-INF/common/header.jsp" %>

<h1 class="h2 fw-bold text-primary mb-2"><%= isDelete ? "Delete" : "Deactivate" %> This Event?</h1>
<p class="text-secondary mb-4">Please review the event information before proceeding.</p>

<div class="bg-light rounded-3 p-3 mb-3">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <span class="fw-semibold">Event Information</span>
        <span class="badge rounded-pill <%= isActive ? "bg-success-subtle text-success-emphasis" : "bg-secondary-subtle text-secondary-emphasis" %>"><%= esc(prettyStatus) %></span>
    </div>
    <div class="fw-semibold mb-3"><%= esc(eventName) %></div>
    <div class="d-flex align-items-center gap-2 text-secondary mb-2">
        <i class="bi bi-calendar3"></i>
        <span><%= prettyDate %></span>
    </div>
    <div class="d-flex align-items-center gap-2 text-secondary">
        <i class="bi bi-people"></i>
        <span><%= registrationCount %> registered participant<%= registrationCount == 1 ? "" : "s" %></span>
    </div>
</div>

<div class="bg-danger-subtle text-danger-emphasis rounded-3 p-3 mb-3">
    <div class="d-flex align-items-center gap-2 fw-semibold mb-1">
        <i class="bi bi-exclamation-triangle"></i>
        <span><%= blockDelete ? "Cannot Delete" : (isDelete ? "Deletion Warning" : "Deactivation Warning") %></span>
    </div>
    <div>
        <% if (blockDelete) { %>
            This event has participants registered, so it cannot be deleted. You can deactivate it instead so it stops accepting new sign-ups.
        <% } else if (isDelete) { %>
            This will permanently remove the event and cannot be undone.
        <% } else { %>
            Participants will no longer be able to register for this event after deactivation.
        <% } %>
    </div>
</div>

<form method="post" action="event_status_action.jsp" class="d-flex gap-2 m-0">
    <input type="hidden" name="id" value="<%= eventId %>">
    <input type="hidden" name="mode" value="<%= blockDelete ? "deactivate" : mode %>">
    <a href="list_events.jsp" class="btn bg-secondary-subtle text-secondary-emphasis fw-semibold flex-fill py-2">Cancel</a>
    <% if (blockDelete) { %>
        <button type="submit" class="btn btn-primary fw-semibold flex-fill py-2">Deactivate Instead</button>
    <% } else { %>
        <button type="submit" class="btn btn-danger fw-semibold flex-fill py-2"><%= isDelete ? "Delete" : "Deactivate" %> Event</button>
    <% } %>
</form>

<%@ include file="/WEB-INF/common/footer.jsp" %>