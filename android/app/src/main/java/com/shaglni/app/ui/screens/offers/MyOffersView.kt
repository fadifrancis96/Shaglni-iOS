package com.shaglni.app.ui.screens.offers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.shaglni.app.data.model.Offer
import com.shaglni.app.ui.components.EmptyStateView
import com.shaglni.app.ui.components.FilterChip
import com.shaglni.app.ui.components.OfferCardView

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MyOffersView(
    onOfferClick: (Offer) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: MyOffersViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var selectedFilter by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(selectedFilter) {
        viewModel.loadOffers(selectedFilter)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("My Offers") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Filter Chips
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    title = "All",
                    isSelected = selectedFilter == null,
                    onClick = { selectedFilter = null }
                )
                
                FilterChip(
                    title = "Pending",
                    isSelected = selectedFilter == "pending",
                    onClick = { selectedFilter = "pending" }
                )
                
                FilterChip(
                    title = "Accepted",
                    isSelected = selectedFilter == "accepted",
                    onClick = { selectedFilter = "accepted" }
                )
                
                FilterChip(
                    title = "Rejected",
                    isSelected = selectedFilter == "rejected",
                    onClick = { selectedFilter = "rejected" }
                )
                
                FilterChip(
                    title = "Counter Offer",
                    isSelected = selectedFilter == "counter_offer",
                    onClick = { selectedFilter = "counter_offer" }
                )
            }

            // Offers List
            when {
                uiState.isLoading -> {
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        CircularProgressIndicator()
                        Spacer(modifier = Modifier.height(16.dp))
                        Text("Loading offers...")
                    }
                }
                
                uiState.offers.isEmpty() -> {
                    EmptyStateView(
                        icon = "📝",
                        title = "No offers found",
                        subtitle = if (selectedFilter != null) {
                            "Try adjusting your filter"
                        } else {
                            "Submit offers to jobs you're interested in"
                        }
                    )
                }
                
                else -> {
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(uiState.offers) { offer ->
                            OfferCardView(
                                offer = offer,
                                onClick = { onOfferClick(offer) }
                            )
                        }
                    }
                }
            }
        }
    }
}

data class MyOffersUiState(
    val offers: List<Offer> = emptyList(),
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)
