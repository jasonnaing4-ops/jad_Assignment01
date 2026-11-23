<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Shown when a page does not exist (status 404), as set up in
    WEB-INF/web.xml. The status stays 404.
--%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Page not found - Vision Screening Station Management System</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body class="bg-light">
<nav class="navbar navbar-dark bg-brand">
    <div class="container-fluid px-4"><span class="navbar-brand fw-bold mb-0">Vision Screening Station Management System</span></div>
</nav>
<main class="container my-5" style="max-width: 640px;">
    <div class="card shadow-sm text-center">
        <div class="card-body p-5">
            <h1 class="h3 text-primary mb-3">Page not found</h1>
            <p>The page you asked for does not exist. Check the address, or go back to the home page.</p>
            <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-primary">Back to Home</a>
        </div>
    </div>
</main>
</body>
</html>
