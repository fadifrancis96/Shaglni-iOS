package com.shaglni.app.ui.screens.jobs

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
// import com.google.android.gms.location.FusedLocationProviderClient
// import com.google.android.gms.location.LocationServices
import com.shaglni.app.data.FirestoreService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class JobMapViewModel @Inject constructor(
    private val firestoreService: FirestoreService
) : ViewModel() {

    private val _uiState = MutableStateFlow(JobMapUiState())
    val uiState: StateFlow<JobMapUiState> = _uiState.asStateFlow()

    fun loadJobs() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            
            try {
                val jobs = firestoreService.fetchJobs()
                // Filter jobs that have valid coordinates
                val jobsWithLocation = jobs.filter { 
                    it.latitude != null && it.longitude != null 
                }
                
                _uiState.value = _uiState.value.copy(
                    jobs = jobsWithLocation,
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Failed to load jobs"
                )
            }
        }
    }

    fun centerOnUserLocation() {
        // This would be implemented with proper location services
        // For now, we'll just reload jobs
        loadJobs()
    }
}
