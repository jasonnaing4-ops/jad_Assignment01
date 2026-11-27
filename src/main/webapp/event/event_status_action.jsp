<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Action page for delete / deactivate / activate - no HTML,
    every path ends in a redirect. Reachable directly from
    list_events.jsp (activate only) or from confirm_event_action.jsp (delete,
    deactivate). Deleting an event that still has registrations is blocked at
    the database level by the event_registrations FK (ON DELETE RESTRICT), so
    this page also catches that as a safety net even though
    confirm_event_action.jsp should normally have already stopped it.
--%>

<%-- Access Control: verify staff session and load database configuration --%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>

<%
    if (!"POST".equals(request.getMethod())) {
        response.sendRedirect("list_events.jsp");
        return;
    }
%>

<%
	//Parameter Validation: ensure id and mode exist, parse eventId, and whitelist action mode
    String idParam = request.getParameter("id");
    String mode = request.getParameter("mode");
    if (idParam == null || mode == null) {
        response.sendRedirect("list_events.jsp");
        return;
    }

    
    int eventId;
    try {
        eventId = Integer.parseInt(idParam.trim());
    } catch (Exception e) {
        response.sendRedirect("list_events.jsp?errCode=invalidAction");
        return;
    }
    if (!mode.equals("delete") && !mode.equals("deactivate") && !mode.equals("activate")) {
        response.sendRedirect("list_events.jsp?errCode=invalidAction");
        return;
    }

 // Database Action Execution: delete event or toggle active/inactive status and redirect with result
    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        if (mode.equals("delete")) {
            String sql = "DELETE FROM events WHERE event_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, eventId);
            int rowsAffected = ps.executeUpdate();
            if (rowsAffected == 0) {
                response.sendRedirect("list_events.jsp?errCode=notFound");
                return;
            }
            response.sendRedirect("list_events.jsp?msg=eventDeleted");
            return;
        } else {
            String newStatus = mode.equals("activate") ? "active" : "inactive";
            String sql = "UPDATE events SET status = ? WHERE event_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, newStatus);
            ps.setInt(2, eventId);
            int rowsAffected = ps.executeUpdate();
            if (rowsAffected == 0) {
                response.sendRedirect("list_events.jsp?errCode=notFound");
                return;
            }
            response.sendRedirect("list_events.jsp?msg=" + (mode.equals("activate") ? "eventActivated" : "eventDeactivated"));
            return;
        }
    } catch (SQLIntegrityConstraintViolationException e) {
    	// Error Handling & Cleanup: catch FK constraint violations or DB errors, redirect, and close connection
        System.err.println("event_status_action.jsp - " + e);
        response.sendRedirect("list_events.jsp?errCode=hasRegistrations");
        return;
    } catch (Exception e) {
        System.err.println("event_status_action.jsp - " + e);
        response.sendRedirect("list_events.jsp?errCode=dbError");
        return;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>