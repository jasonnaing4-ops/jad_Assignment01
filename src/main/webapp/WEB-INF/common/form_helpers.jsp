<%@ page import="java.util.Map" %>
<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: Small helper methods for showing a validation error next to
    the field it belongs to (field-level feedback, section 3.4). Declared with
    <%! %> because they are stateless methods, like esc().

    Include ONCE per form page, after header.jsp (errText uses esc()):
        <%@ include file="/WEB-INF/common/form_helpers.jsp" %>

    Use on an input, where errors is the Map the decision page forwarded:
        <input id="email" name="email" class="form-control<%= invalidClass(errors, "email") %>"
               <%= errAria(errors, "email") %>>
        <%= errText(errors, "email") %>
--%>
<%!
    // " is-invalid" (Bootstrap's red border) when the field failed validation
    private String invalidClass(Map<String, String> errors, String field) {
        if (errors == null || errors.get(field) == null) { return ""; }
        return " is-invalid";
    }

    // Links the input to its message so screen readers read the error out
    private String errAria(Map<String, String> errors, String field) {
        if (errors == null || errors.get(field) == null) { return ""; }
        return "aria-invalid=\"true\" aria-describedby=\"" + field + "Err\"";
    }

    // The message under the field, or "" when the field is fine
    private String errText(Map<String, String> errors, String field) {
        if (errors == null || errors.get(field) == null) { return ""; }
        return "<div id=\"" + field + "Err\" class=\"invalid-feedback d-block\">" + esc(errors.get(field)) + "</div>";
    }

    // " selected" when a dropdown option matches the current value
    private String selectedIf(String current, String option) {
        return option.equals(current) ? " selected" : "";
    }
%>
