<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*, java.util.Map" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Participant's own account page (view + update own record).
    The record is found with the userId in the session - never an id from the
    URL or the form - so a participant can only ever see and edit their own
    details. The form posts to save_my_account.jsp, which forwards back here
    with an errors map if anything is wrong (the typed values are kept).
    Also shows the participant code as a QR code (plain text, e.g. "P-00007")
    for staff to scan at events. It is drawn in the browser by the qrcodejs
    library from the CDN; the code is passed in through an escaped data-code
    attribute, never written straight into the script.
--%>
<%@ include file="/WEB-INF/common/require_participant.jsp" %>
<%
    @SuppressWarnings("unchecked")
    Map<String, String> errors = (Map<String, String>) request.getAttribute("errors");
    boolean redisplay = (errors != null);

    String fFullName = request.getParameter("fullName");
    String fContactNo = request.getParameter("contactNo");
    String fEmail = request.getParameter("email");
    String fDob = request.getParameter("dateOfBirth");
    String fGender = request.getParameter("gender");
    String dbCode = null, dbUsername = null;

    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);
        String sql = "SELECT p.participant_code, p.full_name, p.contact_no, p.email, p.date_of_birth, p.gender, u.username "
                   + "FROM participants p JOIN users u ON u.user_id = p.user_id WHERE p.user_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, userId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            dbCode = rs.getString("participant_code");
            dbUsername = rs.getString("username");
            if (!redisplay) {   // first visit: fill the form from the database
                fFullName = rs.getString("full_name");
                fContactNo = rs.getString("contact_no");
                fEmail = rs.getString("email");
                java.sql.Date dob = rs.getDate("date_of_birth");
                fDob = (dob == null) ? "" : dob.toString();
                fGender = rs.getString("gender");
            }
        }
    } catch (Exception e) {
        System.err.println("my_account.jsp - " + e);
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
    if (dbCode == null) {   // no participant record, or the database could not be reached
        response.sendRedirect("../home/home.jsp?errCode=dbError");
        return;
    }
%>
<%@ include file="/WEB-INF/common/header.jsp" %>
<%@ include file="/WEB-INF/common/form_helpers.jsp" %>

<div class="mx-auto" style="max-width: 720px;">
<h1 class="h2 text-primary mb-3">My Account</h1>
    <%@ include file="/WEB-INF/common/messages.jsp" %>

    <div class="card shadow-sm mb-4">
        <div class="card-body p-4">
            <h2 class="h5 mb-3">Account</h2>
            <div class="d-flex flex-wrap justify-content-between align-items-start gap-4">
                <div class="flex-grow-1">
                    <dl class="row mb-0">
                        <dt class="col-sm-4 text-muted fw-normal">Username</dt><dd class="col-sm-8 fw-semibold"><%= esc(dbUsername) %></dd>
                        <dt class="col-sm-4 text-muted fw-normal">Participant code</dt><dd class="col-sm-8 fw-semibold"><%= esc(dbCode) %></dd>
                        <dt class="col-sm-4 text-muted fw-normal">Status</dt><dd class="col-sm-8 mb-0"><span class="badge rounded-pill text-bg-success">active</span></dd>
                    </dl>
                    <a href="change_password.jsp" class="btn btn-sm btn-outline-primary mt-3">Change password</a>
                </div>
                <%-- QR code of the participant code (plain text, e.g. "P-00007"), drawn in the browser --%>
                <div class="text-center">
                    <div id="participantQr" class="d-inline-block p-2 bg-white border rounded" data-code="<%= esc(dbCode) %>"
                         role="img" aria-label="QR code for participant code <%= esc(dbCode) %>"></div>
                    <div class="small text-muted mt-1">Show this at the event</div>
                </div>
            </div>
        </div>
    </div>

    <form method="post" action="save_my_account.jsp" class="card shadow-sm" novalidate>
        <div class="card-body p-4">
            <h2 class="h5 mb-1">My Details</h2>
            <p class="form-text mt-0 mb-3">Fields marked <span class="text-danger">*</span> are required.</p>
            <%@ include file="/WEB-INF/common/participant_fields.jsp" %>
            <div class="d-flex align-items-center gap-3">
                <button type="submit" class="btn btn-primary">Save Changes</button>
                <a href="my_signups.jsp" class="btn btn-link text-secondary text-decoration-none">Cancel</a>
            </div>
        </div>
    </form>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
<script>
    // Draw the participant code as a QR code. The code is read from data-code
    // (already escaped by esc()), so it never goes straight into the script.
    (function () {
        var box = document.getElementById("participantQr");
        if (box && window.QRCode) {
            new QRCode(box, { text: box.getAttribute("data-code"), width: 140, height: 140 });
        }
    })();
</script>

<%@ include file="/WEB-INF/common/footer.jsp" %>