package com.cnap.server.exception

import org.springframework.http.HttpStatus

abstract class BaseException(
    val status: HttpStatus,
    override val message: String
) : RuntimeException(message)

open class InternalServerError(
    status: HttpStatus = HttpStatus.INTERNAL_SERVER_ERROR,
    message: String = "An unknown error occurred"
) : BaseException(status, message)

open class BadRequestException(
    status: HttpStatus = HttpStatus.BAD_REQUEST,
    message: String = "Invalid request"
) : BaseException(status, message)

open class NotFoundException(
    status: HttpStatus = HttpStatus.NOT_FOUND,
    message: String = "Resource not found"
) : BaseException(status, message)

open class UnauthorizedException(
    status: HttpStatus = HttpStatus.UNAUTHORIZED,
    message: String = "Unauthorized user"
) : BaseException(status, message)

open class ForbiddenException(
    status: HttpStatus = HttpStatus.FORBIDDEN,
    message: String = "Access denied"
) : BaseException(status, message)

open class ConflictException(
    status: HttpStatus = HttpStatus.CONFLICT,
    message: String = "Resource already exists"
) : BaseException(status, message)
