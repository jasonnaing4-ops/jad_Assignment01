/*
S	Author: Pyae Phyo Maung (P2535128)
	Date: 22/11/2026
	Description: Hashes and checks passwords with bcrypt (jBCrypt library).
	The hash (60 characters, salt included) is what goes in users.password_hash.
	Needs jbcrypt-0.4.jar in WEB-INF/lib and on the Eclipse build path.
*/
package util;

import org.mindrot.jbcrypt.BCrypt;

public class PasswordUtil {

	// Cost factor: 10 means 2^10 rounds of hashing (slow on purpose)
	private static final int LOG_ROUNDS = 10;

	// Use at sign-up / when staff create an account.
	// Returns the 60-character string to store in users.password_hash
	public static String hash(String password) {
		return BCrypt.hashpw(password, BCrypt.gensalt(LOG_ROUNDS));
	}

	// Use at login: true only if the typed password matches the stored hash.
	// Any problem (null, malformed hash) counts as a failed login.
	public static boolean verify(String password, String storedHash) {
		try {
			if (password == null || storedHash == null) {
				return false;
			}
			return BCrypt.checkpw(password, storedHash);
		} catch (Exception e) {
			System.err.println("PasswordUtil.verify - " + e);
			return false;
		}
	}
}
