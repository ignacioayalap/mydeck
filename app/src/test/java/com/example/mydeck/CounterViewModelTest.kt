package com.example.mydeck

import com.example.mydeck.ui.CounterViewModel
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class CounterViewModelTest {

    private lateinit var viewModel: CounterViewModel

    @Before
    fun setup() {
        viewModel = CounterViewModel()
    }

    @Test
    fun initialState_isZero() {
        assertEquals(0, viewModel.uiState.value.counter)
    }

    @Test
    fun incrementCounter_increasesByOne() {
        viewModel.incrementCounter()
        assertEquals(1, viewModel.uiState.value.counter)
        viewModel.incrementCounter()
        assertEquals(2, viewModel.uiState.value.counter)
    }

    @Test
    fun decrementCounter_decreasesByOne() {
        viewModel.incrementCounter()
        viewModel.incrementCounter()
        viewModel.decrementCounter()
        assertEquals(1, viewModel.uiState.value.counter)
    }

    @Test
    fun resetCounter_resetsToZero() {
        viewModel.incrementCounter()
        viewModel.incrementCounter()
        viewModel.resetCounter()
        assertEquals(0, viewModel.uiState.value.counter)
    }
}
