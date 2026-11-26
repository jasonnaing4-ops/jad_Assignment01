<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Logout - invalidates the session then sends the
    user back to the login page.
--%>
<%
    session.invalidate();
    response.sendRedirect("login.jsp?msg=loggedOut");
%>
