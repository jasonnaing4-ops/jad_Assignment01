<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.Map" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Public "create an account" form (section 3.2) - a member of
    the public registers themselves as a participant. Pure display page -
    register_okay.jsp does the checks and the insert. If it rejects the input
    it FORWARDS back here (not a redirect), so the typed values and the
    errors map are still in the request and no personal details go into the
    URL. Passwords are never put back into the form.
--%>
<%
    // Someone who is already logged in does not need a new account
    if (session.getAttribute("userId") != null) {
        response.sendRedirect(request.getContextPath() + "/home/home.jsp");
        return;
    }

    @SuppressWarnings("unchecked")
    Map<String, String> errors = (Map<String, String>) request.getAttribute("errors");

    // null on a first visit, the typed values after a rejected submit
    String fUsername = request.getParameter("username");
    String fFullName = request.getParameter("fullName");
    String fContactNo = request.getParameter("contactNo");
    String fEmail = request.getParameter("email");
    String fDob = request.getParameter("dateOfBirth");
    String fGender = request.getParameter("gender");
%>
<%@ include file="/WEB-INF/common/header.jsp" %>
<%@ include file="/WEB-INF/common/form_helpers.jsp" %>

<h1 class="h2 text-primary text-center mb-2">Create an Account</h1>
<p class="text-center text-muted mb-4">Sign up to see screening events and register for them. Fields marked <span class="text-danger">*</span> are required.</p>

<div class="mx-auto" style="max-width: 640px;">
    <%@ include file="/WEB-INF/common/messages.jsp" %>

    <%-- novalidate: the server checks every field, so the user always gets the same, specific messages --%>
    <form method="post" action="<%= request.getContextPath() %>/login/register_okay.jsp" class="card shadow-sm" novalidate>
        <div class="card-body p-4">
            <h2 class="h5 mb-3">Your Details</h2>
            <%@ include file="/WEB-INF/common/participant_fields.jsp" %>

            <h2 class="h5 mt-4 mb-3">Login Details</h2>
            <%@ include file="/WEB-INF/common/account_fields.jsp" %>

            <div class="d-flex align-items-center gap-3">
                <button type="submit" class="btn btn-primary">Create Account</button>
                <a href="<%= request.getContextPath() %>/login/login.jsp" class="btn btn-link text-secondary text-decoration-none">Cancel</a>
            </div>
        </div>
    </form>
</div>

<%@ include file="/WEB-INF/common/footer.jsp" %>
