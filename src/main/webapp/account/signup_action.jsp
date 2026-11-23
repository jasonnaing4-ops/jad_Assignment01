<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Action page for sign up / withdraw - no HTML, every path ends
    in a redirect back to my_signups.jsp. POST only.
      - signup:   the event must exist, be active and be today or later.
      - withdraw: the event must be today or later; the registration is set
                  to 'cancelled' (kept, not deleted).
    event_registrations allows one row per participant + event
    (uq_participant_event), so signing up again after withdrawing re-uses the
    cancelled row (INSERT ... ON DUPLICATE KEY UPDATE). The participant is
    always the one in the session, never one from the form.
--%>
<%@ include file="/WEB-INF/common/require_participant.jsp" %>
<%
    // Step 1: Existence
    String eventIdParam = request.getParameter("eventId");
    String mode = request.getParameter("mode");
    if (!"POST".equalsIgnoreCase(request.getMethod()) || eventIdParam == null || mode == null) {
        response.sendRedirect("my_signups.jsp");
        return;
    }

    // Step 2: Validate
    int eventId = util.Validator.parseId(eventIdParam);
    if (eventId < 0 || (!mode.equals("signup") && !mode.equals("withdraw"))) {
        response.sendRedirect("my_signups.jsp?errCode=invalidAction");
        return;
    }

    // Step 3: Process
    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        // whose sign-up: from the session
        int participantId = -1;
        PreparedStatement pPs = conn.prepareStatement("SELECT participant_id FROM participants WHERE user_id = ?");
        pPs.setInt(1, userId);
        ResultSet pRs = pPs.executeQuery();
        if (pRs.next()) { participantId = pRs.getInt("participant_id"); }

        // which event, and can it still be joined / left?
        PreparedStatement evPs = conn.prepareStatement(
                "SELECT status, (event_date < CURDATE()) AS is_past FROM events WHERE event_id = ?");
        evPs.setInt(1, eventId);
        ResultSet evRs = evPs.executeQuery();
        if (participantId < 0 || !evRs.next()) {
            response.sendRedirect("my_signups.jsp?errCode=eventNotFound");
            return;
        }
        if (evRs.getBoolean("is_past")) {
            response.sendRedirect("my_signups.jsp?errCode=eventPast");
            return;
        }

        if (mode.equals("signup")) {
            if (!"active".equals(evRs.getString("status"))) {
                response.sendRedirect("my_signups.jsp?errCode=eventClosed");
                return;
            }
            String sql = "INSERT INTO event_registrations (participant_id, event_id, status) VALUES (?, ?, 'registered') "
                       + "ON DUPLICATE KEY UPDATE status = 'registered', registered_at = CURRENT_TIMESTAMP";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, participantId);
            ps.setInt(2, eventId);
            ps.executeUpdate();
            response.sendRedirect("my_signups.jsp?msg=signedUp");
            return;
        } else {
            String sql = "UPDATE event_registrations SET status = 'cancelled' "
                       + "WHERE participant_id = ? AND event_id = ? AND status = 'registered'";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, participantId);
            ps.setInt(2, eventId);
            int rowsAffected = ps.executeUpdate();
            response.sendRedirect("my_signups.jsp?" + (rowsAffected == 0 ? "errCode=notSignedUp" : "msg=withdrawn"));
            return;
        }
    } catch (Exception e) {
        System.err.println("signup_action.jsp - " + e);
        response.sendRedirect("my_signups.jsp?errCode=dbError");
        return;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>