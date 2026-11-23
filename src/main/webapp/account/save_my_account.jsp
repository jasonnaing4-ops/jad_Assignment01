<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
    import="java.sql.*, java.util.*, util.Validator" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Decision page for my_account.jsp - writes no HTML. Checks
    every field with util.Validator; a rejected submit is forwarded back to
    my_account.jsp with an errors map. The row to update comes from the
    userId in the session, never from the form, so nobody can change another
    person's details by editing a hidden field.
--%>
<%@ include file="/WEB-INF/common/require_participant.jsp" %>
<%
    request.setCharacterEncoding("UTF-8");

    // Step 1: Existence
    if (!"POST".equalsIgnoreCase(request.getMethod()) || request.getParameter("fullName") == null) {
        response.sendRedirect("my_account.jsp");
        return;
    }
    String fullName = Validator.clean(request.getParameter("fullName"));
    String contactNo = Validator.cleanContact(request.getParameter("contactNo"));
    String email = Validator.clean(request.getParameter("email")).toLowerCase();
    String dob = Validator.clean(request.getParameter("dateOfBirth"));
    String gender = Validator.clean(request.getParameter("gender"));

    // Step 2: Validate
    Map<String, String> errors = new LinkedHashMap<>();
    Validator.addError(errors, "fullName", Validator.fullName(fullName));
    Validator.addError(errors, "contactNo", Validator.contactNo(contactNo));
    Validator.addError(errors, "email", Validator.email(email));
    Validator.addError(errors, "dateOfBirth", Validator.dateOfBirth(dob));
    Validator.addError(errors, "gender", Validator.gender(gender));

    // Step 3: Process
    if (errors.isEmpty()) {
        Connection conn = null;
        try {
            Class.forName(jdbcDriver);
            conn = DriverManager.getConnection(connURL);
            String sql = "UPDATE participants SET full_name = ?, contact_no = ?, email = ?, "
                       + "date_of_birth = ?, gender = ? WHERE user_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, fullName);
            ps.setString(2, contactNo);
            ps.setString(3, email);
            if (dob.isEmpty()) { ps.setNull(4, Types.DATE); } else { ps.setDate(4, java.sql.Date.valueOf(dob)); }
            if (gender.isEmpty()) { ps.setNull(5, Types.VARCHAR); } else { ps.setString(5, gender); }
            ps.setInt(6, userId);
            ps.executeUpdate();
            response.sendRedirect("my_account.jsp?msg=detailsSaved");
            return;
        } catch (SQLIntegrityConstraintViolationException e) {
            errors.put("email", "That email is already used by another account.");
        } catch (Exception e) {
            System.err.println("save_my_account.jsp - " + e);
            request.setAttribute("formError", "Something went wrong saving your details. Please try again.");
        } finally {
            if (conn != null) {
                try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
            }
        }
    }

    // Rejected: back to the form, with the typed values still in this request
    request.setAttribute("errors", errors);
    request.getRequestDispatcher("/account/my_account.jsp").forward(request, response);
%>
