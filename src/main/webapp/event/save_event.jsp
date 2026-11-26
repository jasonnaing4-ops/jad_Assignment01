<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.sql.*" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Decision page for both add_event.jsp and edit_event.jsp - no
    HTML, every path ends in a redirect. id is blank/absent for a
    new event (insert) and present for an existing one (update).
--%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>
<%
	//Input Extraction & State Preservation: read parameters, detect insert vs. update, and build redirect query string    
	String eventName = request.getParameter("eventName");
    String eventDateStr = request.getParameter("eventDate");
    String venue = request.getParameter("venue");
    String startTimeStr = request.getParameter("startTime");
    String endTimeStr = request.getParameter("endTime");
    String description = request.getParameter("description");
    String idParam = request.getParameter("id");
    String capacityStr = request.getParameter("capacity");
    boolean isUpdate = (idParam != null && !idParam.trim().isEmpty());

    if (eventName == null || eventDateStr == null || startTimeStr == null || endTimeStr == null) {
        response.sendRedirect("list_events.jsp");
        return;
    }

    String formPage = isUpdate ? "edit_event.jsp" : "add_event.jsp";
    String preserveParams = "eventName=" + java.net.URLEncoder.encode(eventName, "UTF-8")
            + "&eventDate=" + java.net.URLEncoder.encode(eventDateStr, "UTF-8")
            + "&venue=" + java.net.URLEncoder.encode(venue == null ? "" : venue, "UTF-8")
            + "&startTime=" + java.net.URLEncoder.encode(startTimeStr, "UTF-8")
            + "&endTime=" + java.net.URLEncoder.encode(endTimeStr, "UTF-8")
            + "&description=" + java.net.URLEncoder.encode(description == null ? "" : description, "UTF-8")
            + "&capacity=" + java.net.URLEncoder.encode(capacityStr == null ? "" : capacityStr, "UTF-8")
            + (isUpdate ? "&id=" + idParam.trim() : "");

 	// Input Validation & Normalization: verify required fields, date/time rules, capacity limits, and set defaults
    if (eventName.trim().isEmpty() || eventDateStr.trim().isEmpty()
            || startTimeStr.trim().isEmpty() || endTimeStr.trim().isEmpty()) {
        response.sendRedirect(formPage + "?errCode=emptyFields&" + preserveParams);
        return;
    }

    java.sql.Date eventDate;
    try {
        eventDate = java.sql.Date.valueOf(eventDateStr.trim());
    } catch (Exception e) {
        response.sendRedirect(formPage + "?errCode=badDate&" + preserveParams);
        return;
    }

 	// <input type="time"> sends HH:mm, java.sql.Time.valueOf wants HH:mm:ss
    java.sql.Time startTime;
    java.sql.Time endTime;
    try {
        String st = startTimeStr.trim();
        String et = endTimeStr.trim();
        if (st.length() == 5) { st = st + ":00"; }
        if (et.length() == 5) { et = et + ":00"; }
        startTime = java.sql.Time.valueOf(st);
        endTime = java.sql.Time.valueOf(et);
    } catch (Exception e) {
        response.sendRedirect(formPage + "?errCode=badTime&" + preserveParams);
        return;
    }
    if (!endTime.after(startTime)) {
        response.sendRedirect(formPage + "?errCode=endBeforeStart&" + preserveParams);
        return;
    }
    
    int capacity;
    try {
        capacity = Integer.parseInt(capacityStr == null ? "" : capacityStr.trim());
        if (capacity < 1 || capacity > 100000) { throw new NumberFormatException(); }
    } catch (Exception e) {
        response.sendRedirect(formPage + "?errCode=badCapacity&" + preserveParams);
        return;
    }
    
    // Date can't be in the past (today is fine) - applies to add and edit
    if (eventDate.toLocalDate().isBefore(java.time.LocalDate.now())) {
        response.sendRedirect(formPage + "?errCode=pastDate&" + preserveParams);
        return;
    }
    // On today's date, the start time can't already have passed
    if (eventDate.toLocalDate().equals(java.time.LocalDate.now())
            && startTime.toLocalTime().isBefore(java.time.LocalTime.now())) {
        response.sendRedirect(formPage + "?errCode=pastTime&" + preserveParams);
        return;
    }

    // description is optional; store NULL instead of an empty string
    String descriptionToSave = (description == null || description.trim().isEmpty()) ? null : description.trim();

    Integer eventId = null;
    if (isUpdate) {
        try {
            eventId = Integer.parseInt(idParam.trim());
        } catch (Exception e) {
            response.sendRedirect("list_events.jsp?errCode=invalidAction");
            return;
        }
    }

    String status = request.getParameter("status");
    if (status == null || (!status.equals("active") && !status.equals("inactive"))) {
        status = "active";
    }

 	// Database Persistence (Insert / Update): save event changes to MySQL and redirect to event list
    Connection conn = null;
    try {
        Class.forName(jdbcDriver);
        conn = DriverManager.getConnection(connURL);

        if (isUpdate) {
	            String sql = "UPDATE events SET event_name = ?, event_date = ?, venue = ?, status = ?, "
	                    + "start_time = ?, end_time = ?, description = ?, capacity = ? WHERE event_id = ?";
	         PreparedStatement ps = conn.prepareStatement(sql);
	         ps.setString(1, eventName.trim());
	         ps.setDate(2, eventDate);
	         ps.setString(3, venue == null ? null : venue.trim());
	         ps.setString(4, status);
	         ps.setTime(5, startTime);
	         ps.setTime(6, endTime);
	         ps.setString(7, descriptionToSave);
	         ps.setInt(8, capacity);
	         ps.setInt(9, eventId); 
	         int rowsAffected = ps.executeUpdate();
	         if (rowsAffected == 0) {
                response.sendRedirect("list_events.jsp?errCode=notFound");
                return;
            }
            response.sendRedirect("list_events.jsp?msg=eventUpdated");
            return;
        } else {
	            String sql = "INSERT INTO events (event_name, event_date, venue, status, start_time, end_time, description, capacity) "
	                    + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
	         PreparedStatement ps = conn.prepareStatement(sql);
	         ps.setString(1, eventName.trim());
	         ps.setDate(2, eventDate);
	         ps.setString(3, venue == null ? null : venue.trim());
	         ps.setString(4, status);
	         ps.setTime(5, startTime);
	         ps.setTime(6, endTime);
	         ps.setString(7, descriptionToSave);
	         ps.setInt(8, capacity);
	         ps.executeUpdate();
            response.sendRedirect("list_events.jsp?msg=eventAdded");
            return;
        }
    } catch (Exception e) {
    	// Error Handling & Cleanup: log exceptions, redirect back with preserved form data, and close connection
        System.err.println("save_event.jsp - " + e);
        response.sendRedirect(formPage + "?errCode=dbError&" + preserveParams);
        return;
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
        }
    }
%>