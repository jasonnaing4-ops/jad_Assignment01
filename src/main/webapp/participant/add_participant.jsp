<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.Map" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Staff "add participant" form (section 3.2). Creates the
    participant's login as well as their record, and can sign them up for an
    event straight away (associates the registration with an event, section
    3.3) using the shared event dropdown. Pure display page -
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
%>
<%@ include file="/WEB-INF/common/header.jsp" %>
<%@ include file="/WEB-INF/common/form_helpers.jsp" %>

<nav aria-label="breadcrumb">
    <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="list_participants.jsp">Participants</a></li>
        <li class="breadcrumb-item active" aria-current="page">Add Participant</li>
    </ol>
</nav>
<h1 class="h2 text-primary mb-2">Add Participant</h1>
<p class="text-muted">Fields marked <span class="text-danger">*</span> are required.</p>

<div style="max-width: 720px;">
    <%@ include file="/WEB-INF/common/messages.jsp" %>

    <form method="post" action="save_participant.jsp" class="card shadow-sm" novalidate>
        <div class="card-body p-4">
            <h2 class="h5 mb-3">Participant Details</h2>
            <%@ include file="/WEB-INF/common/participant_fields.jsp" %>

            <h2 class="h5 mt-4 mb-1">Login Details</h2>
            <p class="form-text mt-0 mb-3">Give these to the participant so they can log in and manage their own sign-ups.</p>
            <%@ include file="/WEB-INF/common/account_fields.jsp" %>

            <h2 class="h5 mt-4 mb-3">Event Sign-up (optional)</h2>
            <div class="mb-4">
                <label for="eventId" class="form-label fw-semibold">Sign up for an event</label>
                <select id="eventId" name="eventId" class="form-select<%= invalidClass(errors, "eventId") %>" <%= errAria(errors, "eventId") %>>
                    <option value="">-- No event for now --</option>
                    <%@ include file="/WEB-INF/common/event_dropdown.jsp" %>
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
