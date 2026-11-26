<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*, java.util.*" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Staff view + edit of one participant (section 3.2). Looks the
    record up first and redirects away if the id is bad or the participant is
    gone, and only then writes HTML. Shows the read-only account details
    (code, username, status), the editable details form (posts to
    save_participant.jsp) and the events this participant is signed up for.
    After a rejected save, save_participant.jsp forwards back here: the
    account details and sign-ups are re-read, but the form shows what was typed.
--%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>
<%
    // Step 1: Existence
    String idParam = request.getParameter("id");
    if (idParam == null) {
        response.sendRedirect("list_participants.jsp");
        return;
    }

    // Step 2: Validate
    int participantId = util.Validator.parseId(idParam);
    if (participantId < 0) {
        response.sendRedirect("list_participants.jsp?errCode=invalidAction");
        return;
    }

    @SuppressWarnings("unchecked")
    Map<String, String> errors = (Map<String, String>) request.getAttribute("errors");
    boolean redisplay = (errors != null);   // true when coming back from a rejected save

    String fFullName = request.getParameter("fullName");
    String fContactNo = request.getParameter("contactNo");
    String fEmail = request.getParameter("email");
    String fDob = request.getParameter("dateOfBirth");
    String fGender = request.getParameter("gender");
    String dbCode = null, dbUsername = null, dbStatus = null, dbName = null;
    java.sql.Timestamp dbCreated = null;
    List<String[]> signups = new ArrayList<>();   // {event name, date, registration status}

    // Step 3: Process - look the participant and their sign-ups up
    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        String sql = "SELECT p.participant_code, p.full_name, p.contact_no, p.email, p.date_of_birth, p.gender, "
                   + "p.created_at, u.username, u.status "
                   + "FROM participants p JOIN users u ON u.user_id = p.user_id WHERE p.participant_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, participantId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            dbCode = rs.getString("participant_code");
            dbName = rs.getString("full_name");
            dbUsername = rs.getString("username");
            dbStatus = rs.getString("status");
            dbCreated = rs.getTimestamp("created_at");
            if (!redisplay) {   // first visit: fill the form from the database
                fFullName = dbName;
                fContactNo = rs.getString("contact_no");
                fEmail = rs.getString("email");
                java.sql.Date dob = rs.getDate("date_of_birth");
                fDob = (dob == null) ? "" : dob.toString();
                fGender = rs.getString("gender");
            }
        } else {
            response.sendRedirect("list_participants.jsp?errCode=notFound");
            return;
        }

        String signupSql = "SELECT e.event_name, e.event_date, r.status FROM event_registrations r "
                         + "JOIN events e ON e.event_id = r.event_id WHERE r.participant_id = ? ORDER BY e.event_date";
        PreparedStatement signupPs = conn.prepareStatement(signupSql);
        signupPs.setInt(1, participantId);
        ResultSet signupRs = signupPs.executeQuery();
        while (signupRs.next()) {
            signups.add(new String[] { signupRs.getString("event_name"),
                    String.valueOf(signupRs.getDate("event_date")), signupRs.getString("status") });
        }
    } catch (Exception e) {
        System.err.println("edit_participant.jsp - " + e);
        response.sendRedirect("list_participants.jsp?errCode=dbError");
        return;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
    boolean isActive = "active".equals(dbStatus);
%>
<%@ include file="/WEB-INF/common/header.jsp" %>
<%@ include file="/WEB-INF/common/form_helpers.jsp" %>

<div class="mx-auto" style="max-width: 720px;">
<nav aria-label="breadcrumb">
    <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="list_participants.jsp">Participants</a></li>
        <li class="breadcrumb-item active" aria-current="page"><%= esc(dbName) %></li>
    </ol>
</nav>
<h1 class="h2 text-primary mb-3">Edit Participant</h1>

    <%@ include file="/WEB-INF/common/messages.jsp" %>

    <div class="card shadow-sm mb-4">
        <div class="card-body p-4">
            <h2 class="h5 mb-3">Account</h2>
            <dl class="row mb-2">
                <dt class="col-sm-4 text-muted fw-normal">Participant code</dt><dd class="col-sm-8 fw-semibold"><%= esc(dbCode) %></dd>
                <dt class="col-sm-4 text-muted fw-normal">Username</dt><dd class="col-sm-8 fw-semibold"><%= esc(dbUsername) %></dd>
                <dt class="col-sm-4 text-muted fw-normal">Status</dt>
                <dd class="col-sm-8"><span class="badge rounded-pill <%= isActive ? "text-bg-success" : "text-bg-secondary" %>"><%= esc(dbStatus) %></span></dd>
                <dt class="col-sm-4 text-muted fw-normal">Registered on</dt><dd class="col-sm-8"><%= dbCreated == null ? "-" : dbCreated.toString().substring(0, 10) %></dd>
            </dl>
            <p class="form-text mb-0">The code and username cannot be changed. Use Deactivate / Activate on the participant list to change the status.</p>
        </div>
    </div>

    <form method="post" action="save_participant.jsp" class="card shadow-sm mb-4" novalidate>
        <div class="card-body p-4">
            <input type="hidden" name="id" value="<%= participantId %>">
            <h2 class="h5 mb-1">Participant Details</h2>
            <p class="form-text mt-0 mb-3">Fields marked <span class="text-danger">*</span> are required.</p>
            <%@ include file="/WEB-INF/common/participant_fields.jsp" %>
            <div class="d-flex align-items-center gap-3">
                <button type="submit" class="btn btn-primary">Save Changes</button>
                <a href="list_participants.jsp" class="btn btn-link text-secondary text-decoration-none">Cancel</a>
            </div>
        </div>
    </form>

    <h2 class="h5 mb-3">Event Sign-ups</h2>
    <% if (signups.isEmpty()) { %>
        <p class="text-muted">This participant has not signed up for any events.</p>
    <% } else { %>
        <div class="table-responsive">
        <table class="table table-bordered align-middle">
            <caption class="visually-hidden">Events this participant signed up for</caption>
            <thead class="table-light"><tr><th scope="col">Event</th><th scope="col">Date</th><th scope="col">Sign-up Status</th></tr></thead>
            <tbody>
            <% for (String[] s : signups) { %>
                <tr>
                    <td><%= esc(s[0]) %></td>
                    <td><%= esc(s[1]) %></td>
                    <td><span class="badge rounded-pill <%= "registered".equals(s[2]) ? "text-bg-primary" : "text-bg-secondary" %>"><%= esc(s[2]) %></span></td>
                </tr>
            <% } %>
            </tbody>
        </table>
        </div>
    <% } %>
</div>

<%@ include file="/WEB-INF/common/footer.jsp" %>
