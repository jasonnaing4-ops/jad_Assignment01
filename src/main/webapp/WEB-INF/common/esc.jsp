<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Shared esc() helper.

    Include ONCE per page, with:
        <%@ include file="/WEB-INF/common/esc.jsp" %>

    common/header.jsp already includes this, so any page that includes
    header.jsp already has esc() available and must NOT include this file
    again itself (that would declare the method twice and fail to compile).
--%>
<%!
//XSS Output Sanitization: declare page-level helper to HTML-escape special characters and handle nulls safely
    private String esc(String s) {
        if (s == null) { return ""; }
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
