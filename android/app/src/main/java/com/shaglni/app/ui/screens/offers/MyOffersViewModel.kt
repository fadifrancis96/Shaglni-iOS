package com.shaglni.app.ui.screens.offers

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
class MyOffersViewModel @Inject constructor(
    private val firestoreService: FirestoreService
) : ViewModel() {

    private val _uiState = MutableStateFlow(MyOffersUiState())
    val uiState: StateFlow<MyOffersUiState> = _uiState.asStateFlow()

    private val _statusFilter = MutableStateFlow<String?>(null)

    init {
        // Start observing offers in real-time
        val currentUser = FirebaseAuth.getInstance().currentUser
        if (currentUser != null) {
            viewModelScope.launch {
                combine(
                    firestoreService.observeOffersByContractor(currentUser.uid),
                    _statusFilter
                ) { offers, statusFilter ->
                    val filteredOffers = if (statusFilter != null) {
                        offers.filter { it.status.equals(statusFilter, ignoreCase = true) }
                    } else {
                        offers
                    }

                    _uiState.value = _uiState.value.copy(
                        offers = filteredOffers,
                        isLoading = false,
                        errorMessage = null
                    )
                }.collect { }
            }
        } else {
            _uiState.value = _uiState.value.copy(
                errorMessage = "You must be logged in to view offers"
            )
        }
    }

    fun loadOffers(statusFilter: String?) {
        _statusFilter.value = statusFilter
    }
}
