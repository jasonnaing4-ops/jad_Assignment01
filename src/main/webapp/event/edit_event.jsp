<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Pre-filled "edit event" form (section 3.3). Follows the L03c
    confirm-page pattern: look the record up first (existence/validate/process),
    redirect away if the id is bad or the event is gone, and only then write
    HTML. save_event.jsp does the actual UPDATE.
--%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>
<%
    // Step 1: Existence
    String idParam = request.getParameter("id");
    if (idParam == null) {
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

    // Step 3: Process - look the event up
    String dbEventName = null, dbVenue = null, status = null, dbDescription = null;
    java.sql.Time dbStartTime = null, dbEndTime = null;
    java.sql.Date dbEventDate = null;
    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);
        String sql = "SELECT event_name, event_date, venue, status, start_time, end_time, description FROM events WHERE event_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, eventId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            dbEventName = rs.getString("event_name");
            dbEventDate = rs.getDate("event_date");
            dbVenue = rs.getString("venue");
            status = rs.getString("status");
            dbStartTime = rs.getTime("start_time");
            dbEndTime = rs.getTime("end_time");
            dbDescription = rs.getString("description");
        } else {
            response.sendRedirect("list_events.jsp?errCode=notFound");
            return;
        }
    } catch (Exception e) {
        System.err.println("edit_event.jsp - " + e);
        response.sendRedirect("list_events.jsp?errCode=dbError");
        return;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }

    // If save_event.jsp rejected a previous attempt it redirects back here
    // with the values that were typed, so those take priority over the DB.
    String errCode = request.getParameter("errCode");
    String errMessage = null;
    if (errCode != null) {
        if (errCode.equals("emptyFields")) { errMessage = "Event name, date, start time and end time are required."; }
        else if (errCode.equals("badDate")) { errMessage = "Please enter a valid date (YYYY-MM-DD)."; }
        else if (errCode.equals("badTime")) { errMessage = "Please enter valid start and end times."; }
        else if (errCode.equals("endBeforeStart")) { errMessage = "End time must be later than start time."; }
        else if (errCode.equals("dbError")) { errMessage = "Something went wrong saving the event. Please try again."; }
    }

    String nameOverride = request.getParameter("eventName");
    String dateOverride = request.getParameter("eventDate");
    String venueOverride = request.getParameter("venue");
    String startTimeOverride = request.getParameter("startTime");
    String endTimeOverride = request.getParameter("endTime");
    String descriptionOverride = request.getParameter("description");

    String nameDisplay = (nameOverride != null) ? nameOverride : dbEventName;
    String dateDisplay = (dateOverride != null) ? dateOverride : (dbEventDate != null ? dbEventDate.toString() : "");
    String venueDisplay = (venueOverride != null) ? venueOverride : dbVenue;
    // time columns come back as HH:mm:ss - the time input wants HH:mm
    String startTimeDisplay = (startTimeOverride != null) ? startTimeOverride : (dbStartTime != null ? dbStartTime.toString().substring(0, 5) : "");
    String endTimeDisplay = (endTimeOverride != null) ? endTimeOverride : (dbEndTime != null ? dbEndTime.toString().substring(0, 5) : "");
    String descriptionDisplay = (descriptionOverride != null) ? descriptionOverride : dbDescription;
%>
<%@ include file="/WEB-INF/common/header.jsp" %>

<h1 class="h2 text-primary text-center mb-4">Edit Event</h1>

<% if (errMessage != null) { %><div class="alert alert-danger mx-auto" style="max-width: 520px;"><%= esc(errMessage) %></div><% } %>

<form method="post" action="save_event.jsp" class="card shadow-sm mx-auto" style="max-width: 520px;">
    <div class="card-body p-4">
        <input type="hidden" name="id" value="<%= eventId %>">

        <div class="mb-3">
            <label for="eventName" class="form-label fw-semibold">Event Title</label>
            <input type="text" id="eventName" name="eventName" class="form-control" placeholder="Event Name" value="<%= esc(nameDisplay) %>" required>
        </div>

        <div class="mb-3">
            <label for="eventDate" class="form-label fw-semibold">Pick Date</label>
            <input type="date" id="eventDate" name="eventDate" class="form-control" value="<%= esc(dateDisplay) %>" required>
        </div>

        <div class="row g-2 align-items-end mb-3">
            <div class="col">
                <label for="startTime" class="form-label fw-semibold">Start Time</label>
                <input type="time" id="startTime" name="startTime" class="form-control" value="<%= esc(startTimeDisplay) %>" required>
            </div>
            <div class="col-auto pb-2 text-muted">&rarr;</div>
            <div class="col">
                <label for="endTime" class="form-label fw-semibold">End Time</label>
                <input type="time" id="endTime" name="endTime" class="form-control" value="<%= esc(endTimeDisplay) %>" required>
            </div>
        </div>

        <div class="mb-3">
            <label for="venue" class="form-label fw-semibold">Add Location</label>
            <input type="text" id="venue" name="venue" class="form-control" placeholder="Venue" value="<%= esc(venueDisplay) %>">
        </div>

        <div class="mb-3">
            <label for="description" class="form-label fw-semibold">Add Description</label>
            <textarea id="description" name="description" class="form-control" rows="4" maxlength="500" placeholder="Enter Description"><%= esc(descriptionDisplay) %></textarea>
        </div>

        <div class="mb-3">
            <label for="status" class="form-label fw-semibold">Status</label>
            <select id="status" name="status" class="form-select">
                <option value="active" <%= "active".equals(status) ? "selected" : "" %>>Active</option>
                <option value="inactive" <%= "inactive".equals(status) ? "selected" : "" %>>Inactive</option>
            </select>
        </div>

        <div class="d-flex align-items-center gap-3">
            <button type="submit" class="btn btn-primary">Save Changes</button>
            <a href="list_events.jsp" class="btn btn-link text-secondary text-decoration-none">Cancel</a>
        </div>
    </div>
</form>

<%@ include file="/WEB-INF/common/footer.jsp" %>