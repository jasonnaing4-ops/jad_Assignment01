<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: Shared footer. Include at the bottom of every page that
    included header.jsp - closes the card/<main>/<body>/<html> tags that header.jsp
    opened:

        <%@ include file="/WEB-INF/common/footer.jsp" %>
--%>

<%-- Close Main Content Containers: close card, wrapper, and <main> tags opened by header.jsp --%>
</div>
</div>
</main>

<%-- Global Footer & Document Close: render module footer text and close <body>/<html> tags --%>
<footer class="text-center text-muted small py-3">
    <p class="mb-0">ST0510 J2EE Application Development &mdash; Vision Screening Station Management System</p>
</footer>
</body>
</html>