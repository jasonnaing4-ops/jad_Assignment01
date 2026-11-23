<%@ page import="java.sql.*" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Shared header/nav. Include at the top of every page that
    writes HTML (after a login/staff guard, if that page needs one, so a
    kicked-out user never even flashes this):

        <%@ include file="/WEB-INF/common/header.jsp" %>

    Safe to include on login.jsp too: with no session yet it just shows a
    guest nav with a Login link. Re-looks-up username/role from the DB by the
    userId already in the session - nothing but userId is ever trusted out of
    the session itself. Also brings in esc() (see common/esc.jsp) for the
    rest of the including page to use.

    Uses its own hdrJdbcDriver/hdrConnURL (own copy of the driver/connection
    string, same pattern as common/event_dropdown.jsp) instead of including
    common/dbconfig.jsp itself. This is deliberate: header.jsp is included on
    pages that already included dbconfig.jsp themselves (directly, or via
    require_staff.jsp) as well as on pages that never did (login.jsp). Using
    its own differently-named variables means header.jsp never collides with
    whatever a page already declared, and never depends on include order.

    If you change the DB credentials in common/dbconfig.jsp, update the copy
    below too (same small, deliberate duplication as event_dropdown.jsp).
--%>
<%@ include file="/WEB-INF/common/esc.jsp" %>
<%
    Integer headerUserId = (Integer) session.getAttribute("userId");
    String headerUsername = null;
    String headerRole = null;

    if (headerUserId != null) {
        Connection headerConn = null;
        try {
            String hdrJdbcDriver = "com.mysql.cj.jdbc.Driver";
            String hdrConnURL = "jdbc:mysql://localhost:3306/jad_assignment01_database?user=root&password=jason1224&serverTimezone=UTC";
            Class.forName(hdrJdbcDriver);
            headerConn = DriverManager.getConnection(hdrConnURL);
            String headerSql = "SELECT username, role FROM users WHERE user_id = ?";
            PreparedStatement headerPs = headerConn.prepareStatement(headerSql);
            headerPs.setInt(1, headerUserId);
            ResultSet headerRs = headerPs.executeQuery();
            if (headerRs.next()) {
                headerUsername = headerRs.getString("username");
                headerRole = headerRs.getString("role");
            }
        } catch (Exception e) {
            System.err.println("header.jsp - " + e);
        } finally {
            if (headerConn != null) {
                try { headerConn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Vision Screening Station Management System</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body class="bg-light">
<nav class="navbar navbar-dark bg-brand">
    <div class="container-fluid px-4">
        <span class="navbar-brand fw-bold mb-0">Vision Screening Station Management System</span>
        <div class="d-flex flex-wrap align-items-center gap-3">
            <% if (headerUserId != null) { %>
                <% if ("staff".equals(headerRole)) { %>
     			<% boolean onEventPages = request.getRequestURI().contains("/event/"); %>
    				<a class="nav-link text-white rounded-pill px-3 py-1 text-decoration-underline link-underline link-underline-light link-underline-opacity-0 link-underline-opacity-100-hover<%= onEventPages ? " bg-white bg-opacity-25 fw-semibold" : "" %>"
       				<%= onEventPages ? "aria-current=\"page\"" : "" %>
       				href="<%= request.getContextPath() %>/event/list_events.jsp">Manage Events</a>
       				<% boolean onParticipantPages = request.getRequestURI().contains("/participant/"); %>
					<a class="nav-link text-white rounded-pill px-3 py-1 text-decoration-underline link-underline link-underline-light link-underline-opacity-0 link-underline-opacity-100-hover<%= onParticipantPages ? " bg-white bg-opacity-25 fw-semibold" : "" %>"
					<%= onParticipantPages ? "aria-current=\"page\"" : "" %>
					href="<%= request.getContextPath() %>/participant/list_participants.jsp">Manage Participants</a>
                <% } else { %>
                    <a class="nav-link text-white" href="<%= request.getContextPath() %>/home/home.jsp">Home</a>
                    <a class="nav-link text-white" href="<%= request.getContextPath() %>/account/my_signups.jsp">My Events</a>
					<a class="nav-link text-white" href="<%= request.getContextPath() %>/account/my_account.jsp">My Account</a>
                <% } %>
				<span class="rounded-pill border border-white border-opacity-25 bg-white bg-opacity-10 text-white fst-italic px-3 py-1">
    				Welcome, <%= esc(headerUsername) %>
				</span>
				<a class="btn btn-danger rounded-pill px-3 py-1" href="<%= request.getContextPath() %>/login/logout.jsp">Logout</a>
            <% } else { %>
                <a class="nav-link text-white" href="<%= request.getContextPath() %>/login/login.jsp">Login</a>
                <a class="nav-link text-white" href="<%= request.getContextPath() %>/login/register.jsp">Create Account</a>
            <% } %>
        </div>
    </div>
</nav>
<main class="container my-4">
<div class="card shadow-sm">
<div class="card-body p-4">