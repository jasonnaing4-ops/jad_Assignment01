<%--
    Author: Pyae Phyo Maung (P2535128)
    Date: 22/11/2026
    Description: One shared place for the JDBC driver class and connection URL
--%>
<%
    String jdbcDriver = "com.mysql.cj.jdbc.Driver";
    String connURL = util.DbConfig.getConnURL(application);
%>
