package com.cnap.server.config

import com.cnap.server.config.properties.CorsProperties
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.servlet.config.annotation.CorsRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer

@Configuration
@EnableConfigurationProperties(CorsProperties::class)
class WebConfig {

    @Bean
    fun webMvcConfigurer(corsProperties: CorsProperties): WebMvcConfigurer {
        return object : WebMvcConfigurer {
            override fun addCorsMappings(registry: CorsRegistry) {
                registry.addMapping("/**")
                    .allowedOrigins(*corsProperties.allowedOrigins.toTypedArray())
                    .allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS")
                    .allowedHeaders(*corsProperties.allowedHeaders.toTypedArray())
                    .allowCredentials(corsProperties.allowCredentials)
                    .maxAge(corsProperties.maxAge)
            }
        }
    }
}
