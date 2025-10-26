package com.cnap.server.exception

import jakarta.validation.ConstraintViolationException
import org.slf4j.LoggerFactory
import org.springframework.dao.DataAccessResourceFailureException
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.web.HttpRequestMethodNotSupportedException
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException
import org.springframework.web.servlet.resource.NoResourceFoundException

@RestControllerAdvice
class GlobalExceptionHandler {

    private val logger = LoggerFactory.getLogger(GlobalExceptionHandler::class.java)

    companion object {
        private const val VALIDATION_DEFAULT_ERROR_MESSAGE = "Unknown validation error"
        private const val INVALID_REQUEST_DELIMITER = ", "
    }

    @ExceptionHandler(BadRequestException::class)
    fun handleBadRequest(e: BadRequestException): ResponseEntity<ErrorResponse> {
        logger.error("BadRequestException: ${e.message}", e)
        return ResponseEntity.badRequest()
            .body(ErrorResponse.from(e))
    }

    @ExceptionHandler(NotFoundException::class)
    fun handleNotFound(e: NotFoundException): ResponseEntity<ErrorResponse> {
        logger.error("NotFoundException: ${e.message}", e)
        return ResponseEntity.status(e.status)
            .body(ErrorResponse.from(e))
    }

    @ExceptionHandler(UnauthorizedException::class)
    fun handleUnauthorized(e: UnauthorizedException): ResponseEntity<ErrorResponse> {
        logger.error("UnauthorizedException: ${e.message}", e)
        return ResponseEntity.status(e.status)
            .body(ErrorResponse.from(e))
    }

    @ExceptionHandler(ForbiddenException::class)
    fun handleForbidden(e: ForbiddenException): ResponseEntity<ErrorResponse> {
        logger.error("ForbiddenException: ${e.message}", e)
        return ResponseEntity.status(e.status)
            .body(ErrorResponse.from(e))
    }

    @ExceptionHandler(ConflictException::class)
    fun handleConflict(e: ConflictException): ResponseEntity<ErrorResponse> {
        logger.error("ConflictException: ${e.message}", e)
        return ResponseEntity.status(e.status)
            .body(ErrorResponse.from(e))
    }

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidException(bindingResult: MethodArgumentNotValidException): ResponseEntity<ErrorResponse> {
        val errorMessage = bindingResult.fieldErrors
            .map { it.defaultMessage ?: VALIDATION_DEFAULT_ERROR_MESSAGE }
            .joinToString(INVALID_REQUEST_DELIMITER) { "Invalid Input: [$it]" }
        logger.error("MethodArgumentNotValidException: $errorMessage")
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(
                ErrorResponse(
                    status = HttpStatus.BAD_REQUEST.value(),
                    message = errorMessage
                )
            )
    }

    @ExceptionHandler(ConstraintViolationException::class)
    fun handleValidateException(e: ConstraintViolationException): ResponseEntity<ErrorResponse> {
        logger.error("ConstraintViolationException: ${e.message}", e)
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(
                ErrorResponse(
                    status = HttpStatus.BAD_REQUEST.value(),
                    message = e.message ?: VALIDATION_DEFAULT_ERROR_MESSAGE
                )
            )
    }

    @ExceptionHandler(NoResourceFoundException::class)
    fun handleNoResourceFound(e: NoResourceFoundException): ResponseEntity<ErrorResponse> {
        logger.error("NoResourceFoundException: ${e.message}", e)
        return ResponseEntity.status(e.statusCode)
            .body(
                ErrorResponse(
                    status = e.statusCode.value(),
                    message = "Invalid path: /${e.resourcePath}"
                )
            )
    }

    @ExceptionHandler(DataIntegrityViolationException::class)
    fun handleDuplicateKey(e: DataIntegrityViolationException): ResponseEntity<ErrorResponse> {
        logger.error("DataIntegrityViolationException: ${e.message}", e)
        return ResponseEntity.status(HttpStatus.CONFLICT)
            .body(
                ErrorResponse(
                    status = HttpStatus.CONFLICT.value(),
                    message = "Data integrity violation: duplicate key or constraint violation"
                )
            )
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException::class)
    fun handleMethodNotAllowed(e: HttpRequestMethodNotSupportedException): ResponseEntity<ErrorResponse> {
        logger.error("HttpRequestMethodNotSupportedException: ${e.message}", e)
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED)
            .body(
                ErrorResponse(
                    status = HttpStatus.METHOD_NOT_ALLOWED.value(),
                    message = "Method not allowed: ${e.message}"
                )
            )
    }

    @ExceptionHandler(HttpMessageNotReadableException::class)
    fun handleHttpMessageNotReadable(e: HttpMessageNotReadableException): ResponseEntity<ErrorResponse> {
        logger.error("HttpMessageNotReadableException: ${e.message}", e)
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(
                ErrorResponse(
                    status = HttpStatus.BAD_REQUEST.value(),
                    message = "Invalid request body: ${e.message}"
                )
            )
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException::class)
    fun handleArgumentTypeMismatch(e: MethodArgumentTypeMismatchException): ResponseEntity<ErrorResponse> {
        logger.error("MethodArgumentTypeMismatchException: ${e.message}", e)
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
            .body(
                ErrorResponse(
                    status = HttpStatus.BAD_REQUEST.value(),
                    message = "Invalid argument type: ${e.message}"
                )
            )
    }

    @ExceptionHandler(DataAccessResourceFailureException::class)
    fun handleDataAccessFailure(e: DataAccessResourceFailureException): ResponseEntity<ErrorResponse> {
        logger.error("DataAccessResourceFailureException: ${e.message}", e)
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
            .body(
                ErrorResponse(
                    status = HttpStatus.SERVICE_UNAVAILABLE.value(),
                    message = "Database access failed: ${e.message}"
                )
            )
    }

    @ExceptionHandler(Exception::class)
    fun handleException(e: Exception): ResponseEntity<ErrorResponse> {
        logger.error("Unhandled Exception: ${e.message}", e)
        return ResponseEntity.internalServerError()
            .body(ErrorResponse.from(InternalServerError()))
    }
}
