<%--
    Author: Bhone Theinkha Naing (Jason) (<admin no.>)
    Date: 23/11/2026
    Description: The participant detail inputs (name, contact, email, date of
    birth, gender), shared by login/register.jsp, participant/add_participant.jsp,
    participant/edit_participant.jsp and account/my_account.jsp, so the forms
    always match. Include INSIDE the page's own <form>:

        <%@ include file="/WEB-INF/common/participant_fields.jsp" %>

    The including page must already have:
      - esc() (from header.jsp) and form_helpers.jsp
      - String fFullName, fContactNo, fEmail, fDob, fGender  (null is fine)
      - Map<String, String> errors                          (null is fine)
--%>
<div class="mb-3">
    <label for="fullName" class="form-label fw-semibold">Full Name <span class="text-danger">*</span></label>
    <input type="text" id="fullName" name="fullName" maxlength="100" autocomplete="name"
           class="form-control<%= invalidClass(errors, "fullName") %>" value="<%= esc(fFullName) %>" <%= errAria(errors, "fullName") %>>
    <%= errText(errors, "fullName") %>
</div>
<div class="row g-3 mb-3">
    <div class="col-md-6">
        <label for="contactNo" class="form-label fw-semibold">Contact Number <span class="text-danger">*</span></label>
        <input type="tel" id="contactNo" name="contactNo" maxlength="8" pattern="[689][0-9]{7}" inputmode="numeric" autocomplete="tel"
               class="form-control<%= invalidClass(errors, "contactNo") %>" value="<%= esc(fContactNo) %>" <%= errAria(errors, "contactNo") %>>
        <div class="form-text">8 digits, no spaces, e.g. 91234567</div>
        <%= errText(errors, "contactNo") %>
    </div>
    <div class="col-md-6">
        <label for="email" class="form-label fw-semibold">Email <span class="text-danger">*</span></label>
        <input type="email" id="email" name="email" maxlength="100" autocomplete="email"
               class="form-control<%= invalidClass(errors, "email") %>" value="<%= esc(fEmail) %>" <%= errAria(errors, "email") %>>
        <%= errText(errors, "email") %>
    </div>
</div>
<div class="row g-3 mb-3">
    <div class="col-md-6">
        <label for="dateOfBirth" class="form-label fw-semibold">Date of Birth</label>
        <input type="date" id="dateOfBirth" name="dateOfBirth" max="<%= java.time.LocalDate.now() %>"
               class="form-control<%= invalidClass(errors, "dateOfBirth") %>" value="<%= esc(fDob) %>" <%= errAria(errors, "dateOfBirth") %>>
        <%= errText(errors, "dateOfBirth") %>
    </div>
    <div class="col-md-6">
        <label for="gender" class="form-label fw-semibold">Gender</label>
        <select id="gender" name="gender" class="form-select<%= invalidClass(errors, "gender") %>" <%= errAria(errors, "gender") %>>
            <option value="">Not specified</option>
            <% for (String g : util.Validator.GENDERS) { %>
                <option value="<%= esc(g) %>"<%= selectedIf(fGender, g) %>><%= esc(g) %></option>
            <% } %>
        </select>
        <%= errText(errors, "gender") %>
    </div>
</div>
