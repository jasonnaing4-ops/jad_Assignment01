<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Entry point for the app. No session/role logic belongs here -
    just send everyone to the login page, which decides what to show next.
    This is the only redirect in the file, so no "return;" after it (Jasper
    treats a trailing return at the very end of a scriptlet as unreachable
    code - see section 2 of the coding conventions).
--%>
<%
    response.sendRedirect("login/login.jsp");
%>
