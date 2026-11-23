<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Shown for any unexpected error (status 500 or an uncaught
    exception), as set up in WEB-INF/web.xml. The real problem is written to
    the server log through the application object; the user only sees a
    plain message, so SQL errors and stack traces never reach the browser.
    It deliberately does not include header.jsp: if the header itself caused
    the error, including it again would fail a second time.
--%>
<%
    String failedPage = pageContext.getErrorData().getRequestURI();
    if (exception != null) {   // exception exists only because isErrorPage="true"
        application.log("Unhandled error on " + failedPage, exception);
    } else {
        application.log("Error " + pageContext.getErrorData().getStatusCode() + " on " + failedPage);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Something went wrong - Vision Screening Station Management System</title>
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
            <h1 class="h3 text-primary mb-3">Sorry, something went wrong</h1>
            <p>We could not finish that request. Please go back and try again.</p>
            <p class="text-muted small">If this keeps happening, please tell the screening staff.</p>
            <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-primary">Back to Home</a>
        </div>
    </div>
</main>
</body>
</html>
