package com.shaglni.app.ui.screens.offers

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseAuth
import com.shaglni.app.data.FirestoreService
import com.shaglni.app.data.model.Offer
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OfferFormViewModel @Inject constructor(
    private val firestoreService: FirestoreService
) : ViewModel() {

    private val _uiState = MutableStateFlow(OfferFormUiState())
    val uiState: StateFlow<OfferFormUiState> = _uiState.asStateFlow()

    fun submitOffer(jobId: String, price: Double, message: String) {
        val currentUser = FirebaseAuth.getInstance().currentUser
        if (currentUser == null) {
            _uiState.value = _uiState.value.copy(
                errorMessage = "You must be logged in to submit an offer"
            )
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                isSubmitting = true,
                errorMessage = null
            )

            try {
                val offer = Offer(
                    jobId = jobId,
                    contractorId = currentUser.uid,
                    contractorName = currentUser.displayName ?: "Anonymous",
                    price = price,
                    message = message,
                    status = "pending",
                    createdAt = com.google.firebase.Timestamp.now()
                )
                
                firestoreService.submitOffer(offer, jobId)

                _uiState.value = _uiState.value.copy(
                    isSubmitting = false,
                    isSubmitted = true
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isSubmitting = false,
                    errorMessage = e.message ?: "Failed to submit offer"
                )
            }
        }
    }
}
