<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Landing page for PARTICIPANTS after login (staff skip this
    page - login_okay.jsp sends them straight to Event Management, and a staff
    user who opens this URL is redirected there too). The login guard
    (section 2.5) runs before anything else, then the page re-looks-up the
    user's own details by userId rather than trusting anything but the id out
    of the session.
--%>
<%
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        response.sendRedirect("../login/login.jsp?errCode=notLoggedIn");
        return;
    }
%>
<%@ include file="/WEB-INF/common/dbconfig.jsp" %>
<%
    String role = null;
    String displayName = null;
    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        String sql = "SELECT username, role FROM users WHERE user_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, userId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            role = rs.getString("role");
            displayName = rs.getString("username");
        }

        if ("participant".equals(role)) {
            String nameSql = "SELECT full_name FROM participants WHERE user_id = ?";
            PreparedStatement namePs = conn.prepareStatement(nameSql);
            namePs.setInt(1, userId);
            ResultSet nameRs = namePs.executeQuery();
            if (nameRs.next()) {
                displayName = nameRs.getString("full_name");
            }
        }
    } catch (Exception e) {
        System.err.println("home.jsp - " + e);
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }

    // Staff have no home page - Event Management is their landing page
    if ("staff".equals(role)) {
        response.sendRedirect("../event/list_events.jsp");
        return;
    }

    String errCode = request.getParameter("errCode");
    String errMessage = null;
    if (errCode != null && errCode.equals("notAuthorized")) {
        errMessage = "You do not have access to that page.";
    }
%>
<%@ include file="/WEB-INF/common/header.jsp" %>

<h1 class="h2 text-primary mb-3">Welcome, <%= esc(displayName) %></h1>
<p>You are signed in as <strong><%= esc(role) %></strong>.</p>

<% if (errMessage != null) { %>
    <div class="alert alert-danger"><%= esc(errMessage) %></div>
<% } %>

<p class="fst-italic text-muted">Participant self-service pages (browse events, sign up, view/edit your own record) are being built separately.</p>

<%@ include file="/WEB-INF/common/footer.jsp" %>