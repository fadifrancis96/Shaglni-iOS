package com.shaglni.app.ui.screens.jobs

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.foundation.layout.width
import androidx.compose.material3.IconButton
import androidx.compose.material3.ExperimentalMaterial3Api
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.MapProperties
import com.google.maps.android.compose.MapType
import com.google.maps.android.compose.MapUiSettings
import com.google.maps.android.compose.Marker
import com.google.maps.android.compose.MarkerState
import com.google.maps.android.compose.rememberCameraPositionState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.shaglni.app.data.model.Job
import com.shaglni.app.data.model.Offer
import com.shaglni.app.ui.components.EmptyStateView
import com.shaglni.app.ui.components.OfferCardView
import com.shaglni.app.ui.components.StatusBadge
import com.shaglni.app.ui.localization.LocalizationManager
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun JobDetailView(
    job: Job,
    onOfferClick: (Offer) -> Unit,
    onSubmitOfferClick: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: JobDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showSubmitOffer by remember { mutableStateOf(false) }
    var showMap by remember { mutableStateOf(false) }

    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(
            LatLng(job.latitude ?: 31.7683, job.longitude ?: 35.2137),
            15f
        )
    }

    LaunchedEffect(job.id) {
        job.id?.let { viewModel.loadOffers(it) }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Job Details") },
                actions = {
                    if (job.latitude != null && job.longitude != null) {
                        IconButton(onClick = { showMap = !showMap }) {
                            Icon(
                                Icons.Default.Map,
                                contentDescription = LocalizationManager.localized("showMap")
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        },
        bottomBar = {
            if (uiState.canSubmitOffer) {
                Button(
                    onClick = onSubmitOfferClick,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text("Submit Offer")
                }
            }
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Job Header
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Title and Status
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.Top
                        ) {
                            Text(
                                text = job.title,
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.weight(1f)
                            )
                            
                            StatusBadge(status = job.status)
                        }
                        
                        // Description
                        Text(
                            text = job.description,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        
                        Divider()
                        
                        // Job Details
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            // Location
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.LocationOn,
                                    contentDescription = "Location",
                                    tint = MaterialTheme.colorScheme.primary
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = job.location,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                            
                            // Date Posted
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.Schedule,
                                    contentDescription = "Date",
                                    tint = MaterialTheme.colorScheme.primary
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = formatDate(job.datePosted?.toDate()),
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                        }
                        
                        // Posted By
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.Person,
                                contentDescription = "Posted by",
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "Posted by: ${job.createdBy}",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
            
            // Map Section (if enabled)
            if (showMap && job.latitude != null && job.longitude != null) {
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(200.dp)
                        ) {
                            GoogleMap(
                                cameraPositionState = cameraPositionState,
                                properties = MapProperties(
                                    mapType = MapType.NORMAL
                                ),
                                uiSettings = MapUiSettings(
                                    zoomControlsEnabled = true,
                                    compassEnabled = true
                                ),
                                modifier = Modifier.fillMaxSize()
                            ) {
                                Marker(
                                    state = MarkerState(
                                        position = LatLng(job.latitude!!, job.longitude!!)
                                    ),
                                    title = job.title,
                                    snippet = job.location
                                )
                            }
                        }
                    }
                }
            }

            // Offers Section
            item {
                Text(
                    text = "Offers (${uiState.offers.size})",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            
            // Offers List
            if (uiState.isLoadingOffers) {
                item {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        CircularProgressIndicator()
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("Loading offers...")
                    }
                }
            } else if (uiState.offers.isEmpty()) {
                item {
                    EmptyStateView(
                        icon = "💼",
                        title = "No offers yet",
                        subtitle = "Be the first to submit an offer for this job"
                    )
                }
            } else {
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

private fun formatDate(date: Date?): String {
    if (date == null) return "Unknown"
    
    val now = Date()
    val diff = now.time - date.time
    val days = diff / (24 * 60 * 60 * 1000)
    
    return when {
        days == 0L -> "Today"
        days == 1L -> "Yesterday"
        days < 7L -> "$days days ago"
        else -> SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()).format(date)
    }
}

data class JobDetailUiState(
    val offers: List<Offer> = emptyList(),
    val isLoadingOffers: Boolean = false,
    val canSubmitOffer: Boolean = false,
    val errorMessage: String? = null
)
