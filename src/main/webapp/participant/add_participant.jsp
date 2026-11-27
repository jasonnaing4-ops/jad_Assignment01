<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*, java.util.Map" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Staff "add participant" form (section 3.2). Creates the
    participant's login as well as their record (staff choose the username;
    the system generates a demo password that must be changed at first login), and can sign them up for an
    event straight away (associates the registration with an event, section
    3.3). The dropdown lists upcoming events only (active, dated after
    today). Display page only -
    save_participant.jsp does the checks and the insert, and forwards back
    here with an errors map if anything is wrong (typed values are kept,
    passwords are not).
--%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>
<%
    @SuppressWarnings("unchecked")
    Map<String, String> errors = (Map<String, String>) request.getAttribute("errors");

    String fUsername = request.getParameter("username");
    String fFullName = request.getParameter("fullName");
    String fContactNo = request.getParameter("contactNo");
    String fEmail = request.getParameter("email");
    String fDob = request.getParameter("dateOfBirth");
    String fGender = request.getParameter("gender");
    String fEventId = request.getParameter("eventId");   // keeps the chosen event after an error
%>
<%@ include file="/WEB-INF/common/header.jsp" %>
<%@ include file="/WEB-INF/common/form_helpers.jsp" %>

<div class="mx-auto" style="max-width: 720px;">
<nav aria-label="breadcrumb">
    <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="list_participants.jsp">Participants</a></li>
        <li class="breadcrumb-item active" aria-current="page">Add Participant</li>
    </ol>
</nav>
<h1 class="h2 text-primary mb-2">Add Participant</h1>
<p class="text-muted">Fields marked <span class="text-danger">*</span> are required.</p>

    <%@ include file="/WEB-INF/common/messages.jsp" %>

    <form method="post" action="save_participant.jsp" class="card shadow-sm" novalidate>
        <div class="card-body p-4">
            <h2 class="h5 mb-3">Participant Details</h2>
            <%@ include file="/WEB-INF/common/participant_fields.jsp" %>

            <h2 class="h5 mt-4 mb-1">Login Details</h2>
            <p class="form-text mt-0 mb-3">A demo password is created for you after saving. Give the participant their username and that password. They must choose their own password the first time they log in.</p>
            <div class="mb-3">
                <label for="username" class="form-label fw-semibold">Username <span class="text-danger">*</span></label>
                <input type="text" id="username" name="username" maxlength="50" autocomplete="off"
                       class="form-control<%= invalidClass(errors, "username") %>" value="<%= esc(fUsername) %>" <%= errAria(errors, "username") %>>
                <div class="form-text">3 to 50 letters, numbers or _</div>
                <%= errText(errors, "username") %>
            </div>

            <h2 class="h5 mt-4 mb-3">Event Sign-up (optional)</h2>
            <div class="mb-4">
                <label for="eventId" class="form-label fw-semibold">Sign up for an event</label>
                <select id="eventId" name="eventId" class="form-select<%= invalidClass(errors, "eventId") %>" <%= errAria(errors, "eventId") %>>
                    <option value="">-- No event for now --</option>
<%
    // Upcoming events only (active, date after today) - same rule that
    // save_participant.jsp re-checks on the server
    Connection evConn = null;
    try {
        Class.forName(jdbcDriver);
        evConn = DriverManager.getConnection(connURL);
        PreparedStatement evPs = evConn.prepareStatement(
                "SELECT event_id, event_name, event_date FROM events "
              + "WHERE status = 'active' AND event_date > CURDATE() ORDER BY event_date, event_name");
        ResultSet evRs = evPs.executeQuery();
        while (evRs.next()) {
            String evId = String.valueOf(evRs.getInt("event_id"));
%>
                    <option value="<%= evId %>"<%= evId.equals(fEventId) ? " selected" : "" %>><%= esc(evRs.getString("event_name")) %> (<%= evRs.getDate("event_date") %>)</option>
<%
        }
    } catch (Exception e) {
        System.err.println("add_participant.jsp - " + e);
%>
                    <option value="" disabled>-- events unavailable, try again later --</option>
<%
    } finally {
        if (evConn != null) {
            try { evConn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>
                </select>
                <%= errText(errors, "eventId") %>
            </div>

            <div class="d-flex align-items-center gap-3">
                <button type="submit" class="btn btn-primary">Add Participant</button>
                <a href="list_participants.jsp" class="btn btn-link text-secondary text-decoration-none">Cancel</a>
            </div>
        </div>
    </form>
</div>

<%@ include file="/WEB-INF/common/footer.jsp" %>