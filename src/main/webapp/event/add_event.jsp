<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Blank "add event" form (section 3.3). Pure display page -
    save_event.jsp does the actual insert. If save_event.jsp rejects the
    input it redirects back here with errCode plus the values that were
    typed, so nothing needs to be retyped (section 3.4).
--%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>
<%@ include file="/WEB-INF/common/header.jsp" %>

<%
    String errCode = request.getParameter("errCode");
    String errMessage = null;
    if (errCode != null) {
        if (errCode.equals("emptyFields")) { errMessage = "Event name, date, start time and end time are required."; }
        else if (errCode.equals("badDate")) { errMessage = "Please enter a valid date (YYYY-MM-DD)."; }
        else if (errCode.equals("badTime")) { errMessage = "Please enter valid start and end times."; }
        else if (errCode.equals("endBeforeStart")) { errMessage = "End time must be later than start time."; }
        else if (errCode.equals("dbError")) { errMessage = "Something went wrong saving the event. Please try again."; }
    }
    String nameValue = request.getParameter("eventName");
    String dateValue = request.getParameter("eventDate");
    String venueValue = request.getParameter("venue");
    String startTimeValue = request.getParameter("startTime");
    String endTimeValue = request.getParameter("endTime");
    String descriptionValue = request.getParameter("description");
%>

<h1 class="h2 text-primary text-center mb-4">Create Event</h1>

<% if (errMessage != null) { %><div class="alert alert-danger mx-auto" style="max-width: 520px;"><%= esc(errMessage) %></div><% } %>

<form method="post" action="save_event.jsp" class="card shadow-sm mx-auto" style="max-width: 520px;">
    <div class="card-body p-4">
        <div class="mb-3">
            <label for="eventName" class="form-label fw-semibold">Event Title</label>
            <input type="text" id="eventName" name="eventName" class="form-control" placeholder="Event Name" value="<%= esc(nameValue) %>" required>
        </div>

        <div class="mb-3">
            <label for="eventDate" class="form-label fw-semibold">Pick Date</label>
            <input type="date" id="eventDate" name="eventDate" class="form-control" value="<%= esc(dateValue) %>" required>
        </div>

        <div class="row g-2 align-items-end mb-3">
            <div class="col">
                <label for="startTime" class="form-label fw-semibold">Start Time</label>
                <input type="time" id="startTime" name="startTime" class="form-control" value="<%= esc(startTimeValue) %>" required>
            </div>
            <div class="col-auto pb-2 text-muted">&rarr;</div>
            <div class="col">
                <label for="endTime" class="form-label fw-semibold">End Time</label>
                <input type="time" id="endTime" name="endTime" class="form-control" value="<%= esc(endTimeValue) %>" required>
            </div>
        </div>

        <div class="mb-3">
            <label for="venue" class="form-label fw-semibold">Add Location</label>
            <input type="text" id="venue" name="venue" class="form-control" placeholder="Venue" value="<%= esc(venueValue) %>">
        </div>

        <div class="mb-3">
            <label for="description" class="form-label fw-semibold">Add Description</label>
            <textarea id="description" name="description" class="form-control" rows="4" maxlength="500" placeholder="Enter Description"><%= esc(descriptionValue) %></textarea>
        </div>

        <div class="d-flex align-items-center gap-3">
            <button type="submit" class="btn btn-primary">Save Event</button>
            <a href="list_events.jsp" class="btn btn-link text-secondary text-decoration-none">Cancel</a>
        </div>
    </div>
</form>

<%@ include file="/WEB-INF/common/footer.jsp" %>