<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Decision page for login - writes no HTML, every path ends in
    a redirect. Checks the submitted credentials against
    users.password_hash with PasswordUtil (bcrypt) and starts the session
  	success.
--%>
<%@ include file="/WEB-INF/common/dbconfig.jsp" %>
<%
//Input Validation: ensure username and password exist and are not blank    
	String username = request.getParameter("username");
    String password = request.getParameter("password");
    if (username == null || password == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    if (username.trim().isEmpty() || password.trim().isEmpty()) {
        response.sendRedirect("login.jsp?errCode=emptyFields");
        return;
    }

 // Database Lookup: query users table for the matching username    
 	Connection conn = null;
    try {
    	// Load JDBC driver and open a connection to the database
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        String sql = "SELECT user_id, password_hash, status, role, must_change_password FROM users WHERE username = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, username.trim());
        ResultSet rs = ps.executeQuery();

     // Verification & Redirect: check password hash and status, start session, and route by role
        if (rs.next()) {
            int foundUserId = rs.getInt("user_id");
            String storedHash = rs.getString("password_hash");
            String status = rs.getString("status");
            String role = rs.getString("role");
            boolean mustChange = rs.getBoolean("must_change_password");

            if (!util.PasswordUtil.verify(password, storedHash)) {
                response.sendRedirect("login.jsp?errCode=badLogin");
                return;
            }
         
            if (!"active".equals(status)) {
                response.sendRedirect("login.jsp?errCode=accountInactive");
                return;
            }
            request.changeSessionId();
            session.setAttribute("userId", foundUserId);
            // Staff go straight to Event Management; participants to their own page
            if ("staff".equals(role)) {
                response.sendRedirect("../event/list_events.jsp");
            } else if (mustChange) {
                response.sendRedirect("../account/change_password.jsp");
            } else {
            	response.sendRedirect("../account/my_signups.jsp");
            }
            return;
        } else {
            response.sendRedirect("login.jsp?errCode=badLogin");
            return;
        }
    } catch (Exception e) {
    	// Error Handling & Cleanup: log exceptions, redirect on error, and close connection
        System.err.println("login_okay.jsp - " + e);
        response.sendRedirect("login.jsp?errCode=dbError");
        return;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>