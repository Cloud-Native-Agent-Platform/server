package com.cnap.server.config.properties

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "cnap.cors")
data class CorsProperties(
    val allowedOrigins: List<String>,
    val allowedHeaders: List<String>,
    val allowCredentials: Boolean,
    val maxAge: Long
)
