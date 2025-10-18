package com.shaglni.app.ui.screens.jobs

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseAuth
import com.shaglni.app.data.FirestoreService
import com.shaglni.app.data.model.Job
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class JobFormViewModel @Inject constructor(
    private val firestoreService: FirestoreService
) : ViewModel() {

    private val _uiState = MutableStateFlow(JobFormUiState())
    val uiState: StateFlow<JobFormUiState> = _uiState.asStateFlow()

    private val currentUser = FirebaseAuth.getInstance().currentUser

    fun loadJob(jobId: String) {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)

        viewModelScope.launch {
            try {
                val job = firestoreService.fetchJob(jobId)
                _uiState.value = _uiState.value.copy(
                    job = job,
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Could not load job: ${e.message}"
                )
            }
        }
    }

    fun createJob(job: Job) {
        val currentUser = FirebaseAuth.getInstance().currentUser
        if (currentUser == null) {
            _uiState.value = _uiState.value.copy(
                errorMessage = "You must be logged in to create a job"
            )
            return
        }

        _uiState.value = _uiState.value.copy(
            isSubmitting = true,
            errorMessage = null
        )

        viewModelScope.launch {
            try {
                val jobWithUser = job.copy(createdBy = currentUser.uid)
                firestoreService.createJob(jobWithUser)
                _uiState.value = _uiState.value.copy(
                    isSubmitting = false,
                    isSubmitted = true
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isSubmitting = false,
                    errorMessage = e.message ?: "Failed to create job"
                )
            }
        }
    }

    fun updateJob(job: Job) {
        _uiState.value = _uiState.value.copy(
            isSubmitting = true,
            errorMessage = null
        )

        viewModelScope.launch {
            try {
                firestoreService.updateJob(job)
                _uiState.value = _uiState.value.copy(
                    isSubmitting = false,
                    isSubmitted = true
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isSubmitting = false,
                    errorMessage = e.message ?: "Failed to update job"
                )
            }
        }
    }
}