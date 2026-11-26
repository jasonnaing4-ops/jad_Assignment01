<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*, java.util.*" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Participant's events page - explore events, sign up and
    withdraw (associates each registration with an event, section 3.3).
      - "My sign-ups": events this participant is registered for, with a
        Withdraw button while the event has not happened yet.
      - "Open events": active events from today onwards that they have not
        joined yet, with a Sign Up button.
    Both buttons are small POST forms to signup_action.jsp. Everything is
    looked up by the userId in the session.
    My sign-ups has status tabs (All / Upcoming / Ongoing / Completed, same
    date rule as Event Management), a search by event name (q) and a sort
    dropdown (event date soonest / latest, event name A-Z, recently signed
    up). Open events has its own search (oq) and sort dropdown (osort):
    event date or start time, either way round. The sort values are
    whitelisted, the search text only ever goes in through ? placeholders,
    and every value is kept in the page links.
    Searching happens as you type: the script at the bottom fetches this
    page in the background and swaps in #signupsResults and #openResults,
    so the search boxes keep their focus. Without JavaScript, Enter submits
    the search form instead.
--%>
<%@ include file="/WEB-INF/common/require_participant.jsp" %>
<%
    // {event_id, name, date, start-end, venue, state}   state: upcoming / ongoing / past / inactive
    List<String[]> joined = new ArrayList<>();
    // {event_id, name, date, start-end, venue, description}
    List<String[]> open = new ArrayList<>();
    boolean loadFailed = false;

    // Pagination: My Sign-ups 5 per page (sp), Open Events 10 per page (op).
    // Separate parameters, so moving through one list does not reset the other.
    int signPageSize = 5;
    int openPageSize = 10;
    int signPage = Math.max(1, util.Validator.parseId(request.getParameter("sp")));
    int openPage = Math.max(1, util.Validator.parseId(request.getParameter("op")));
    int signTotal = 0, openTotal = 0;
    int signPages = 1, openPages = 1;

    // Status tab for My Sign-ups (same date rule as Event Management)
    String filter = request.getParameter("filter");
    if (filter == null || !(filter.equals("all") || filter.equals("upcoming")
            || filter.equals("ongoing") || filter.equals("completed"))) {
        filter = "all";
    }
    String filterSql = "";
    if (filter.equals("upcoming")) { filterSql = " AND e.event_date > CURDATE()"; }
    else if (filter.equals("ongoing")) { filterSql = " AND e.event_date = CURDATE()"; }
    else if (filter.equals("completed")) { filterSql = " AND e.event_date < CURDATE()"; }

    // Search by event name: q = My Sign-ups, oq = Open Events (at most 100 characters)
    String q = util.Validator.clean(request.getParameter("q"));
    if (q.length() > 100) { q = q.substring(0, 100); }
    String oq = util.Validator.clean(request.getParameter("oq"));
    if (oq.length() > 100) { oq = oq.substring(0, 100); }
    String qSql = q.isEmpty() ? "" : " AND e.event_name LIKE ?";
    String oqSql = oq.isEmpty() ? "" : " AND e.event_name LIKE ?";

    // Sort order for My Sign-ups - whitelist only, never put into the SQL itself
    String sort = request.getParameter("sort");
    String orderBy;
    if ("dateDesc".equals(sort)) {
        orderBy = "e.event_date DESC, e.start_time DESC, e.event_id";
    } else if ("nameAsc".equals(sort)) {
        orderBy = "e.event_name, e.event_date, e.event_id";
    } else if ("recent".equals(sort)) {
        orderBy = "r.registered_at DESC, e.event_id";
    } else {
        sort = "dateAsc";                       // default: soonest first
        orderBy = "e.event_date, e.start_time, e.event_id";
    }
    // Sort order for Open Events (osort) - date or start time, whitelist only
    String osort = request.getParameter("osort");
    String openOrderBy;
    if ("dateDesc".equals(osort)) {
        openOrderBy = "e.event_date DESC, e.start_time DESC, e.event_id";
    } else if ("timeAsc".equals(osort)) {
        openOrderBy = "e.start_time IS NULL, e.start_time ASC, e.event_date ASC, e.event_id";
    } else if ("timeDesc".equals(osort)) {
        openOrderBy = "e.start_time IS NULL, e.start_time DESC, e.event_date ASC, e.event_id";
    } else {
        osort = "dateAsc";                      // default: earliest first
        openOrderBy = "e.event_date, e.start_time, e.event_id";
    }

    // kept in every link on this page (the search text is URL-encoded)
    String qPart = q.isEmpty() ? "" : "&q=" + java.net.URLEncoder.encode(q, "UTF-8");
    String oqPart = oq.isEmpty() ? "" : "&oq=" + java.net.URLEncoder.encode(oq, "UTF-8");
    String viewPart = "&filter=" + filter + "&sort=" + sort + "&osort=" + osort + qPart + oqPart;
    int tabAll = 0, tabUpcoming = 0, tabOngoing = 0, tabCompleted = 0;

    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        // counts for the status tabs (all of this participant's sign-ups, not just the search matches)
        PreparedStatement tabPs = conn.prepareStatement(
                "SELECT COUNT(*) AS total, SUM(e.event_date > CURDATE()) AS up, "
              + "SUM(e.event_date = CURDATE()) AS ongo, SUM(e.event_date < CURDATE()) AS done "
              + "FROM event_registrations r JOIN participants p ON p.participant_id = r.participant_id "
              + "JOIN events e ON e.event_id = r.event_id WHERE p.user_id = ? AND r.status = 'registered'");
        tabPs.setInt(1, userId);
        ResultSet tabRs = tabPs.executeQuery();
        if (tabRs.next()) {
            tabAll = tabRs.getInt("total");
            tabUpcoming = tabRs.getInt("up");
            tabOngoing = tabRs.getInt("ongo");
            tabCompleted = tabRs.getInt("done");
        }

        // totals first, so a page number that is too high can be pulled back into range
        PreparedStatement signCountPs = conn.prepareStatement(
                "SELECT COUNT(*) FROM event_registrations r JOIN participants p ON p.participant_id = r.participant_id "
              + "JOIN events e ON e.event_id = r.event_id "
              + "WHERE p.user_id = ? AND r.status = 'registered'" + filterSql + qSql);
        int sci = 1;
        signCountPs.setInt(sci++, userId);
        if (!q.isEmpty()) { signCountPs.setString(sci++, "%" + likeEscape(q) + "%"); }
        ResultSet signCountRs = signCountPs.executeQuery();
        if (signCountRs.next()) { signTotal = signCountRs.getInt(1); }
        signPages = Math.max(1, (signTotal + signPageSize - 1) / signPageSize);
        if (signPage > signPages) { signPage = signPages; }

        PreparedStatement openCountPs = conn.prepareStatement(
                "SELECT COUNT(*) FROM events e WHERE e.status = 'active' AND e.event_date >= CURDATE() "
              + "AND e.event_id NOT IN (SELECT r.event_id FROM event_registrations r "
              + "  JOIN participants p ON p.participant_id = r.participant_id "
              + "  WHERE p.user_id = ? AND r.status = 'registered')" + oqSql);
        int oci = 1;
        openCountPs.setInt(oci++, userId);
        if (!oq.isEmpty()) { openCountPs.setString(oci++, "%" + likeEscape(oq) + "%"); }
        ResultSet openCountRs = openCountPs.executeQuery();
        if (openCountRs.next()) { openTotal = openCountRs.getInt(1); }
        openPages = Math.max(1, (openTotal + openPageSize - 1) / openPageSize);
        if (openPage > openPages) { openPage = openPages; }

        String joinedSql = "SELECT e.event_id, e.event_name, e.event_date, e.start_time, e.end_time, e.venue, e.status, "
                         + "(e.event_date < CURDATE()) AS is_past, (e.event_date = CURDATE()) AS is_today "
                         + "FROM event_registrations r "
                         + "JOIN participants p ON p.participant_id = r.participant_id "
                         + "JOIN events e ON e.event_id = r.event_id "
                         + "WHERE p.user_id = ? AND r.status = 'registered'" + filterSql + qSql
                         + " ORDER BY " + orderBy + " LIMIT ? OFFSET ?";
        PreparedStatement joinedPs = conn.prepareStatement(joinedSql);
        int ji = 1;
        joinedPs.setInt(ji++, userId);
        if (!q.isEmpty()) { joinedPs.setString(ji++, "%" + likeEscape(q) + "%"); }
        joinedPs.setInt(ji++, signPageSize);
        joinedPs.setInt(ji++, (signPage - 1) * signPageSize);
        ResultSet joinedRs = joinedPs.executeQuery();
        while (joinedRs.next()) {
            String state = joinedRs.getBoolean("is_past") ? "past"
                         : !"active".equals(joinedRs.getString("status")) ? "inactive"
                         : joinedRs.getBoolean("is_today") ? "ongoing" : "upcoming";
            joined.add(new String[] { String.valueOf(joinedRs.getInt("event_id")), joinedRs.getString("event_name"),
                    String.valueOf(joinedRs.getDate("event_date")),
                    timeRange(joinedRs.getTime("start_time"), joinedRs.getTime("end_time")),
                    joinedRs.getString("venue"), state });
        }

        String openSql = "SELECT e.event_id, e.event_name, e.event_date, e.start_time, e.end_time, e.venue, e.description "
                       + "FROM events e WHERE e.status = 'active' AND e.event_date >= CURDATE() "
                       + "AND e.event_id NOT IN (SELECT r.event_id FROM event_registrations r "
                       + "  JOIN participants p ON p.participant_id = r.participant_id "
                       + "  WHERE p.user_id = ? AND r.status = 'registered')" + oqSql
                       + " ORDER BY " + openOrderBy + " LIMIT ? OFFSET ?";
        PreparedStatement openPs = conn.prepareStatement(openSql);
        int oi = 1;
        openPs.setInt(oi++, userId);
        if (!oq.isEmpty()) { openPs.setString(oi++, "%" + likeEscape(oq) + "%"); }
        openPs.setInt(oi++, openPageSize);
        openPs.setInt(oi++, (openPage - 1) * openPageSize);
        ResultSet openRs = openPs.executeQuery();
        while (openRs.next()) {
            open.add(new String[] { String.valueOf(openRs.getInt("event_id")), openRs.getString("event_name"),
                    String.valueOf(openRs.getDate("event_date")),
                    timeRange(openRs.getTime("start_time"), openRs.getTime("end_time")),
                    openRs.getString("venue"), openRs.getString("description") });
        }
    } catch (Exception e) {
        System.err.println("my_signups.jsp - " + e);
        loadFailed = true;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>
<%!
    // "09:00 - 12:00", or "-" for events created before times existed
    private String timeRange(java.sql.Time start, java.sql.Time end) {
        if (start == null || end == null) { return "-"; }
        return start.toString().substring(0, 5) + " - " + end.toString().substring(0, 5);
    }

    // Escapes the LIKE wildcards % and _ so a search for "50%" matches that text
    private String likeEscape(String s) {
        return s.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }
%>
<%@ include file="/WEB-INF/common/header.jsp" %>
<%@ include file="/WEB-INF/common/pagination.jsp" %>

<h1 class="h2 text-primary mb-3">My Events</h1>
<%@ include file="/WEB-INF/common/messages.jsp" %>
<% if (loadFailed) { %><div class="alert alert-danger">Could not load events right now. Please try again.</div><% } %>

<h2 class="h5 mt-4 mb-3">My Sign-ups</h2>

<%-- Search + sort for My Sign-ups. Hidden fields keep everything else, so Enter
     (no JavaScript) still lands on the same view. --%>
<form method="get" action="my_signups.jsp" class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3" role="search">
    <input type="hidden" name="filter" value="<%= filter %>">
    <input type="hidden" name="osort" value="<%= osort %>">
    <input type="hidden" name="oq" value="<%= esc(oq) %>">
    <input type="hidden" name="op" value="<%= openPage %>">
    <div class="d-flex gap-2">
        <label for="signSearch" class="visually-hidden">Search my sign-ups by event name</label>
        <input type="text" id="signSearch" name="q" maxlength="100" class="form-control rounded-pill"
               placeholder="Search my sign-ups" value="<%= esc(q) %>" autocomplete="off">
        <a href="<%= esc("my_signups.jsp?filter=" + filter + "&sort=" + sort + "&osort=" + osort + oqPart + "&op=" + openPage) %>"
           id="signClear" class="btn btn-outline-secondary rounded-pill px-4<%= q.isEmpty() ? " d-none" : "" %>">Clear</a>
    </div>
    <label for="sortSelect" class="visually-hidden">Sort my sign-ups</label>
    <select id="sortSelect" name="sort" class="form-select form-select-sm rounded-pill w-auto">
        <option value="dateAsc" <%= sort.equals("dateAsc") ? "selected" : "" %>>Event date: soonest first</option>
        <option value="dateDesc" <%= sort.equals("dateDesc") ? "selected" : "" %>>Event date: latest first</option>
        <option value="nameAsc" <%= sort.equals("nameAsc") ? "selected" : "" %>>Event name: A to Z</option>
        <option value="recent" <%= sort.equals("recent") ? "selected" : "" %>>Recently signed up</option>
    </select>
</form>

<div id="signupsResults">
<div class="row g-3 mb-3">
    <%
        // {filter value, label, Bootstrap colour, count} - colours match the Event Management tabs
        String[][] tabs = {
            {"all", "All", "dark", String.valueOf(tabAll)},
            {"upcoming", "Upcoming", "primary", String.valueOf(tabUpcoming)},
            {"ongoing", "Ongoing", "warning", String.valueOf(tabOngoing)},
            {"completed", "Completed", "success", String.valueOf(tabCompleted)}
        };
        for (String[] t : tabs) {
    %>
    <div class="col-6 col-lg-3">
        <a class="card stat-card h-100 text-decoration-none shadow-sm <%= filter.equals(t[0]) ? "border border-2 border-" + t[2] : "border-0" %>"
           href="<%= esc("my_signups.jsp?filter=" + t[0] + "&sort=" + sort + "&osort=" + osort + qPart + oqPart + "&op=" + openPage) %>">
            <div class="card-body d-flex align-items-center gap-3">
                <span class="stat-indicator bg-<%= t[2] %>"></span>
                <span class="d-flex flex-column">
                    <span class="fs-4 fw-bold text-dark lh-1"><%= t[3] %></span>
                    <span class="small text-muted"><%= t[1] %></span>
                </span>
            </div>
        </a>
    </div>
    <% } %>
</div>

<% if (joined.isEmpty()) { %>
    <% if (!q.isEmpty()) { %>
        <p class="text-muted">No sign-ups match your search.</p>
    <% } else if (filter.equals("all")) { %>
        <p class="text-muted">You have not signed up for any events yet. Choose one from the open events below.</p>
    <% } else { %>
        <p class="text-muted">You have no <%= filter %> sign-ups.</p>
    <% } %>
<% } else { %>
<%= pagerBar("sign-ups", "my_signups.jsp?op=" + openPage + viewPart + "&sp=", signPage, signPages, signPageSize, signTotal) %>
<div class="table-responsive">
<table class="table table-bordered table-hover align-middle">
    <caption class="visually-hidden">Events you have signed up for</caption>
    <thead class="table-light">
        <tr><th scope="col">Event</th><th scope="col">Date</th><th scope="col">Time</th><th scope="col">Venue</th><th scope="col">Status</th><th scope="col">Action</th></tr>
    </thead>
    <tbody>
    <% for (String[] ev : joined) { %>
        <tr>
            <td class="fw-semibold"><%= esc(ev[1]) %></td>
            <td class="text-nowrap"><%= esc(ev[2]) %></td>
            <td class="text-nowrap"><%= esc(ev[3]) %></td>
            <td><%= esc(ev[4]) %></td>
            <td>
                <% if (ev[5].equals("past")) { %><span class="badge rounded-pill text-bg-success">completed</span>
                <% } else if (ev[5].equals("inactive")) { %><span class="badge rounded-pill text-bg-secondary">not running</span>
                <% } else if (ev[5].equals("ongoing")) { %><span class="badge rounded-pill text-bg-warning">ongoing</span>
                <% } else { %><span class="badge rounded-pill text-bg-primary">upcoming</span><% } %>
            </td>
            <td>
                <% if (!ev[5].equals("past")) { %>
                    <form method="post" action="signup_action.jsp" class="m-0">
                        <input type="hidden" name="eventId" value="<%= esc(ev[0]) %>">
                        <input type="hidden" name="mode" value="withdraw">
                        <input type="hidden" name="sp" value="<%= signPage %>">
                        <input type="hidden" name="op" value="<%= openPage %>">
                        <button type="submit" class="btn btn-sm btn-outline-danger text-nowrap">Withdraw</button>
                    </form>
                <% } else { %>-<% } %>
            </td>
        </tr>
    <% } %>
    </tbody>
</table>
</div>
<% } %>
</div><%-- end #signupsResults --%>

<h2 class="h5 mt-4 mb-1">Open Events</h2>
<p class="form-text mt-0 mb-3">Upcoming events you can still sign up for.</p>

<%-- Search + sort for Open Events - always shown, so the box stays when a search finds nothing --%>
<form method="get" action="my_signups.jsp" class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3" role="search">
    <input type="hidden" name="filter" value="<%= filter %>">
    <input type="hidden" name="sort" value="<%= sort %>">
    <input type="hidden" name="q" value="<%= esc(q) %>">
    <input type="hidden" name="sp" value="<%= signPage %>">
    <div class="d-flex gap-2">
        <label for="openSearch" class="visually-hidden">Search open events by event name</label>
        <input type="text" id="openSearch" name="oq" maxlength="100" class="form-control rounded-pill"
               placeholder="Search open events" value="<%= esc(oq) %>" autocomplete="off">
        <a href="<%= esc("my_signups.jsp?filter=" + filter + "&sort=" + sort + "&osort=" + osort + qPart + "&sp=" + signPage) %>"
           id="openClear" class="btn btn-outline-secondary rounded-pill px-4<%= oq.isEmpty() ? " d-none" : "" %>">Clear</a>
    </div>
    <label for="openSortSelect" class="visually-hidden">Sort open events</label>
    <select id="openSortSelect" name="osort" class="form-select form-select-sm rounded-pill w-auto">
        <option value="dateAsc" <%= osort.equals("dateAsc") ? "selected" : "" %>>Date: earliest first</option>
        <option value="dateDesc" <%= osort.equals("dateDesc") ? "selected" : "" %>>Date: latest first</option>
        <option value="timeAsc" <%= osort.equals("timeAsc") ? "selected" : "" %>>Time: morning first</option>
        <option value="timeDesc" <%= osort.equals("timeDesc") ? "selected" : "" %>>Time: evening first</option>
    </select>
</form>

<div id="openResults">
<% if (open.isEmpty()) { %>
    <% if (!oq.isEmpty()) { %>
        <p class="text-muted">No open events match your search.</p>
    <% } else { %>
        <p class="text-muted">There are no other open events right now. Please check again later.</p>
    <% } %>
<% } else { %>
<%= pagerBar("events", "my_signups.jsp?sp=" + signPage + viewPart + "&op=", openPage, openPages, openPageSize, openTotal) %>
<div class="table-responsive">
<table class="table table-bordered table-hover align-middle">
    <caption class="visually-hidden">Events you can sign up for</caption>
    <thead class="table-light">
        <tr><th scope="col">Event</th><th scope="col">Date</th><th scope="col">Time</th><th scope="col">Venue</th><th scope="col">Description</th><th scope="col">Action</th></tr>
    </thead>
    <tbody>
    <% for (String[] ev : open) { %>
        <tr>
            <td class="fw-semibold"><%= esc(ev[1]) %></td>
            <td class="text-nowrap"><%= esc(ev[2]) %></td>
            <td class="text-nowrap"><%= esc(ev[3]) %></td>
            <td><%= esc(ev[4]) %></td>
            <td class="text-break" style="max-width: 260px;"><%= (ev[5] == null || ev[5].isEmpty()) ? "-" : esc(ev[5]) %></td>
            <td>
                <form method="post" action="signup_action.jsp" class="m-0">
                    <input type="hidden" name="eventId" value="<%= esc(ev[0]) %>">
                    <input type="hidden" name="mode" value="signup">
                    <input type="hidden" name="sp" value="<%= signPage %>">
                    <input type="hidden" name="op" value="<%= openPage %>">
                    <button type="submit" class="btn btn-sm btn-primary text-nowrap">Sign Up</button>
                </form>
            </td>
        </tr>
    <% } %>
    </tbody>
</table>
</div>
<% } %>
</div><%-- end #openResults --%>

<script>
(function () {
    var state = new URLSearchParams(window.location.search);   // filter, sort, osort, q, oq, sp, op
    var lastRequest = 0;

    // fetch this page with the current state and swap in BOTH result areas,
    // so every link on the page carries both searches and both sorts
    function load() {
        var url = "my_signups.jsp?" + state.toString();
        var thisRequest = ++lastRequest;
        fetch(url, { credentials: "same-origin" })
            .then(function (res) {
                if (res.redirected) { window.location.href = res.url; return null; }   // e.g. session expired
                return res.text();
            })
            .then(function (html) {
                if (html === null || thisRequest !== lastRequest) { return; }          // an older, slower reply
                var doc = new DOMParser().parseFromString(html, "text/html");
                ["signupsResults", "openResults"].forEach(function (id) {
                    var fresh = doc.getElementById(id);
                    if (fresh) { document.getElementById(id).innerHTML = fresh.innerHTML; }
                });
                history.replaceState(null, "", url);
            });
    }

    // a search box: param = q or oq, pageParam = sp or op (back to page 1 on every change)
    function wireSearch(inputId, clearId, param, pageParam) {
        var input = document.getElementById(inputId);
        var clearBtn = document.getElementById(clearId);
        var timer = null;
        function update() {
            var v = input.value.trim();
            if (v === "") { state.delete(param); } else { state.set(param, v); }
            state.delete(pageParam);
            load();
        }
        input.addEventListener("input", function () {
            clearBtn.classList.toggle("d-none", input.value.trim() === "");
            clearTimeout(timer);
            timer = setTimeout(update, 250);      // short pause so not every key press sends a request
        });
        clearBtn.addEventListener("click", function (e) {
            e.preventDefault();
            input.value = "";
            clearBtn.classList.add("d-none");
            update();
            input.focus();
        });
    }

    // a sort dropdown: re-sorts straight away and goes back to page 1 of that list
    function wireSort(selectId, param, pageParam) {
        document.getElementById(selectId).addEventListener("change", function () {
            state.set(param, this.value);
            state.delete(pageParam);
            load();
        });
    }

    wireSearch("signSearch", "signClear", "q", "sp");
    wireSearch("openSearch", "openClear", "oq", "op");
    wireSort("sortSelect", "sort", "sp");
    wireSort("openSortSelect", "osort", "op");
})();
</script>

<%@ include file="/WEB-INF/common/footer.jsp" %>
