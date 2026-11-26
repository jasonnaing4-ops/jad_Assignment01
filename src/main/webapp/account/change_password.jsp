<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.Map" %>
<%--
    Description: Change-password form for the signed-in participant.
      - Forced: an account staff created starts with a demo password
        (users.must_change_password = 1). login_okay.jsp sends the participant
        here, and require_participant.jsp sends every other participant page
        here too, until a new password is saved.
      - Voluntary: also reachable from My Account at any time.
    Pure display page - save_password.jsp does the checks and the update, and
    forwards back here with an errors map if anything is wrong. Passwords are
    never put back into the form.
--%>
<%@ include file="/WEB-INF/common/require_participant.jsp" %>
<%
    @SuppressWarnings("unchecked")
    Map<String, String> errors = (Map<String, String>) request.getAttribute("errors");
%>
<%@ include file="/WEB-INF/common/header.jsp" %>
<%@ include file="/WEB-INF/common/form_helpers.jsp" %>

<div class="mx-auto" style="max-width: 520px;">
    <h1 class="h2 text-primary mb-2"><%= guardMustChange ? "Choose Your Own Password" : "Change Password" %></h1>
    <% if (guardMustChange) { %>
        <div class="alert alert-info">
            You are using a demo password from the screening staff. Choose your own password to continue.
        </div>
    <% } %>

    <%@ include file="/WEB-INF/common/messages.jsp" %>

    <%-- novalidate: the server checks every field, so the user always gets the same, specific messages --%>
    <form method="post" action="save_password.jsp" class="card shadow-sm" novalidate>
        <div class="card-body p-4">
            <div class="mb-3">
                <label for="currentPassword" class="form-label fw-semibold"><%= guardMustChange ? "Demo Password" : "Current Password" %> <span class="text-danger">*</span></label>
                <input type="password" id="currentPassword" name="currentPassword" maxlength="72" autocomplete="current-password"
                       class="form-control<%= invalidClass(errors, "currentPassword") %>" <%= errAria(errors, "currentPassword") %>>
                <%= errText(errors, "currentPassword") %>
            </div>
            <div class="mb-3">
                <label for="newPassword" class="form-label fw-semibold">New Password <span class="text-danger">*</span></label>
                <input type="password" id="newPassword" name="newPassword" maxlength="72" autocomplete="new-password"
                       class="form-control<%= invalidClass(errors, "newPassword") %>" <%= errAria(errors, "newPassword") %>>
                <div class="form-text">At least 8 characters, with a letter and a number</div>
                <%= errText(errors, "newPassword") %>
            </div>
            <div class="mb-4">
                <label for="confirmPassword" class="form-label fw-semibold">Confirm New Password <span class="text-danger">*</span></label>
                <input type="password" id="confirmPassword" name="confirmPassword" maxlength="72" autocomplete="new-password"
                       class="form-control<%= invalidClass(errors, "confirmPassword") %>" <%= errAria(errors, "confirmPassword") %>>
                <%= errText(errors, "confirmPassword") %>
            </div>

            <div class="d-flex align-items-center gap-3">
                <button type="submit" class="btn btn-primary">Save Password</button>
                <% if (guardMustChange) { %>
                    <a href="<%= request.getContextPath() %>/login/logout.jsp" class="btn btn-link text-secondary text-decoration-none">Log out</a>
                <% } else { %>
                    <a href="my_account.jsp" class="btn btn-link text-secondary text-decoration-none">Cancel</a>
                <% } %>
            </div>
        </div>
    </form>
</div>

<%@ include file="/WEB-INF/common/footer.jsp" %>