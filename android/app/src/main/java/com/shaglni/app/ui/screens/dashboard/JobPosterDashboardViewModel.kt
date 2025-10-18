package com.shaglni.app.ui.screens.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseAuth
import com.shaglni.app.data.FirestoreService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class JobPosterDashboardViewModel @Inject constructor(
    private val firestoreService: FirestoreService
) : ViewModel() {

    private val _uiState = MutableStateFlow(JobPosterDashboardUiState())
    val uiState: StateFlow<JobPosterDashboardUiState> = _uiState.asStateFlow()

    init {
        val currentUser = FirebaseAuth.getInstance().currentUser
        if (currentUser != null) {
            // Start observing jobs in real-time
            viewModelScope.launch {
                firestoreService.observeJobsByUser(currentUser.uid).collect { jobs ->
                    // Calculate stats
                    val totalJobs = jobs.size
                    val openJobs = jobs.count { it.status.equals("open", ignoreCase = true) }
                    
                    // Get recent jobs (last 5)
                    val recentJobs = jobs.take(5)

                    _uiState.value = _uiState.value.copy(
                        totalJobs = totalJobs,
                        openJobs = openJobs,
                        recentJobs = recentJobs,
                        isLoading = false,
                        errorMessage = null
                    )
                }
            }
        }
    }

    fun loadDashboardData() {
        // Data is now loaded automatically via real-time updates
    }
}
