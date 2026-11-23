<%@ page import="java.util.Map" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Shared message box for the participant pages, so every page
    shows success and error messages in the same place and style. Include it
    ONCE, after header.jsp (it uses esc()), where the message should appear:

        <%@ include file="/WEB-INF/common/messages.jsp" %>

    It shows three kinds of message:
      1. ?msg=<code>      after a successful redirect (green)
      2. ?errCode=<code>  after a failed redirect (red)
         Only the codes listed below are shown, so a typed URL can never put
         its own text on the page.
      3. Form problems from a decision page that forwarded back to the form:
           request.setAttribute("errors", errors);       // field -> message
           request.setAttribute("formError", "...");     // problem not tied to one field
         The errors map is shown as a summary with a link to each field
         (the field's id must match the key); form_helpers.jsp shows the same
         message under the field itself.

    All variables start with "msg" so they cannot clash with the page's own.
--%>
<%
    String msgCode = request.getParameter("msg");
    String msgErrCode = request.getParameter("errCode");
    String msgInfo = null;
    String msgError = null;

    if (msgCode != null) {
        if (msgCode.equals("participantAdded")) { msgInfo = "Participant added. Give them their username and password so they can log in."; }
        else if (msgCode.equals("participantAddedSignedUp")) { msgInfo = "Participant added and signed up for the event."; }
        else if (msgCode.equals("participantUpdated")) { msgInfo = "Participant details saved."; }
        else if (msgCode.equals("participantDeactivated")) { msgInfo = "Account deactivated. The participant can no longer log in."; }
        else if (msgCode.equals("participantActivated")) { msgInfo = "Account activated. The participant can log in again."; }
        else if (msgCode.equals("detailsSaved")) { msgInfo = "Your details were saved."; }
        else if (msgCode.equals("signedUp")) { msgInfo = "You have signed up for the event."; }
        else if (msgCode.equals("withdrawn")) { msgInfo = "You have withdrawn from the event."; }
    }

    if (msgErrCode != null) {
        if (msgErrCode.equals("notFound")) { msgError = "That participant could not be found - it may have been removed."; }
        else if (msgErrCode.equals("invalidAction")) { msgError = "That request was not valid. Please try again from this page."; }
        else if (msgErrCode.equals("dbError")) { msgError = "Something went wrong. Please try again."; }
        else if (msgErrCode.equals("alreadyActive")) { msgError = "That account is already active."; }
        else if (msgErrCode.equals("alreadyInactive")) { msgError = "That account is already deactivated."; }
        else if (msgErrCode.equals("eventNotFound")) { msgError = "That event could not be found."; }
        else if (msgErrCode.equals("eventClosed")) { msgError = "That event is not open for sign-ups."; }
        else if (msgErrCode.equals("eventPast")) { msgError = "That event has already taken place."; }
        else if (msgErrCode.equals("notSignedUp")) { msgError = "You were not signed up for that event."; }
    }

    String msgFormError = (String) request.getAttribute("formError");
    @SuppressWarnings("unchecked")
    Map<String, String> msgErrors = (Map<String, String>) request.getAttribute("errors");
%>
<% if (msgInfo != null) { %>
    <div class="alert alert-success" role="status"><%= esc(msgInfo) %></div>
<% } %>
<% if (msgError != null) { %>
    <div class="alert alert-danger" role="alert"><%= esc(msgError) %></div>
<% } %>
<% if (msgFormError != null) { %>
    <div class="alert alert-danger" role="alert"><%= esc(msgFormError) %></div>
<% } %>
<% if (msgErrors != null && !msgErrors.isEmpty()) { %>
    <div class="alert alert-danger" role="alert">
        <p class="fw-semibold mb-1">Please fix <%= msgErrors.size() %> <%= msgErrors.size() == 1 ? "problem" : "problems" %> before saving:</p>
        <ul class="mb-0">
        <% for (Map.Entry<String, String> msgEntry : msgErrors.entrySet()) { %>
            <li><a class="alert-link" href="#<%= esc(msgEntry.getKey()) %>"><%= esc(msgEntry.getValue()) %></a></li>
        <% } %>
        </ul>
    </div>
<% } %>
