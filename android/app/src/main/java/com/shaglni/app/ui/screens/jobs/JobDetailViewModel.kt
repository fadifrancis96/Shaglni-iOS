package com.shaglni.app.ui.screens.jobs

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseAuth
import com.shaglni.app.data.FirestoreService
import com.shaglni.app.data.model.Job
import com.shaglni.app.data.model.Offer
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class JobDetailViewModel @Inject constructor(
    private val firestoreService: FirestoreService
) : ViewModel() {

    private val _uiState = MutableStateFlow(JobDetailUiState())
    val uiState: StateFlow<JobDetailUiState> = _uiState.asStateFlow()

    fun loadOffers(jobId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingOffers = true, errorMessage = null)
            
            try {
                val offers = firestoreService.fetchOffersForJob(jobId)
                _uiState.value = _uiState.value.copy(
                    offers = offers,
                    isLoadingOffers = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoadingOffers = false,
                    errorMessage = e.message ?: "Failed to load offers"
                )
            }
        }
    }

    fun checkCanSubmitOffer(job: Job) {
        val currentUser = FirebaseAuth.getInstance().currentUser
        val isContractor = true // TODO: Get from auth state
        val isJobOpen = job.status.equals("open", ignoreCase = true)
        val isNotJobOwner = job.createdBy != currentUser?.uid
        
        _uiState.value = _uiState.value.copy(
            canSubmitOffer = isContractor && isJobOpen && isNotJobOwner
        )
    }
}
