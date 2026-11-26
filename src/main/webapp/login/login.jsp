<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Login form. Pure display page - the only parameters it reads
    are errCode and msg, to explain why the last attempt failed or that the
    user was just logged out. All actual processing happens in login_okay.jsp.
--%>
<%@ include file="/WEB-INF/common/dbconfig.jsp" %>
<%
	//Check if the user already has an active session
    if (session.getAttribute("userId") != null) {
    	Integer userId = (Integer) session.getAttribute("userId");
    	String role = null;
    	Connection conn = null;
        try {
        	// Establish database connection and fetch the user's current role
            Class.forName(jdbcDriver);
            conn = DriverManager.getConnection(connURL);

            String sql = "SELECT role FROM users WHERE user_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                role = rs.getString("role");
            }

         // Redirect already-logged-in users to their respective dashboards
            if ("participant".equals(role)) {
    			response.sendRedirect("../account/my_signups.jsp");
    			return;
            }
            
            if ("staff".equals(role)) {
                response.sendRedirect("../event/list_events.jsp");
                return;
            }
            
        } catch (Exception e) {
        	// Log any database or connection errors to the server console
            System.err.println("login.jsp - " + e);
        } finally {
        	// Ensure the database connection is closed to prevent resource leaks
            if (conn != null) {
                try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
            }
    }
   }
%>
<%-- Include global navigation bar and page layout header --%>
<%@ include file="/WEB-INF/common/header.jsp" %>
<%
//Map URL error codes (from login_okay.jsp or auth checks) to user-friendly error messages
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
        } else if (errCode.equals("sessionExpired")) {
        	errMessage = "Your session has expired. Please log in again.";
        } else if (errCode.equals("dbError")) {
            errMessage = "Something went wrong. Please try again.";
        }
    }

 // Map URL status messages to user-friendly informational alerts
    String msg = request.getParameter("msg");
    String infoMessage = null;
    if (msg != null) {
        if (msg.equals("loggedOut")) {
            infoMessage = "You have been logged out.";
        } else if (msg.equals("accountCreated")) {
        	infoMessage = "Your account was created. Please log in.";
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
        <p class="text-center small mt-3 mb-0">New here? <a href="register.jsp">Create an account</a></p>
    </div>
</form>

<%@ include file="/WEB-INF/common/footer.jsp" %>
