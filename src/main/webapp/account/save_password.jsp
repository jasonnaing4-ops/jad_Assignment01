<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
    import="java.sql.*, java.util.*, util.Validator, util.PasswordUtil" %>
<%--
    Description: Decision page for change_password.jsp - writes no HTML.
      - The account is the one in the session (userId), never one from the form.
      - The current (or demo) password must be correct, checked with bcrypt.
      - The new password must pass Validator.password(), be typed twice the
        same, and differ from the current one (so the demo password cannot be
        kept).
      - Saves only the new bcrypt hash and clears users.must_change_password,
        which lets the participant use the rest of the site.
    A rejected submit is forwarded back to change_password.jsp with an errors
    map. Passwords are never trimmed, logged or put in a URL.
--%>
<%@ include file="/WEB-INF/common/require_participant.jsp" %>
<%
    request.setCharacterEncoding("UTF-8");

    // Step 1: Existence - only accept the form's own POST
    if (!"POST".equalsIgnoreCase(request.getMethod()) || request.getParameter("newPassword") == null) {
        response.sendRedirect("change_password.jsp");
        return;
    }
    String currentPassword = request.getParameter("currentPassword");   // passwords are not trimmed
    String newPassword = request.getParameter("newPassword");
    String confirm = request.getParameter("confirmPassword");

    // Step 2: Validate - every field, in form order
    Map<String, String> errors = new LinkedHashMap<>();
    if (currentPassword == null || currentPassword.isEmpty()) {
        errors.put("currentPassword", (guardMustChange ? "Demo password" : "Current password") + " is required.");
    }
    Validator.addError(errors, "newPassword", Validator.password(newPassword));
    Validator.addError(errors, "confirmPassword", Validator.passwordMatch(newPassword, confirm));

    // Step 3: Process
    if (errors.isEmpty()) {
        Connection conn = null;
        try {
            Class.forName(jdbcDriver);
            conn = DriverManager.getConnection(connURL);

            String storedHash = null;
            PreparedStatement findPs = conn.prepareStatement("SELECT password_hash FROM users WHERE user_id = ?");
            findPs.setInt(1, userId);
            ResultSet findRs = findPs.executeQuery();
            if (findRs.next()) { storedHash = findRs.getString("password_hash"); }

            if (!PasswordUtil.verify(currentPassword, storedHash)) {
                errors.put("currentPassword", (guardMustChange ? "That demo password" : "Your current password") + " is not correct.");
            } else if (newPassword.equals(currentPassword)) {
                errors.put("newPassword", "Choose a password that is different from your current one.");
            } else {
                PreparedStatement ps = conn.prepareStatement(
                        "UPDATE users SET password_hash = ?, must_change_password = 0 WHERE user_id = ?");
                ps.setString(1, PasswordUtil.hash(newPassword));   // only the bcrypt hash is stored
                ps.setInt(2, userId);
                ps.executeUpdate();

                // forced change: on to their events; voluntary change: back to My Account
                response.sendRedirect((guardMustChange ? "my_signups.jsp" : "my_account.jsp") + "?msg=passwordChanged");
                return;
            }
        } catch (Exception e) {
            System.err.println("save_password.jsp - " + e);
            request.setAttribute("formError", "Something went wrong saving your password. Please try again.");
        } finally {
            if (conn != null) {
                try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
            }
        }
    }

    // Rejected: back to the form (passwords are not sent back)
    request.setAttribute("errors", errors);
    request.getRequestDispatcher("/account/change_password.jsp").forward(request, response);
%>