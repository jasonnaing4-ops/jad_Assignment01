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

    // Sort order - whitelist only; the parameter value is never put into SQL itself
    String sort = request.getParameter("sort");
    String orderBy;
    if ("dateDesc".equals(sort)) {
        orderBy = "e.event_date DESC, e.start_time DESC, e.event_id";
    } else if ("timeAsc".equals(sort)) {
        orderBy = "e.start_time IS NULL, e.start_time ASC, e.event_date ASC, e.event_id";
    } else if ("timeDesc".equals(sort)) {
        orderBy = "e.start_time IS NULL, e.start_time DESC, e.event_date ASC, e.event_id";
    } else if ("signupsAsc".equals(sort)) {
        orderBy = "signed_up ASC, e.event_date ASC, e.event_id";
    } else if ("signupsDesc".equals(sort)) {
        orderBy = "signed_up DESC, e.event_date ASC, e.event_id";
    } else {
        sort = "dateAsc";
        orderBy = "e.event_date ASC, e.start_time ASC, e.event_id";
    }

    // tab links keep the chosen sort (but not a search)
    String searchLinkPart = "dateAsc".equals(sort) ? "" : "&sort=" + sort;
    
    // Pagination: requested page (clamped once the total is known)
    int pageSize = 10;
    int pageNum = 1;
    try { pageNum = Integer.parseInt(request.getParameter("p")); } catch (Exception e) { pageNum = 1; }
    if (pageNum < 1) { pageNum = 1; }
    int totalRows = 0;
    int totalPages = 1;

    // A search covers every category; otherwise the selected tab decides
    String whereClause;
    if (!searchQuery.isEmpty() || filter.equals("all")) {
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
%>

<h1 class="h2 text-primary mb-4">Event Management</h1>

<div class="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-3">
    <form method="get" action="list_events.jsp" class="d-flex flex-wrap align-items-center gap-2 m-0" id="searchForm">
        <input type="text" id="searchInput" name="q" class="form-control rounded-pill w-auto" placeholder="Search by event name" value="<%= esc(searchQuery) %>" autocomplete="off">
        <select name="sort" id="sortSelect" class="form-select rounded-pill w-auto">
            <option value="dateAsc" <%= sort.equals("dateAsc") ? "selected" : "" %>>Date: earliest first</option>
            <option value="dateDesc" <%= sort.equals("dateDesc") ? "selected" : "" %>>Date: latest first</option>
            <option value="timeAsc" <%= sort.equals("timeAsc") ? "selected" : "" %>>Time: morning first</option>
            <option value="timeDesc" <%= sort.equals("timeDesc") ? "selected" : "" %>>Time: evening first</option>
            <option value="signupsAsc" <%= sort.equals("signupsAsc") ? "selected" : "" %>>Sign-ups: least to most</option>
            <option value="signupsDesc" <%= sort.equals("signupsDesc") ? "selected" : "" %>>Sign-ups: most to least</option>
        </select>
        <button type="submit" class="btn btn-primary rounded-pill px-4">Search</button>
        <a href="list_events.jsp" id="clearBtn" class="btn btn-outline-secondary rounded-pill px-4<%= searchQuery.isEmpty() ? " d-none" : "" %>">Clear</a>
    </form>

    <a href="add_event.jsp" class="btn btn-primary rounded-pill shadow-sm btn-create">Create Event</a>
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
        
        countRs = countStmt.executeQuery("SELECT COUNT(*) FROM events WHERE status = 'inactive'");
        if (countRs.next()) { inactiveCount = countRs.getInt(1); }

        // Searching: find which categories the matches fall in. All in one -> jump
        // to that tab; spread out (or none) -> highlight "All"
        if (!searchQuery.isEmpty()) {
            PreparedStatement catPs = statsConn.prepareStatement(
                "SELECT DISTINCT CASE WHEN status = 'inactive' THEN 'inactive' "
              + "WHEN event_date < CURDATE() THEN 'completed' "
              + "WHEN event_date = CURDATE() THEN 'ongoing' ELSE 'upcoming' END AS cat "
              + "FROM events WHERE event_name LIKE ?");
            catPs.setString(1, "%" + searchQuery + "%");
            ResultSet catRs = catPs.executeQuery();
            String onlyCat = null;
            int catCount = 0;
            while (catRs.next()) { onlyCat = catRs.getString("cat"); catCount++; }
            filter = (catCount == 1) ? onlyCat : "all";
        }
        
        // How many events match this view (for the page links); keep the page in range
        String totalSql = "SELECT COUNT(*) FROM events e WHERE " + whereClause;
        if (!searchQuery.isEmpty()) { totalSql += " AND e.event_name LIKE ?"; }
        PreparedStatement totalPs = statsConn.prepareStatement(totalSql);
        if (!searchQuery.isEmpty()) { totalPs.setString(1, "%" + searchQuery + "%"); }
        ResultSet totalRs = totalPs.executeQuery();
        if (totalRs.next()) { totalRows = totalRs.getInt(1); }
        totalPages = Math.max(1, (totalRows + pageSize - 1) / pageSize);
        if (pageNum > totalPages) { pageNum = totalPages; }

        
    } catch (Exception e) {
        System.err.println("list_events.jsp (stat counts) - " + e);
    } finally {
        if (statsConn != null) {
            try { statsConn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>

<div id="results">
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
</div>

<%
    int fromRow = totalRows == 0 ? 0 : (pageNum - 1) * pageSize + 1;
    int toRow = Math.min(totalRows, pageNum * pageSize);

    // page links keep the current view (search or tab) and the sort
    String pageBase = "list_events.jsp?sort=" + sort;
    if (!searchQuery.isEmpty()) {
        pageBase += "&q=" + java.net.URLEncoder.encode(searchQuery, "UTF-8");
    } else {
        pageBase += "&filter=" + filter;
    }
    pageBase += "&p=";
    int startPage = Math.max(1, pageNum - 2);
    int endPage = Math.min(totalPages, pageNum + 2);
%>
<div id="pageInfo" data-page="<%= pageNum %>" class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
    <div class="small text-muted">Showing <%= fromRow %>-<%= toRow %> of <%= totalRows %> events</div>
    <% if (totalPages > 1) { %>
    <ul class="pagination pagination-sm mb-0">
        <li class="page-item<%= pageNum == 1 ? " disabled" : "" %>"><a class="page-link" href="<%= pageBase %><%= pageNum - 1 %>">Previous</a></li>
        <% if (startPage > 1) { %>
            <li class="page-item"><a class="page-link" href="<%= pageBase %>1">1</a></li>
            <% if (startPage > 2) { %><li class="page-item disabled"><span class="page-link">&hellip;</span></li><% } %>
        <% } %>
        <% for (int i = startPage; i <= endPage; i++) { %>
            <li class="page-item<%= i == pageNum ? " active" : "" %>"><a class="page-link" href="<%= pageBase %><%= i %>"><%= i %></a></li>
        <% } %>
        <% if (endPage < totalPages) { %>
            <% if (endPage < totalPages - 1) { %><li class="page-item disabled"><span class="page-link">&hellip;</span></li><% } %>
            <li class="page-item"><a class="page-link" href="<%= pageBase %><%= totalPages %>"><%= totalPages %></a></li>
        <% } %>
        <li class="page-item<%= pageNum == totalPages ? " disabled" : "" %>"><a class="page-link" href="<%= pageBase %><%= pageNum + 1 %>">Next</a></li>
    </ul>
    <% } %>
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
            <th>Filled</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
<%
	Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        int offset = (pageNum - 1) * pageSize;

        String sql = "SELECT e.event_id, e.event_name, e.event_date, e.venue, e.status, e.start_time, e.end_time, e.description, e.capacity, "
                + "COUNT(r.registration_id) AS signed_up "
                + "FROM events e "
                + "LEFT JOIN event_registrations r ON r.event_id = e.event_id AND r.status = 'registered' "
                + "WHERE " + whereClause;
        if (!searchQuery.isEmpty()) {
            sql += " AND e.event_name LIKE ?";
        }
        sql += " GROUP BY e.event_id, e.event_name, e.event_date, e.venue, e.status, e.start_time, e.end_time, e.description, e.capacity"
             + " ORDER BY " + orderBy + " LIMIT ? OFFSET ?";

        PreparedStatement ps = conn.prepareStatement(sql);
        int paramIdx = 1;
        if (!searchQuery.isEmpty()) {
            ps.setString(paramIdx++, "%" + searchQuery + "%");
        }
        ps.setInt(paramIdx++, pageSize);
        ps.setInt(paramIdx++, offset);
        ResultSet rs = ps.executeQuery();
        int shownRows = 0;
        while (rs.next()) {
        	shownRows++;
            String rowStatus = rs.getString("status");
            int rowEventId = rs.getInt("event_id");
            boolean rowActive = "active".equals(rowStatus);
            // time columns are NULL for events created before times existed
            java.sql.Time rowStart = rs.getTime("start_time");
            java.sql.Time rowEnd = rs.getTime("end_time");
            String rowDescription = rs.getString("description");
            int rowSignedUp = rs.getInt("signed_up");
            int rowCapacity = rs.getInt("capacity");
            boolean rowFull = rowSignedUp >= rowCapacity;
            int rowPercent = rowCapacity > 0 ? Math.min(100, rowSignedUp * 100 / rowCapacity) : 0;
%>
        <tr>
            <td><%= esc(rs.getString("event_name")) %></td>
            <td><%= rs.getDate("event_date") %></td>
            <td><%= rowStart != null ? rowStart.toString().substring(0, 5) : "-" %></td>
            <td><%= rowEnd != null ? rowEnd.toString().substring(0, 5) : "-" %></td>
            <td><%= esc(rs.getString("venue")) %></td>
            <td class="text-break" style="max-width: 220px;"><%= (rowDescription == null || rowDescription.isEmpty()) ? "-" : esc(rowDescription) %></td>
            <td><%= esc(rowStatus) %></td>
            <td style="min-width: 130px;">
                <div class="small fw-semibold"><%= rowSignedUp %>/<%= rowCapacity %> filled<% if (rowFull) { %> <span class="badge text-bg-danger">Full</span><% } %></div>
                <div class="progress mt-1" style="height: 6px;">
                    <div class="progress-bar <%= rowFull ? "bg-danger" : "bg-primary" %>" style="width: <%= rowPercent %>%;"></div>
                </div>
            </td>            
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
        if (shownRows == 0) {
%>
        <tr><td colspan="9" class="text-center text-muted">No events found.</td></tr>
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

<script>
(function () {
    var input = document.getElementById("searchInput");
    var sortSelect = document.getElementById("sortSelect");
    var clearBtn = document.getElementById("clearBtn");
    var typingTimer = null;
    var lastRequest = 0;

    // keepTab:  stay on the tab the user is on (sorting, auto-refresh)
    // keepPage: stay on the page the user is on (auto-refresh only)
    function load(keepTab, keepPage) {
        var results = document.getElementById("results");
        var q = input.value.trim();
        var params = [];
        if (q !== "") {
            params.push("q=" + encodeURIComponent(q));
        } else if (keepTab) {
            params.push("filter=" + encodeURIComponent(results.getAttribute("data-filter")));
        }
        params.push("sort=" + encodeURIComponent(sortSelect.value));
        if (keepPage) {
            var info = document.getElementById("pageInfo");
            params.push("p=" + encodeURIComponent(info ? info.getAttribute("data-page") : "1"));
        }

        var thisRequest = ++lastRequest;
        fetch("list_events.jsp?" + params.join("&"), { credentials: "same-origin" })
            .then(function (res) {
                if (res.redirected) { window.location.href = res.url; return null; }
                return res.text();
            })
            .then(function (html) {
                if (html === null || thisRequest !== lastRequest) { return; }
                var doc = new DOMParser().parseFromString(html, "text/html");
                var fresh = doc.getElementById("results");
                if (fresh) {
                    results.innerHTML = fresh.innerHTML;
                    results.setAttribute("data-filter", fresh.getAttribute("data-filter"));
                }
            });
    }

    input.addEventListener("input", function () {
        clearBtn.classList.toggle("d-none", input.value.trim() === "");
        clearTimeout(typingTimer);
        typingTimer = setTimeout(function () { load(false, false); }, 250);
    });

    sortSelect.addEventListener("change", function () { load(true, false); });

    // live headcounts: refresh every 5 seconds while the page is visible
    setInterval(function () {
        if (!document.hidden) { load(true, true); }
    }, 5000);
})();
</script>

<%@ include file="/WEB-INF/common/footer.jsp" %>