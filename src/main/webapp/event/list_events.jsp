<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Staff-only event list (section 3.3). Shows every event with
    its status and gives Edit / Activate-Deactivate / Delete actions per row.
    Activate is a direct one-click action (reversible, no confirmation
    needed); Deactivate and Delete go through confirm_event_action.jsp first
    (L03c list -> confirm -> action -> redirect pattern, section 7).

    Also shows 4 stat-tabs (Completed / Ongoing / Upcoming / Inactive) with a
    count on each, used both as the filter for the table below and as an
    at-a-glance summary. Completed/Ongoing/Upcoming are all status='active'
    events, split by comparing event_date to today's date (events only have a
    single date, not a start/end range); Inactive is status='inactive'
    regardless of date. Defaults to "upcoming" if no/invalid filter param is
    given. A GET search box filters further by event_name (LIKE match),
    staying within whichever tab is currently selected.
--%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>
<%@ include file="/WEB-INF/common/header.jsp" %>

<%
    String msg = request.getParameter("msg");
    String infoMessage = null;
    if (msg != null) {
        if (msg.equals("eventAdded")) { infoMessage = "Event added."; }
        else if (msg.equals("eventUpdated")) { infoMessage = "Event updated."; }
        else if (msg.equals("eventDeleted")) { infoMessage = "Event deleted."; }
        else if (msg.equals("eventDeactivated")) { infoMessage = "Event deactivated."; }
        else if (msg.equals("eventActivated")) { infoMessage = "Event activated."; }
    }

    String errCode = request.getParameter("errCode");
    String errMessage = null;
    if (errCode != null) {
        if (errCode.equals("hasRegistrations")) { errMessage = "That event has participants registered and cannot be deleted. Deactivate it instead."; }
        else if (errCode.equals("notFound")) { errMessage = "That event could not be found - it may already have been removed."; }
        else if (errCode.equals("invalidAction")) { errMessage = "That request was not valid. Please try again from this page."; }
        else if (errCode.equals("dbError")) { errMessage = "Something went wrong. Please try again."; }
    }
    
    // Which stat-tab is selected - default to "all" if missing/invalid
    String filter = request.getParameter("filter");
    if (filter == null || !(filter.equals("all") || filter.equals("completed") || filter.equals("ongoing")
            || filter.equals("upcoming") || filter.equals("inactive"))) {
        filter = "all";
    }

    // Optional search-by-name, kept across tab clicks via the hidden filter field
    String searchQuery = request.getParameter("q");
    if (searchQuery == null) { searchQuery = ""; }
    searchQuery = searchQuery.trim();

    // searchQuery appended to each tab link so switching tabs doesn't lose a search
    String searchLinkPart = searchQuery.isEmpty() ? "" : "&q=" + java.net.URLEncoder.encode(searchQuery, "UTF-8");
%>

<h1 class="h2 text-primary mb-4">Event Management</h1>

<div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
    <a href="add_event.jsp" class="btn btn-primary rounded-pill shadow-sm btn-create">Create Event</a>
    <form method="get" action="list_events.jsp" class="d-flex gap-2">
        <input type="hidden" name="filter" value="<%= esc(filter) %>">
        <input type="text" name="q" class="form-control rounded-pill" placeholder="Search by event name" value="<%= esc(searchQuery) %>">
        <button type="submit" class="btn btn-primary rounded-pill px-4">Search</button>
    </form>
</div>

<% if (infoMessage != null) { %><div class="alert alert-success"><%= esc(infoMessage) %></div><% } %>
<% if (errMessage != null) { %><div class="alert alert-danger"><%= esc(errMessage) %></div><% } %>

<%
    // Self-contained block with its own connection, kept separate from the
    // main listing query below - so a failure here (counts just fall back to
    // 0) can never interfere with the main table's own try/catch/finally.
    int allCount = 0, completedCount = 0, ongoingCount = 0, upcomingCount = 0, inactiveCount = 0;
    Connection statsConn = null;
    try {
        Class.forName(jdbcDriver);
        statsConn = DriverManager.getConnection(connURL);

        // No user input in any of these 4 - a plain Statement is fine (section 6)
        Statement countStmt = statsConn.createStatement();
        ResultSet countRs;
        
        countRs = countStmt.executeQuery("SELECT COUNT(*) FROM events");
        if (countRs.next()) { allCount = countRs.getInt(1); }

        countRs = countStmt.executeQuery("SELECT COUNT(*) FROM events WHERE status = 'active' AND event_date < CURDATE()");
        if (countRs.next()) { completedCount = countRs.getInt(1); }

        countRs = countStmt.executeQuery("SELECT COUNT(*) FROM events WHERE status = 'active' AND event_date = CURDATE()");
        if (countRs.next()) { ongoingCount = countRs.getInt(1); }

        countRs = countStmt.executeQuery("SELECT COUNT(*) FROM events WHERE status = 'active' AND event_date > CURDATE()");
        if (countRs.next()) { upcomingCount = countRs.getInt(1); }

        countRs = countStmt.executeQuery("SELECT COUNT(*) FROM events WHERE status = 'inactive'");
        if (countRs.next()) { inactiveCount = countRs.getInt(1); }
    } catch (Exception e) {
        System.err.println("list_events.jsp (stat counts) - " + e);
    } finally {
        if (statsConn != null) {
            try { statsConn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>

<div class="row g-3 mb-4">
	    <div class="col-6 col-lg">
        <a class="card stat-card h-100 text-decoration-none shadow-sm <%= filter.equals("all") ? "border border-2 border-dark" : "border-0" %>" href="list_events.jsp?filter=all<%= searchLinkPart %>">
            <div class="card-body d-flex align-items-center gap-3">
                <span class="stat-indicator bg-dark"></span>
                <span class="d-flex flex-column">
                    <span class="fs-4 fw-bold text-dark lh-1"><%= allCount %></span>
                    <span class="small text-muted">All</span>
                </span>
            </div>
        </a>
    </div>
    
    <div class="col-6 col-lg">
        <a class="card stat-card h-100 text-decoration-none shadow-sm <%= filter.equals("completed") ? "border border-2 border-success" : "border-0" %>" href="list_events.jsp?filter=completed<%= searchLinkPart %>">
            <div class="card-body d-flex align-items-center gap-3">
                <span class="stat-indicator bg-success"></span>
                <span class="d-flex flex-column">
                    <span class="fs-4 fw-bold text-dark lh-1"><%= completedCount %></span>
                    <span class="small text-muted">Completed</span>
                </span>
            </div>
        </a>
    </div>
    <div class="col-6 col-lg">
        <a class="card stat-card h-100 text-decoration-none shadow-sm <%= filter.equals("ongoing") ? "border border-2 border-warning" : "border-0" %>" href="list_events.jsp?filter=ongoing<%= searchLinkPart %>">
            <div class="card-body d-flex align-items-center gap-3">
                <span class="stat-indicator bg-warning"></span>
                <span class="d-flex flex-column">
                    <span class="fs-4 fw-bold text-dark lh-1"><%= ongoingCount %></span>
                    <span class="small text-muted">Ongoing</span>
                </span>
            </div>
        </a>
    </div>
    <div class="col-6 col-lg">
        <a class="card stat-card h-100 text-decoration-none shadow-sm <%= filter.equals("upcoming") ? "border border-2 border-primary" : "border-0" %>" href="list_events.jsp?filter=upcoming<%= searchLinkPart %>">
            <div class="card-body d-flex align-items-center gap-3">
                <span class="stat-indicator bg-primary"></span>
                <span class="d-flex flex-column">
                    <span class="fs-4 fw-bold text-dark lh-1"><%= upcomingCount %></span>
                    <span class="small text-muted">Upcoming</span>
                </span>
            </div>
        </a>
    </div>
    <div class="col-6 col-lg">
        <a class="card stat-card h-100 text-decoration-none shadow-sm <%= filter.equals("inactive") ? "border border-2 border-secondary" : "border-0" %>" href="list_events.jsp?filter=inactive<%= searchLinkPart %>">
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
    <thead class="table-light">
        <tr>
            <th>Event Name</th>
            <th>Date</th>
            <th>Start Time</th>
            <th>End Time</th>
            <th>Venue</th>
            <th>Description</th>
            <th>Status</th>
            <th>Signed Up</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
<%
    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        String whereClause;
        if (filter.equals("all")) {
            whereClause = "1 = 1";
        } else if (filter.equals("completed")) {
            whereClause = "e.status = 'active' AND e.event_date < CURDATE()";
        } else if (filter.equals("ongoing")) {
            whereClause = "e.status = 'active' AND e.event_date = CURDATE()";
        } else if (filter.equals("inactive")) {
            whereClause = "e.status = 'inactive'";
        } else {
            whereClause = "e.status = 'active' AND e.event_date > CURDATE()";
        }

        String sql = "SELECT e.event_id, e.event_name, e.event_date, e.venue, e.status, e.start_time, e.end_time, e.description, "
                + "COUNT(r.registration_id) AS signed_up "
                + "FROM events e "
                + "LEFT JOIN event_registrations r ON r.event_id = e.event_id AND r.status = 'registered' "
                + "WHERE " + whereClause;
	     if (!searchQuery.isEmpty()) {
	         sql += " AND e.event_name LIKE ?";
	     }
	     sql += " GROUP BY e.event_id, e.event_name, e.event_date, e.venue, e.status, e.start_time, e.end_time, e.description"
	          + " ORDER BY e.event_date";

        PreparedStatement ps = conn.prepareStatement(sql);
        if (!searchQuery.isEmpty()) {
            ps.setString(1, "%" + searchQuery + "%");
        }
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            String rowStatus = rs.getString("status");
            int rowEventId = rs.getInt("event_id");
            boolean rowActive = "active".equals(rowStatus);
            // time columns are NULL for events created before times existed
            java.sql.Time rowStart = rs.getTime("start_time");
            java.sql.Time rowEnd = rs.getTime("end_time");
            String rowDescription = rs.getString("description");
%>
        <tr>
            <td><%= esc(rs.getString("event_name")) %></td>
            <td><%= rs.getDate("event_date") %></td>
            <td><%= rowStart != null ? rowStart.toString().substring(0, 5) : "-" %></td>
            <td><%= rowEnd != null ? rowEnd.toString().substring(0, 5) : "-" %></td>
            <td><%= esc(rs.getString("venue")) %></td>
            <td class="text-break" style="max-width: 220px;"><%= (rowDescription == null || rowDescription.isEmpty()) ? "-" : esc(rowDescription) %></td>
            <td><%= esc(rowStatus) %></td>
            <td class="text-center"><span class="badge rounded-pill text-bg-primary"><%= rs.getInt("signed_up") %></span></td>
            <td>
                <div class="d-flex flex-wrap align-items-center gap-2">
                    <a href="edit_event.jsp?id=<%= rowEventId %>" class="btn btn-sm text-success-emphasis bg-success-subtle border-success-subtle">Edit</a>

                    <% if (rowActive) { %>
                        <form method="post" action="confirm_event_action.jsp" class="m-0">
                            <input type="hidden" name="id" value="<%= rowEventId %>">
                            <input type="hidden" name="mode" value="deactivate">
                            <button type="submit" class="btn btn-sm btn-primary">Deactivate</button>
                        </form>
                    <% } else { %>
                        <form method="post" action="event_status_action.jsp" class="m-0">
                            <input type="hidden" name="id" value="<%= rowEventId %>">
                            <input type="hidden" name="mode" value="activate">
                            <button type="submit" class="btn btn-sm btn-primary">Activate</button>
                        </form>
                    <% } %>

                    <form method="post" action="confirm_event_action.jsp" class="m-0">
                        <input type="hidden" name="id" value="<%= rowEventId %>">
                        <input type="hidden" name="mode" value="delete">
                        <button type="submit" class="btn btn-sm btn-danger">Delete</button>
                    </form>
                </div>
            </td>
        </tr>
<%
        }
    } catch (Exception e) {
        System.err.println("list_events.jsp - " + e);
%>
        <tr><td colspan="9">Could not load events right now.</td></tr>
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