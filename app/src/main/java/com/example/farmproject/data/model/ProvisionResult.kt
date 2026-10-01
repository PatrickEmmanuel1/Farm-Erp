package com.example.farmproject.data.model

sealed interface ProvisionResult<out T> {
    data class Success<T>(val data: T) : ProvisionResult<T>
    data class Failure(val message: String) : ProvisionResult<Nothing>
}
