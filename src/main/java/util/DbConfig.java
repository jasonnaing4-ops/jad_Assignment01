package util;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Properties;

import jakarta.servlet.ServletContext;

/**
 * Builds the JDBC connection URL from WEB-INF/.env so the DB credentials
 * live in one file instead of being hard-coded in several JSPs.
 */
public class DbConfig {

    public static String getConnURL(ServletContext ctx) throws IOException {
        Properties p = new Properties();
        try (InputStream in = ctx.getResourceAsStream("/WEB-INF/.env")) {
            if (in == null) {
                throw new FileNotFoundException("WEB-INF/.env not found");
            }
            p.load(in);
        }
        String user = URLEncoder.encode(p.getProperty("DB_USER", "").trim(), StandardCharsets.UTF_8);
        String pass = URLEncoder.encode(p.getProperty("DB_PASSWORD", "").trim(), StandardCharsets.UTF_8);
        return "jdbc:mysql://" + p.getProperty("DB_HOST", "localhost").trim()
             + ":" + p.getProperty("DB_PORT", "3306").trim()
             + "/" + p.getProperty("DB_NAME", "").trim()
             + "?user=" + user + "&password=" + pass + "&serverTimezone=UTC";
    }
}