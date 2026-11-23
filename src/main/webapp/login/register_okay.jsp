<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
    import="java.sql.*, java.util.*, util.Validator, util.PasswordUtil" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Decision page for register.jsp - writes no HTML. Every field
    is checked on the server with util.Validator. A rejected submit is
    forwarded back to register.jsp with an errors map (field -> message).
    A good one hashes the password with util.PasswordUtil (bcrypt) and calls
    the stored procedure sp_register_participant through a CallableStatement,
    which creates the users row and the participants row in ONE transaction
    and generates the participant code (P-00007). Then redirects to login.
--%>
<%@ include file="/WEB-INF/common/dbconfig.jsp" %>
<%
    request.setCharacterEncoding("UTF-8");

    // Step 1: Existence - only accept the form's own POST
    if (!"POST".equalsIgnoreCase(request.getMethod()) || request.getParameter("username") == null) {
        response.sendRedirect("register.jsp");
        return;
    }
    String username = Validator.clean(request.getParameter("username"));
    String password = request.getParameter("password");            // passwords are not trimmed
    String confirm = request.getParameter("confirmPassword");
    String fullName = Validator.clean(request.getParameter("fullName"));
    String contactNo = Validator.cleanContact(request.getParameter("contactNo"));
    String email = Validator.clean(request.getParameter("email")).toLowerCase();
    String dob = Validator.clean(request.getParameter("dateOfBirth"));
    String gender = Validator.clean(request.getParameter("gender"));

    // Step 2: Validate - every field, in form order, so the summary reads top to bottom
    Map<String, String> errors = new LinkedHashMap<>();
    Validator.addError(errors, "fullName", Validator.fullName(fullName));
    Validator.addError(errors, "contactNo", Validator.contactNo(contactNo));
    Validator.addError(errors, "email", Validator.email(email));
    Validator.addError(errors, "dateOfBirth", Validator.dateOfBirth(dob));
    Validator.addError(errors, "gender", Validator.gender(gender));
    Validator.addError(errors, "username", Validator.username(username));
    Validator.addError(errors, "password", Validator.password(password));
    Validator.addError(errors, "confirmPassword", Validator.passwordMatch(password, confirm));

    // Step 3: Process
    if (errors.isEmpty()) {
        Connection conn = null;
        try {
            Class.forName(jdbcDriver);
            conn = DriverManager.getConnection(connURL);

            CallableStatement cs = conn.prepareCall("{call sp_register_participant(?, ?, ?, ?, ?, ?)}");
            cs.setString(1, username);
            cs.setString(2, PasswordUtil.hash(password));   // only the bcrypt hash is stored
            cs.setString(3, fullName);
            cs.setString(4, contactNo);
            cs.setString(5, email);
            cs.registerOutParameter(6, Types.INTEGER);
            cs.execute();
            int newParticipantId = cs.getInt(6);

            // date of birth and gender are optional and are not parameters of the procedure
            if (!dob.isEmpty() || !gender.isEmpty()) {
                PreparedStatement ps = conn.prepareStatement(
                        "UPDATE participants SET date_of_birth = ?, gender = ? WHERE participant_id = ?");
                if (dob.isEmpty()) { ps.setNull(1, Types.DATE); } else { ps.setDate(1, java.sql.Date.valueOf(dob)); }
                if (gender.isEmpty()) { ps.setNull(2, Types.VARCHAR); } else { ps.setString(2, gender); }
                ps.setInt(3, newParticipantId);
                ps.executeUpdate();
            }

            response.sendRedirect("login.jsp?msg=accountCreated");
            return;
        } catch (SQLIntegrityConstraintViolationException e) {
            // a UNIQUE key was broken - tell the user which field, so they can fix it
            String m = String.valueOf(e.getMessage());
            if (m.contains("uq_users_username")) {
                errors.put("username", "That username is already taken. Please choose another.");
            } else if (m.contains("uq_participant_email")) {
                errors.put("email", "That email is already used by another account.");
            } else {
                request.setAttribute("formError", "Those details are already in use.");
            }
        } catch (Exception e) {
            System.err.println("register_okay.jsp - " + e);
            request.setAttribute("formError", "Something went wrong creating your account. Please try again.");
        } finally {
            if (conn != null) {
                try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
            }
        }
    }

    // Rejected: back to the form, with the typed values still in this request
    request.setAttribute("errors", errors);
    request.getRequestDispatcher("/login/register.jsp").forward(request, response);
%>
