package com.cnap.server.controller

import com.cnap.server.model.dto.ApiResponse
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Profile
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

@Tag(name = "Health", description = "Health check and version information APIs")
@RestController
@Profile("local")
class HealthController {

    @Value("\${spring.application.name}")
    private lateinit var applicationName: String

    @Value("\${cnap.kubernetes.namespace}")
    private lateinit var namespace: String

    @Operation(
        summary = "Health Check",
        description = "Returns the current health status of the application"
    )
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

    @Operation(
        summary = "Version Information",
        description = "Returns version and build information of the application"
    )
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
