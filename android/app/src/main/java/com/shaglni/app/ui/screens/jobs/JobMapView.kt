package com.shaglni.app.ui.screens.jobs

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.LatLngBounds
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.MapProperties
import com.google.maps.android.compose.MapType
import com.google.maps.android.compose.MapUiSettings
import com.google.maps.android.compose.Marker
import com.google.maps.android.compose.MarkerState
import com.google.maps.android.compose.rememberCameraPositionState
import com.shaglni.app.data.model.Job
import com.shaglni.app.ui.components.EmptyStateView
import com.shaglni.app.ui.localization.LocalizationManager

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun JobMapView(
    onJobClick: (Job) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: JobMapViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var selectedJob by remember { mutableStateOf<Job?>(null) }
    var showJobDetails by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.loadJobs()
    }

    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(
            LatLng(31.7683, 35.2137), // Jerusalem coordinates as default
            10f
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(LocalizationManager.localized("jobsMap")) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { viewModel.centerOnUserLocation() },
                containerColor = MaterialTheme.colorScheme.primary
            ) {
                Icon(Icons.Default.MyLocation, contentDescription = "My Location")
            }
        }
    ) { paddingValues ->
        Box(
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                uiState.isLoading -> {
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        CircularProgressIndicator()
                        androidx.compose.foundation.layout.Spacer(modifier = Modifier.size(16.dp))
                        Text(LocalizationManager.localized("loading"))
                    }
                }

                uiState.jobs.isEmpty() -> {
                    EmptyStateView(
                        icon = "🗺️",
                        title = LocalizationManager.localized("noJobsOnMap"),
                        subtitle = LocalizationManager.localized("noJobsWithLocation")
                    )
                }

                else -> {
                    GoogleMap(
                        cameraPositionState = cameraPositionState,
                        properties = MapProperties(
                            mapType = MapType.NORMAL,
                            isMyLocationEnabled = true
                        ),
                        uiSettings = MapUiSettings(
                            myLocationButtonEnabled = false,
                            zoomControlsEnabled = true,
                            compassEnabled = true
                        ),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        uiState.jobs.forEach { job ->
                            if (job.latitude != null && job.longitude != null) {
                                Marker(
                                    state = MarkerState(
                                        position = LatLng(job.latitude!!, job.longitude!!)
                                    ),
                                    title = job.title,
                                    snippet = job.location,
                                    onClick = {
                                        selectedJob = job
                                        showJobDetails = true
                                        true
                                    }
                                )
                            }
                        }
                    }

                    // Job Details Card
                    if (showJobDetails && selectedJob != null) {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp)
                                .align(Alignment.BottomCenter),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                            elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = selectedJob!!.title,
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.Bold,
                                        modifier = Modifier.weight(1f)
                                    )
                                    
                                    IconButton(
                                        onClick = { showJobDetails = false }
                                    ) {
                                        Icon(
                                            Icons.Default.Close,
                                            contentDescription = "Close",
                                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }

                                Text(
                                    text = selectedJob!!.description,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    maxLines = 2
                                )

                                Row(
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        Icons.Default.LocationOn,
                                        contentDescription = "Location",
                                        modifier = Modifier.size(16.dp),
                                        tint = MaterialTheme.colorScheme.primary
                                    )
                                    androidx.compose.foundation.layout.Spacer(modifier = Modifier.size(4.dp))
                                    Text(
                                        text = selectedJob!!.location,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }

                                androidx.compose.material3.Button(
                                    onClick = {
                                        onJobClick(selectedJob!!)
                                        showJobDetails = false
                                    },
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text("View Details")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

data class JobMapUiState(
    val jobs: List<Job> = emptyList(),
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)
