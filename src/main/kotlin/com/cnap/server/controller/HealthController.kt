package com.cnap.server.controller

import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Profile
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@Profile("local")
class HealthController {

    @Value("\${spring.application.name}")
    private lateinit var applicationName: String

    @Value("\${cnap.kubernetes.namespace}")
    private lateinit var namespace: String

    @GetMapping("/healthz")
    fun health(): Map<String, Any> {
        return mapOf(
            "status" to "UP",
            "application" to applicationName,
            "namespace" to namespace,
            "timestamp" to System.currentTimeMillis()
        )
    }

    @GetMapping("/version")
    fun version(): Map<String, Any> {
        return mapOf(
            "application" to applicationName,
            "version" to (this::class.java.`package`?.implementationVersion ?: "dev"),
            "buildTime" to (this::class.java.`package`?.implementationTitle ?: "unknown")
        )
    }
}
