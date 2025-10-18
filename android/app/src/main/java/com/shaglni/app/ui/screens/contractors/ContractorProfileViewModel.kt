package com.shaglni.app.ui.screens.contractors

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shaglni.app.data.FirestoreService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ContractorProfileViewModel @Inject constructor(
    private val firestoreService: FirestoreService
) : ViewModel() {

    private val _uiState = MutableStateFlow(ContractorProfileUiState())
    val uiState: StateFlow<ContractorProfileUiState> = _uiState.asStateFlow()

    fun loadContractorProfile(contractorId: String) {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)

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
}