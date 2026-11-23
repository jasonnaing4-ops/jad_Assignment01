<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Login form. Pure display page - the only parameters it reads
    are errCode and msg, to explain why the last attempt failed or that the
    user was just logged out. All actual processing happens in login_okay.jsp.
--%>
<%@ include file="/WEB-INF/common/header.jsp" %>
<%
    String errCode = request.getParameter("errCode");
    String errMessage = null;
    if (errCode != null) {
        if (errCode.equals("emptyFields")) {
            errMessage = "Please enter both your username and password.";
        } else if (errCode.equals("badLogin")) {
            errMessage = "Username or password is incorrect.";
        } else if (errCode.equals("accountInactive")) {
            errMessage = "This account has been deactivated. Please contact staff.";
        } else if (errCode.equals("notLoggedIn")) {
            errMessage = "Please log in to continue.";
        } else if (errCode.equals("dbError")) {
            errMessage = "Something went wrong. Please try again.";
        }
    }

    String msg = request.getParameter("msg");
    String infoMessage = null;
    if (msg != null) {
        if (msg.equals("loggedOut")) {
            infoMessage = "You have been logged out.";
        }
    }
%>
<h1 class="h2 text-primary text-center mb-4">Login</h1>

<% if (errMessage != null) { %>
    <div class="alert alert-danger mx-auto" style="max-width: 420px;"><%= esc(errMessage) %></div>
<% } %>
<% if (infoMessage != null) { %>
    <div class="alert alert-success mx-auto" style="max-width: 420px;"><%= esc(infoMessage) %></div>
<% } %>

<form method="post" action="login_okay.jsp" class="card shadow-sm mx-auto" style="max-width: 420px;">
    <div class="card-body p-4">
        <div class="mb-3">
            <label for="username" class="form-label fw-semibold">Username</label>
            <input type="text" id="username" name="username" class="form-control" required>
        </div>

        <div class="mb-3">
            <label for="password" class="form-label fw-semibold">Password</label>
            <input type="password" id="password" name="password" class="form-control" required>
        </div>

        <button type="submit" class="btn btn-primary w-100">Log In</button>
    </div>
</form>

<%@ include file="/WEB-INF/common/footer.jsp" %>
