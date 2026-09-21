package com.example.mydeck.ui

import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

data class CounterUiState(
    val counter: Int = 0
)

class CounterViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(CounterUiState())
    val uiState: StateFlow<CounterUiState> = _uiState.asStateFlow()

    fun incrementCounter() {
        _uiState.update { it.copy(counter = it.counter + 1) }
    }

    fun decrementCounter() {
        _uiState.update { it.copy(counter = maxOf(0, it.counter - 1)) }
    }

    fun resetCounter() {
        _uiState.update { it.copy(counter = 0) }
    }
}
