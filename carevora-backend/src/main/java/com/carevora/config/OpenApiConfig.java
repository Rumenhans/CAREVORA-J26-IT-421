package com.carevora.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI carevoraOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("CAREVORA Emotional Wellness API")
                        .description("Backend REST API services for Elderly Emotional Wellness Monitoring Platform (Flutter Mobile & Caregiver Web Dashboard)")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("CAREVORA Engineering Team")
                                .email("support@carevora.com")))
                .addSecurityItem(new SecurityRequirement().addList("Bearer Authentication"))
                .components(new Components().addSecuritySchemes("Bearer Authentication", createSecurityScheme()));
    }

    private SecurityScheme createSecurityScheme() {
        return new SecurityScheme()
                .type(SecurityScheme.Type.HTTP)
                .bearerFormat("JWT")
                .scheme("bearer");
    }
}
