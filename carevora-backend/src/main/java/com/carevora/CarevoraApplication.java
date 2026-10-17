package com.carevora;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootApplication
public class CarevoraApplication {

    public static void main(String[] args) {
        SpringApplication.run(CarevoraApplication.class, args);
    }

    @Bean
    public CommandLineRunner databaseCompatibilityFix(JdbcTemplate jdbcTemplate) {
        return args -> {
            try {
                jdbcTemplate.execute("ALTER TABLE assessments ALTER COLUMN social_score DROP NOT NULL");
            } catch (Exception ignored) {
            }
        };
    }
}
