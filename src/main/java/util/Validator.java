/*
	Author: Bhone Theinkha Naing (Jason) (<admin no.>)
	Date: 23/11/2026
	Description: Server-side validation for form input.
	Each check returns null when the value is valid, or a message to show
	next to the field when it is not. The participant forms and the event
	forms both use this class. These checks are the real ones: HTML
	attributes such as required only help the user and can be bypassed.

	How a decision page uses it:
		Map<String, String> errors = new LinkedHashMap<>();
		Validator.addError(errors, "email", Validator.email(email));
		if (!errors.isEmpty()) {
			request.setAttribute("errors", errors);
			// forward (not redirect) back to the form: the typed values stay
			// in the request, so personal details never go into the URL
		}
*/
package util;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Map;

public class Validator {

	// Maximum lengths match the column sizes in the database
	public static final int NAME_MAX = 100;
	public static final int EMAIL_MAX = 100;
	public static final int USERNAME_MIN = 3;
	public static final int USERNAME_MAX = 50;
	public static final int PASSWORD_MIN = 8;
	public static final int PASSWORD_MAX_BYTES = 72;   // bcrypt ignores anything after 72 bytes

	// Values allowed in participants.gender (the column also allows NULL)
	public static final String[] GENDERS = { "Male", "Female", "Prefer not to say" };

	// ---------- small helpers ----------

	// Returns the trimmed value, or "" when the value is null.
	public static String clean(String value) {
		if (value == null) {
			return "";
		}
		return value.trim();
	}

	public static boolean isBlank(String value) {
		return clean(value).isEmpty();
	}

	// Only trims the ends; a space inside the number is NOT removed, so "9123 4567" is rejected.
	public static String cleanContact(String value) {
		return clean(value);
	}

	// Adds the message under the field name, but only if there is a message.
	public static void addError(Map<String, String> errors, String field, String message) {
		if (message != null) {
			errors.put(field, message);
		}
	}

	// Returns the message for one field, or null. Safe to call with errors == null.
	public static String errorFor(Map<String, String> errors, String field) {
		if (errors == null) {
			return null;
		}
		return errors.get(field);
	}

	// Turns an id from the URL or a form into a number.
	// Returns -1 when it is missing, not a whole number, or below 1.
	public static int parseId(String value) {
		try {
			int id = Integer.parseInt(clean(value));
			if (id < 1) {
				return -1;
			}
			return id;
		} catch (NumberFormatException e) {
			return -1;
		}
	}

	// Turns "yyyy-MM-dd" (what <input type="date"> sends) into a LocalDate.
	// Returns null when it is blank or not a real date.
	public static LocalDate parseDate(String value) {
		try {
			return LocalDate.parse(clean(value));
		} catch (DateTimeParseException e) {
			return null;
		}
	}

	// ---------- general checks (also used by the event forms) ----------

	public static String required(String value, String label) {
		if (isBlank(value)) {
			return label + " is required.";
		}
		return null;
	}

	public static String maxLength(String value, int max, String label) {
		if (clean(value).length() > max) {
			return label + " must be " + max + " characters or fewer.";
		}
		return null;
	}

	// A date that must be filled in and must be real.
	public static String date(String value, String label) {
		if (isBlank(value)) {
			return label + " is required.";
		}
		if (parseDate(value) == null) {
			return label + " is not a valid date.";
		}
		return null;
	}

	// A date that must be today or later, e.g. the date of a new event.
	public static String dateNotPast(String value, String label) {
		String problem = date(value, label);
		if (problem != null) {
			return problem;
		}
		if (parseDate(value).isBefore(LocalDate.now())) {
			return label + " cannot be in the past.";
		}
		return null;
	}

	// ---------- participant and account checks ----------

	public static String fullName(String value) {
		String v = clean(value);
		if (v.isEmpty()) {
			return "Full name is required.";
		}
		if (v.length() > NAME_MAX) {
			return "Full name must be " + NAME_MAX + " characters or fewer.";
		}
		// letters, spaces and the punctuation found in names, e.g. O'Brien, Lim-Tan, d/o
		if (!v.matches("[A-Za-z][A-Za-z .,'/-]*")) {
			return "Full name can only contain letters, spaces and . , ' - /";
		}
		return null;
	}

	public static String username(String value) {
		String v = clean(value);
		if (v.isEmpty()) {
			return "Username is required.";
		}
		if (v.length() < USERNAME_MIN || v.length() > USERNAME_MAX) {
			return "Username must be " + USERNAME_MIN + " to " + USERNAME_MAX + " characters.";
		}
		if (!v.matches("[A-Za-z0-9_]+")) {
			return "Username can only contain letters, numbers and _";
		}
		return null;
	}

	// Passwords are NOT trimmed: a space is a valid password character.
	public static String password(String value) {
		if (value == null || value.isEmpty()) {
			return "Password is required.";
		}
		if (value.length() < PASSWORD_MIN) {
			return "Password must be at least " + PASSWORD_MIN + " characters.";
		}
		if (value.getBytes(StandardCharsets.UTF_8).length > PASSWORD_MAX_BYTES) {
			return "Password is too long (72 characters at most).";
		}
		if (!value.matches(".*[A-Za-z].*") || !value.matches(".*[0-9].*")) {
			return "Password must contain at least one letter and one number.";
		}
		return null;
	}

	public static String passwordMatch(String password, String confirm) {
		if (confirm == null || confirm.isEmpty()) {
			return "Please type the password again.";
		}
		if (!confirm.equals(password)) {
			return "The two passwords do not match.";
		}
		return null;
	}

	// Singapore numbers: exactly 8 digits starting with 6, 8 or 9 - no spaces or other characters.
	public static String contactNo(String value) {
		String v = cleanContact(value);
		if (v.isEmpty()) {
			return "Contact number is required.";
		}
		if (!v.matches("[689][0-9]{7}")) {
			return "Enter an 8-digit number starting with 6, 8 or 9, e.g. 91234567.";
		}
		return null;
	}

	public static String email(String value) {
		String v = clean(value);
		if (v.isEmpty()) {
			return "Email is required.";
		}
		if (v.length() > EMAIL_MAX) {
			return "Email must be " + EMAIL_MAX + " characters or fewer.";
		}
		if (!v.matches("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")) {
			return "Enter a valid email address, e.g. name@example.com.";
		}
		return null;
	}

	// Optional: blank is allowed, but a value must be a real, sensible date.
	public static String dateOfBirth(String value) {
		if (isBlank(value)) {
			return null;
		}
		LocalDate dob = parseDate(value);
		if (dob == null) {
			return "Date of birth is not a valid date.";
		}
		if (dob.isAfter(LocalDate.now())) {
			return "Date of birth cannot be in the future.";
		}
		if (dob.isBefore(LocalDate.of(1900, 1, 1))) {
			return "Date of birth must be after 1900.";
		}
		return null;
	}

	// Optional: blank is allowed, otherwise it must be one of GENDERS.
	public static String gender(String value) {
		if (isBlank(value)) {
			return null;
		}
		for (String g : GENDERS) {
			if (g.equals(clean(value))) {
				return null;
			}
		}
		return "Please choose a gender from the list.";
	}
}
