package com.shaglni.app.ui.screens.jobs

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shaglni.app.data.FirestoreService
import com.shaglni.app.data.model.Job
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class JobListViewModel @Inject constructor(
    private val firestoreService: FirestoreService
) : ViewModel() {

    private val _uiState = MutableStateFlow(JobListUiState())
    val uiState: StateFlow<JobListUiState> = _uiState.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    private val _selectedStatus = MutableStateFlow<String?>(null)

    init {
        // Start observing jobs in real-time
        viewModelScope.launch {
            combine(
                firestoreService.observeJobs(),
                _searchQuery,
                _selectedStatus
            ) { jobs, query, status ->
                // Filter by search query
                val filteredJobs = if (query.isNotBlank()) {
                    jobs.filter { job ->
                        job.title.contains(query, ignoreCase = true) ||
                        job.description.contains(query, ignoreCase = true) ||
                        job.location.contains(query, ignoreCase = true)
                    }
                } else {
                    jobs
                }
                
                // Filter by status
                val finalJobs = if (status != null) {
                    filteredJobs.filter { it.status.equals(status, ignoreCase = true) }
                } else {
                    filteredJobs
                }
                
                _uiState.value = _uiState.value.copy(
                    jobs = finalJobs,
                    isLoading = false,
                    errorMessage = null
                )
            }.collect { }
        }
    }

    fun searchJobs(query: String, status: String?) {
        _searchQuery.value = query
        _selectedStatus.value = status
    }
}
