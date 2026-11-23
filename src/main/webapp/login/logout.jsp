<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Logout - invalidates the session (section 2.5) then sends the
    user back to the login page. No parameters are read here, so there is
    nothing to run the existence/validate steps on; this is the single,
    page-final redirect, so no "return;" after it.
--%>
<%
    session.invalidate();
    response.sendRedirect("login.jsp?msg=loggedOut");
%>
