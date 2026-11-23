<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Shared esc() helper (section 5 of the coding conventions -
    XSS escaping for any value that came from the request or the database).
    Declared with <%! %> because it is a stateless method, not a field, which
    is the one case the conventions doc allows inside <%! %>.

    Include ONCE per page, with:
        <%@ include file="/WEB-INF/common/esc.jsp" %>

    common/header.jsp already includes this, so any page that includes
    header.jsp already has esc() available and must NOT include this file
    again itself (that would declare the method twice and fail to compile).
--%>
<%!
    private String esc(String s) {
        if (s == null) { return ""; }
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
