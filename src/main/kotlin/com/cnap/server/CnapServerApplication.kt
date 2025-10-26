package com.cnap.server

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class CnapServerApplication

fun main(args: Array<String>) {
    runApplication<CnapServerApplication>(*args)
}
