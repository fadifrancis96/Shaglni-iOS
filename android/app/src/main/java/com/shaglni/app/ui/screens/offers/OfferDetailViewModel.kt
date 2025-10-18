package com.shaglni.app.ui.screens.offers

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseAuth
import com.shaglni.app.data.FirestoreService
import com.shaglni.app.data.model.ContractorProfile
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OfferDetailViewModel @Inject constructor(
    private val firestoreService: FirestoreService
) : ViewModel() {

    private val _uiState = MutableStateFlow(OfferDetailUiState())
    val uiState: StateFlow<OfferDetailUiState> = _uiState.asStateFlow()

    private val currentUser = FirebaseAuth.getInstance().currentUser

    init {
        // Check if current user is job poster by looking at their role
        // This is a simplified check - in a real app you'd fetch user data
        _uiState.value = _uiState.value.copy(isJobPoster = true) // Placeholder
    }

    fun loadContractorProfile(contractorId: String) {
        _uiState.value = _uiState.value.copy(isLoading = true)

        viewModelScope.launch {
            try {
                val profile = firestoreService.fetchContractorProfile(contractorId)
                _uiState.value = _uiState.value.copy(
                    contractorProfile = profile,
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Could not load contractor profile: ${e.message}"
                )
            }
        }
    }

    fun acceptOffer(jobId: String, offerId: String) {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)

        viewModelScope.launch {
            try {
                firestoreService.updateOfferStatus(jobId, offerId, "accepted")
                _uiState.value = _uiState.value.copy(isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Failed to accept offer"
                )
            }
        }
    }

    fun rejectOffer(jobId: String, offerId: String) {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)

        viewModelScope.launch {
            try {
                firestoreService.updateOfferStatus(jobId, offerId, "rejected")
                _uiState.value = _uiState.value.copy(isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Failed to reject offer"
                )
            }
        }
    }

    fun sendCounterOffer(jobId: String, offerId: String, counterPrice: Double, message: String) {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)

        viewModelScope.launch {
            try {
                firestoreService.sendCounterOffer(jobId, offerId, counterPrice, message)
                _uiState.value = _uiState.value.copy(isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Failed to send counter offer"
                )
            }
        }
    }

    fun acceptCounterOffer(jobId: String, offerId: String) {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)

        viewModelScope.launch {
            try {
                firestoreService.respondToCounterOffer(jobId, offerId, true)
                _uiState.value = _uiState.value.copy(isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Failed to accept counter offer"
                )
            }
        }
    }

    fun declineCounterOffer(jobId: String, offerId: String) {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)

        viewModelScope.launch {
            try {
                firestoreService.respondToCounterOffer(jobId, offerId, false)
                _uiState.value = _uiState.value.copy(isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Failed to decline counter offer"
                )
            }
        }
    }
}
