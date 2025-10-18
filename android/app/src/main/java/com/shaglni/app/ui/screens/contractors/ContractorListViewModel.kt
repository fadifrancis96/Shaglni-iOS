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
class ContractorListViewModel @Inject constructor(
    private val firestoreService: FirestoreService
) : ViewModel() {

    private val _uiState = MutableStateFlow(ContractorListUiState())
    val uiState: StateFlow<ContractorListUiState> = _uiState.asStateFlow()

    fun searchContractors(query: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            
            try {
                val contractors = firestoreService.fetchAllContractors()
                
                val filteredContractors = if (query.isNotBlank()) {
                    contractors.filter { contractor ->
                        contractor.displayName.contains(query, ignoreCase = true) ||
                        contractor.bio.contains(query, ignoreCase = true) ||
                        contractor.skills.any { it.contains(query, ignoreCase = true) }
                    }
                } else {
                    contractors
                }

                _uiState.value = _uiState.value.copy(
                    contractors = filteredContractors,
                    isLoading = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Failed to load contractors"
                )
            }
        }
    }
}
