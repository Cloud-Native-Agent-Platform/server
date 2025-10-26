package com.cnap.server.config.properties

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "cnap.jwt")
data class JwtProperties(
    val secret: String,
    val accessTokenExpiration: Long,
    val refreshTokenExpiration: Long
)
