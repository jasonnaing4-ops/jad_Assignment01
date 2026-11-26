<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Decision page for login - writes no HTML, every path ends in
    a redirect (section 2). Checks the submitted credentials against
    users.password_hash with PasswordUtil (bcrypt) and starts the session
    (userId only, section 2.5) on success.
--%>
<%@ include file="/WEB-INF/common/dbconfig.jsp" %>
<%
    // Step 1: Existence
    String username = request.getParameter("username");
    String password = request.getParameter("password");
    if (username == null || password == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Step 2: Validate
    if (username.trim().isEmpty() || password.trim().isEmpty()) {
        response.sendRedirect("login.jsp?errCode=emptyFields");
        return;
    }

    // Step 3: Authentication and Session Initialization
    Connection conn = null;
    try {
    	// Load JDBC driver and open a connection to the database
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        
        String sql = "SELECT user_id, password_hash, status, role FROM users WHERE username = ?";        
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, username.trim());
        ResultSet rs = ps.executeQuery();

        if (rs.next()) {
            int foundUserId = rs.getInt("user_id");
            String storedHash = rs.getString("password_hash");
            String status = rs.getString("status");
            String role = rs.getString("role");

         // Verify submitted plaintext password against the stored bcrypt hash.
            if (!util.PasswordUtil.verify(password, storedHash)) {
                response.sendRedirect("login.jsp?errCode=badLogin");
                return;
            }
         
         // Block login if the account has been deactivated by staff
            if (!"active".equals(status)) {
                response.sendRedirect("login.jsp?errCode=accountInactive");
                return;
            }

            session.setAttribute("userId", foundUserId);
            // Staff go straight to Event Management; participants to their own page
            if ("staff".equals(role)) {
                response.sendRedirect("../event/list_events.jsp");
            } else {
            	response.sendRedirect("../account/my_signups.jsp");
            }
            return;
        } else {
            response.sendRedirect("login.jsp?errCode=badLogin");
            return;
        }
    } catch (Exception e) {
        System.err.println("login_okay.jsp - " + e);
        response.sendRedirect("login.jsp?errCode=dbError");
        return;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>