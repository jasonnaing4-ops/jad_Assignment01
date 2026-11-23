<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Username + password inputs for a NEW account, shared by
    login/register.jsp and participant/add_participant.jsp. Include INSIDE the
    page's own <form>:

        <%@ include file="/WEB-INF/common/account_fields.jsp" %>

    Passwords are never put back into the form after an error, so a password
    is never sent back to the browser inside the page.

    The including page must already have esc(), form_helpers.jsp,
    String fUsername and Map<String, String> errors (both may be null).
--%>
<div class="mb-3">
    <label for="username" class="form-label fw-semibold">Username <span class="text-danger">*</span></label>
    <input type="text" id="username" name="username" maxlength="50" autocomplete="username"
           class="form-control<%= invalidClass(errors, "username") %>" value="<%= esc(fUsername) %>" <%= errAria(errors, "username") %>>
    <div class="form-text">3 to 50 letters, numbers or _</div>
    <%= errText(errors, "username") %>
</div>
<div class="row g-3 mb-3">
    <div class="col-md-6">
        <label for="password" class="form-label fw-semibold">Password <span class="text-danger">*</span></label>
        <input type="password" id="password" name="password" maxlength="72" autocomplete="new-password"
               class="form-control<%= invalidClass(errors, "password") %>" <%= errAria(errors, "password") %>>
        <div class="form-text">At least 8 characters, with a letter and a number</div>
        <%= errText(errors, "password") %>
    </div>
    <div class="col-md-6">
        <label for="confirmPassword" class="form-label fw-semibold">Confirm Password <span class="text-danger">*</span></label>
        <input type="password" id="confirmPassword" name="confirmPassword" maxlength="72" autocomplete="new-password"
               class="form-control<%= invalidClass(errors, "confirmPassword") %>" <%= errAria(errors, "confirmPassword") %>>
        <%= errText(errors, "confirmPassword") %>
    </div>
</div>
