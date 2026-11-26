<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
    import="java.sql.*, java.util.*, util.Validator, util.PasswordUtil" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Decision page for both add_participant.jsp and
    edit_participant.jsp - writes no HTML. id is absent for a new participant
    (insert) and present for an existing one (update).
      - Every field is checked with util.Validator. A rejected submit is
        FORWARDED back to the form with an errors map, so the typed values are
        kept without putting personal details in the URL.
      - Add: hashes the password (util.PasswordUtil, bcrypt) and calls the
        stored procedure sp_register_participant with a CallableStatement
        (users + participants rows in one transaction, code generated), then
        optionally signs the participant up for the chosen event.
      - Edit: UPDATE with a PreparedStatement.
      - Success: redirect to the list with ?msg= (so a refresh cannot resubmit).
--%>
<%@ include file="/WEB-INF/common/require_staff.jsp" %>
<%
    request.setCharacterEncoding("UTF-8");

    // Step 1: Existence - only accept the forms' own POST
    if (!"POST".equalsIgnoreCase(request.getMethod()) || request.getParameter("fullName") == null) {
        response.sendRedirect("list_participants.jsp");
        return;
    }
    
    
    String idParam = request.getParameter("id");
    boolean isUpdate = (idParam != null && !idParam.trim().isEmpty());
    String formPage = isUpdate ? "/participant/edit_participant.jsp" : "/participant/add_participant.jsp";

    String fullName = Validator.clean(request.getParameter("fullName"));
    String contactNo = Validator.cleanContact(request.getParameter("contactNo"));
    String email = Validator.clean(request.getParameter("email")).toLowerCase();
    String dob = Validator.clean(request.getParameter("dateOfBirth"));
    String gender = Validator.clean(request.getParameter("gender"));
    String username = Validator.clean(request.getParameter("username"));
    String password = request.getParameter("password");             // passwords are not trimmed
    String confirm = request.getParameter("confirmPassword");
    String eventIdParam = Validator.clean(request.getParameter("eventId"));

    // Step 2: Validate
    int participantId = -1;
    if (isUpdate) {
        participantId = Validator.parseId(idParam);
        if (participantId < 0) {
            response.sendRedirect("list_participants.jsp?errCode=invalidAction");
            return;
        }
    }

    Map<String, String> errors = new LinkedHashMap<>();
    Validator.addError(errors, "fullName", Validator.fullName(fullName));
    Validator.addError(errors, "contactNo", Validator.contactNo(contactNo));
    Validator.addError(errors, "email", Validator.email(email));
    Validator.addError(errors, "dateOfBirth", Validator.dateOfBirth(dob));
    Validator.addError(errors, "gender", Validator.gender(gender));
    int eventId = -1;
    if (!isUpdate) {
        Validator.addError(errors, "username", Validator.username(username));
        Validator.addError(errors, "password", Validator.password(password));
        Validator.addError(errors, "confirmPassword", Validator.passwordMatch(password, confirm));
        if (!eventIdParam.isEmpty()) {
            eventId = Validator.parseId(eventIdParam);
            if (eventId < 0) {
                errors.put("eventId", "Please choose an event from the list.");
            }
        }
    }

    // Step 3: Process
    if (errors.isEmpty()) {
        Connection conn = null;
        try {
            Class.forName(jdbcDriver);
            conn = DriverManager.getConnection(connURL);

            if (isUpdate) {
                String sql = "UPDATE participants SET full_name = ?, contact_no = ?, email = ?, "
                           + "date_of_birth = ?, gender = ? WHERE participant_id = ?";
                PreparedStatement ps = conn.prepareStatement(sql);
                ps.setString(1, fullName);
                ps.setString(2, contactNo);
                ps.setString(3, email);
                if (dob.isEmpty()) { ps.setNull(4, Types.DATE); } else { ps.setDate(4, java.sql.Date.valueOf(dob)); }
                if (gender.isEmpty()) { ps.setNull(5, Types.VARCHAR); } else { ps.setString(5, gender); }
                ps.setInt(6, participantId);
                int rowsAffected = ps.executeUpdate();
                if (rowsAffected == 0) {
                    response.sendRedirect("list_participants.jsp?errCode=notFound");
                    return;
                }
                response.sendRedirect("list_participants.jsp?msg=participantUpdated");
                return;
            }

            // Add: check the chosen event BEFORE creating anything
            if (eventId > 0) {
                PreparedStatement evPs = conn.prepareStatement(
                        "SELECT event_id FROM events WHERE event_id = ? AND status = 'active' AND event_date >= CURDATE()");
                evPs.setInt(1, eventId);
                ResultSet evRs = evPs.executeQuery();
                if (!evRs.next()) {
                    errors.put("eventId", "That event is not open for sign-ups. Choose an upcoming event, or none.");
                }
            }

            if (errors.isEmpty()) {
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

                // The success message names the participant that was just created,
                // using the code the stored procedure generated (e.g. P-00007).
                // Kept in the session for ONE page view (messages.jsp reads and removes
                // it), so nothing about the participant goes into the URL.
                String newCode = null;
                PreparedStatement codePs = conn.prepareStatement(
                        "SELECT participant_code FROM participants WHERE participant_id = ?");
                codePs.setInt(1, newParticipantId);
                ResultSet codeRs = codePs.executeQuery();
                if (codeRs.next()) { newCode = codeRs.getString("participant_code"); }
                session.setAttribute("flashAddedCode", newCode);
                session.setAttribute("flashAddedName", fullName);

                if (eventId > 0) {
                    PreparedStatement regPs = conn.prepareStatement(
                            "INSERT INTO event_registrations (participant_id, event_id, status) VALUES (?, ?, 'registered')");
                    regPs.setInt(1, newParticipantId);
                    regPs.setInt(2, eventId);
                    regPs.executeUpdate();

                    PreparedStatement evNamePs = conn.prepareStatement("SELECT event_name FROM events WHERE event_id = ?");
                    evNamePs.setInt(1, eventId);
                    ResultSet evNameRs = evNamePs.executeQuery();
                    if (evNameRs.next()) { session.setAttribute("flashAddedEvent", evNameRs.getString("event_name")); }

                    response.sendRedirect("list_participants.jsp?msg=participantAddedSignedUp");
                } else {
                    response.sendRedirect("list_participants.jsp?msg=participantAdded");
                }
                return;
            }
        } catch (SQLIntegrityConstraintViolationException e) {
            // a UNIQUE key was broken - say which field, so staff can fix it
            String m = String.valueOf(e.getMessage());
            if (m.contains("uq_users_username")) {
                errors.put("username", "That username is already taken. Please choose another.");
            } else if (m.contains("uq_participant_email")) {
                errors.put("email", "That email is already used by another account.");
            } else {
                request.setAttribute("formError", "Those details are already in use.");
            }
        } catch (Exception e) {
            System.err.println("save_participant.jsp - " + e);
            request.setAttribute("formError", "Something went wrong saving the participant. Please try again.");
        } finally {
            if (conn != null) {
                try { conn.close(); } catch (SQLException e) { System.err.println("Error closing connection: " + e); }
            }
        }
    }

    // Rejected: back to the form, with the typed values still in this request
    request.setAttribute("errors", errors);
    request.getRequestDispatcher(formPage).forward(request, response);
%>