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
class ContractorDashboardViewModel @Inject constructor(
    private val firestoreService: FirestoreService
) : ViewModel() {

    private val _uiState = MutableStateFlow(ContractorDashboardUiState())
    val uiState: StateFlow<ContractorDashboardUiState> = _uiState.asStateFlow()

    init {
        val currentUser = FirebaseAuth.getInstance().currentUser
        if (currentUser != null) {
            // Load completed jobs count once
            viewModelScope.launch {
                try {
                    val completedJobs = firestoreService.fetchCompletedJobs(currentUser.uid)
                    _uiState.value = _uiState.value.copy(completedJobs = completedJobs.size)
                } catch (e: Exception) {
                    _uiState.value = _uiState.value.copy(completedJobs = 0)
                }
            }
            
            // Start observing offers in real-time
            viewModelScope.launch {
                firestoreService.observeOffersByContractor(currentUser.uid).collect { offers ->
                    // Calculate stats
                    val totalOffers = offers.size
                    val acceptedOffers = offers.count { it.status.equals("accepted", ignoreCase = true) }
                    val pendingOffers = offers.count { it.status.equals("pending", ignoreCase = true) }
                    
                    // Get recent offers (last 5)
                    val recentOffers = offers.take(5)

                    _uiState.value = _uiState.value.copy(
                        totalOffers = totalOffers,
                        acceptedOffers = acceptedOffers,
                        pendingOffers = pendingOffers,
                        recentOffers = recentOffers,
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
