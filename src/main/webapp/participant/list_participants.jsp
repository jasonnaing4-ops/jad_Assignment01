<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Staff-only participant list (section 3.2). Same layout as
    event/list_events.jsp: stat-tabs (All / Active / Inactive, with counts)
    that also filter the table, plus a GET search box on name or participant
    code that stays within the selected tab. Each row has Edit and
    Activate / Deactivate. Activate is a direct one-click action (reversible);
    Deactivate goes through confirm_participant_action.jsp first
    (list -> confirm -> action -> redirect pattern, section 7).
--%>
<%!
    // Escapes the LIKE wildcards % and _ so a search for "50%" matches that text
    private String likeEscape(String s) {
        return s.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }
%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>
<%@ include file="/WEB-INF/common/header.jsp" %>
<%
    // Which tab is selected - default to "all" if missing/invalid
    String filter = request.getParameter("filter");
    if (filter == null || !(filter.equals("all") || filter.equals("active") || filter.equals("inactive"))) {
        filter = "all";
    }

    String searchQuery = request.getParameter("q");
    if (searchQuery == null) { searchQuery = ""; }
    searchQuery = searchQuery.trim();
    String searchLinkPart = searchQuery.isEmpty() ? "" : "&q=" + java.net.URLEncoder.encode(searchQuery, "UTF-8");
%>

<h1 class="h2 text-primary mb-4">Participant Management</h1>

<div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
    <a href="add_participant.jsp" class="btn btn-primary rounded-pill shadow-sm btn-create">Add Participant</a>
    <form method="get" action="list_participants.jsp" class="d-flex gap-2" role="search">
        <input type="hidden" name="filter" value="<%= esc(filter) %>">
        <label for="q" class="visually-hidden">Search by name or participant code</label>
        <input type="text" id="q" name="q" maxlength="100" class="form-control rounded-pill" placeholder="Search by name or code" value="<%= esc(searchQuery) %>">
        <button type="submit" class="btn btn-primary rounded-pill px-4">Search</button>
    </form>
</div>

<%@ include file="/WEB-INF/common/messages.jsp" %>

<%
    // Tab counts: own connection, so a failure here (counts fall back to 0)
    // cannot affect the main table below
    int allCount = 0, activeCount = 0, inactiveCount = 0;
    Connection statsConn = null;
    try {
        Class.forName(jdbcDriver);
        statsConn = DriverManager.getConnection(connURL);
        // No user input in this query - a plain Statement is fine (section 6)
        Statement countStmt = statsConn.createStatement();
        ResultSet countRs = countStmt.executeQuery(
                "SELECT COUNT(*) AS total, SUM(u.status = 'active') AS act, SUM(u.status = 'inactive') AS inact "
              + "FROM participants p JOIN users u ON u.user_id = p.user_id");
        if (countRs.next()) {
            allCount = countRs.getInt("total");
            activeCount = countRs.getInt("act");
            inactiveCount = countRs.getInt("inact");
        }
    } catch (Exception e) {
        System.err.println("list_participants.jsp (stat counts) - " + e);
    } finally {
        if (statsConn != null) {
            try { statsConn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>

<div class="row g-3 mb-4">
    <div class="col-4">
        <a class="card stat-card h-100 text-decoration-none shadow-sm <%= filter.equals("all") ? "border border-2 border-dark" : "border-0" %>" href="list_participants.jsp?filter=all<%= searchLinkPart %>">
            <div class="card-body d-flex align-items-center gap-3">
                <span class="stat-indicator bg-dark"></span>
                <span class="d-flex flex-column">
                    <span class="fs-4 fw-bold text-dark lh-1"><%= allCount %></span>
                    <span class="small text-muted">All</span>
                </span>
            </div>
        </a>
    </div>
    <div class="col-4">
        <a class="card stat-card h-100 text-decoration-none shadow-sm <%= filter.equals("active") ? "border border-2 border-success" : "border-0" %>" href="list_participants.jsp?filter=active<%= searchLinkPart %>">
            <div class="card-body d-flex align-items-center gap-3">
                <span class="stat-indicator bg-success"></span>
                <span class="d-flex flex-column">
                    <span class="fs-4 fw-bold text-dark lh-1"><%= activeCount %></span>
                    <span class="small text-muted">Active</span>
                </span>
            </div>
        </a>
    </div>
    <div class="col-4">
        <a class="card stat-card h-100 text-decoration-none shadow-sm <%= filter.equals("inactive") ? "border border-2 border-secondary" : "border-0" %>" href="list_participants.jsp?filter=inactive<%= searchLinkPart %>">
            <div class="card-body d-flex align-items-center gap-3">
                <span class="stat-indicator bg-secondary"></span>
                <span class="d-flex flex-column">
                    <span class="fs-4 fw-bold text-dark lh-1"><%= inactiveCount %></span>
                    <span class="small text-muted">Inactive</span>
                </span>
            </div>
        </a>
    </div>
</div>

<div class="table-responsive">
<table class="table table-bordered table-hover align-middle">
    <caption class="visually-hidden">List of participants</caption>
    <thead class="table-light">
        <tr>
            <th scope="col">Code</th>
            <th scope="col">Full Name</th>
            <th scope="col">Contact No.</th>
            <th scope="col">Email</th>
            <th scope="col">Sign-ups</th>
            <th scope="col">Status</th>
            <th scope="col">Actions</th>
        </tr>
    </thead>
    <tbody>
<%
    Connection conn = null;
    int rowCount = 0;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        // Only fixed text is joined into the SQL; the search text only ever
        // goes in through the ? placeholders (section 6)
        String sql = "SELECT p.participant_id, p.participant_code, p.full_name, p.contact_no, p.email, u.status, "
                   + "COUNT(r.registration_id) AS signups "
                   + "FROM participants p "
                   + "JOIN users u ON u.user_id = p.user_id "
                   + "LEFT JOIN event_registrations r ON r.participant_id = p.participant_id AND r.status = 'registered' "
                   + "WHERE 1 = 1";
        if (filter.equals("active")) { sql += " AND u.status = 'active'"; }
        else if (filter.equals("inactive")) { sql += " AND u.status = 'inactive'"; }
        if (!searchQuery.isEmpty()) {
            sql += " AND (p.full_name LIKE ? OR p.participant_code LIKE ?)";
        }
        sql += " GROUP BY p.participant_id, p.participant_code, p.full_name, p.contact_no, p.email, u.status"
             + " ORDER BY p.full_name";

        PreparedStatement ps = conn.prepareStatement(sql);
        if (!searchQuery.isEmpty()) {
            String like = "%" + likeEscape(searchQuery) + "%";
            ps.setString(1, like);
            ps.setString(2, like);
        }
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            rowCount++;
            int rowId = rs.getInt("participant_id");
            boolean rowActive = "active".equals(rs.getString("status"));
%>
        <tr>
            <td class="fw-semibold"><%= esc(rs.getString("participant_code")) %></td>
            <td><%= esc(rs.getString("full_name")) %></td>
            <td><%= esc(rs.getString("contact_no")) %></td>
            <td class="text-break"><%= esc(rs.getString("email")) %></td>
            <td class="text-center"><span class="badge rounded-pill text-bg-primary"><%= rs.getInt("signups") %></span></td>
            <td><span class="badge rounded-pill <%= rowActive ? "text-bg-success" : "text-bg-secondary" %>"><%= rowActive ? "active" : "inactive" %></span></td>
            <td>
                <div class="d-flex flex-wrap align-items-center gap-2">
                    <a href="edit_participant.jsp?id=<%= rowId %>" class="btn btn-sm text-success-emphasis bg-success-subtle border-success-subtle">View / Edit</a>
                    <% if (rowActive) { %>
                        <form method="post" action="confirm_participant_action.jsp" class="m-0">
                            <input type="hidden" name="id" value="<%= rowId %>">
                            <input type="hidden" name="mode" value="deactivate">
                            <button type="submit" class="btn btn-sm btn-danger">Deactivate</button>
                        </form>
                    <% } else { %>
                        <form method="post" action="participant_status_action.jsp" class="m-0">
                            <input type="hidden" name="id" value="<%= rowId %>">
                            <input type="hidden" name="mode" value="activate">
                            <button type="submit" class="btn btn-sm btn-primary">Activate</button>
                        </form>
                    <% } %>
                </div>
            </td>
        </tr>
<%
        }
        if (rowCount == 0) {
%>
        <tr><td colspan="7" class="text-muted">No participants match your search.</td></tr>
<%
        }
    } catch (Exception e) {
        System.err.println("list_participants.jsp - " + e);
%>
        <tr><td colspan="7">Could not load participants right now.</td></tr>
<%
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>
    </tbody>
</table>
</div>

<%@ include file="/WEB-INF/common/footer.jsp" %>
