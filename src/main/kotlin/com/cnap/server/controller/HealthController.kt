package com.cnap.server.controller

import com.cnap.server.model.dto.ApiResponse
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Profile
import org.springframework.http.ResponseEntity
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
    fun health(): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val healthData = mapOf(
            "status" to "UP",
            "application" to applicationName,
            "namespace" to namespace,
            "timestamp" to System.currentTimeMillis()
        )
        return ResponseEntity.ok(ApiResponse(result = healthData))
    }

    @GetMapping("/version")
    fun version(): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val versionData = mapOf(
            "application" to applicationName,
            "version" to (this::class.java.`package`?.implementationVersion ?: "dev"),
            "buildTime" to (this::class.java.`package`?.implementationTitle ?: "unknown")
        )
        return ResponseEntity.ok(ApiResponse(result = versionData))
    }
}
