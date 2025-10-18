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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.shaglni.app.data.model.Job
import com.shaglni.app.ui.localization.LocalizationManager

enum class JobCategory(val displayName: String) {
    PLUMBING("Plumbing"),
    ELECTRICAL("Electrical"),
    CARPENTRY("Carpentry"),
    PAINTING("Painting"),
    CLEANING("Cleaning"),
    LANDSCAPING("Landscaping"),
    HVAC("HVAC"),
    ROOFING("Roofing"),
    FLOORING("Flooring"),
    MASONRY("Masonry"),
    WELDING("Welding"),
    AUTOMOTIVE("Automotive"),
    APPLIANCE("Appliance Repair"),
    PEST("Pest Control"),
    MOVING("Moving"),
    OTHER("Other")
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun JobFormView(
    jobId: String? = null, // If provided, we're editing an existing job
    onJobSubmitted: () -> Unit,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: JobFormViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var selectedLocation by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf<JobCategory?>(null) }
    var budget by remember { mutableStateOf("") }
    var showLocationPicker by remember { mutableStateOf(false) }
    var showCategoryDropdown by remember { mutableStateOf(false) }

    // Load existing job data if editing
    LaunchedEffect(jobId) {
        jobId?.let { 
            viewModel.loadJob(it)
        }
    }

    // Update form fields when job is loaded
    LaunchedEffect(uiState.job) {
        uiState.job?.let { job ->
            title = job.title
            description = job.description
            selectedLocation = job.location
            selectedCategory = JobCategory.values().find { it.name == job.category }
            budget = job.budget?.toString() ?: ""
        }
    }

    // Navigate back when job is submitted
    LaunchedEffect(uiState.isSubmitted) {
        if (uiState.isSubmitted) {
            onJobSubmitted()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        if (jobId != null) LocalizationManager.localized("edit_job") 
                        else LocalizationManager.localized("post_job")
                    ) 
                },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
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
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Job Details Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = LocalizationManager.localized("job_details"),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
                    )

                    // Title Field
                    OutlinedTextField(
                        value = title,
                        onValueChange = { title = it },
                        label = { Text(LocalizationManager.localized("title")) },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next)
                    )

                    // Description Field
                    OutlinedTextField(
                        value = description,
                        onValueChange = { description = it },
                        label = { Text(LocalizationManager.localized("description")) },
                        modifier = Modifier.fillMaxWidth(),
                        minLines = 3,
                        maxLines = 5,
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done)
                    )

                    // Location Picker
                    Button(
                        onClick = { showLocationPicker = true },
                        modifier = Modifier.fillMaxWidth(),
                        colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant,
                            contentColor = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    ) {
                        Icon(
                            Icons.Default.LocationOn,
                            contentDescription = "Location",
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = if (selectedLocation.isEmpty()) {
                                LocalizationManager.localized("select_location")
                            } else {
                                selectedLocation
                            }
                        )
                    }

                    // Category Dropdown
                    ExposedDropdownMenuBox(
                        expanded = showCategoryDropdown,
                        onExpandedChange = { showCategoryDropdown = !showCategoryDropdown }
                    ) {
                        OutlinedTextField(
                            value = selectedCategory?.displayName ?: "",
                            onValueChange = { },
                            readOnly = true,
                            label = { Text(LocalizationManager.localized("category")) },
                            trailingIcon = {
                                ExposedDropdownMenuDefaults.TrailingIcon(expanded = showCategoryDropdown)
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .menuAnchor()
                        )
                        
                        ExposedDropdownMenu(
                            expanded = showCategoryDropdown,
                            onDismissRequest = { showCategoryDropdown = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text(LocalizationManager.localized("select_category")) },
                                onClick = {
                                    selectedCategory = null
                                    showCategoryDropdown = false
                                }
                            )
                            JobCategory.values().forEach { category ->
                                DropdownMenuItem(
                                    text = { Text(category.displayName) },
                                    onClick = {
                                        selectedCategory = category
                                        showCategoryDropdown = false
                                    }
                                )
                            }
                        }
                    }

                    // Budget Field
                    OutlinedTextField(
                        value = budget,
                        onValueChange = { budget = it },
                        label = { Text("${LocalizationManager.localized("budget")} (${LocalizationManager.localized("optional")})") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Number,
                            imeAction = ImeAction.Done
                        )
                    )
                }
            }

            // Error Message
            uiState.errorMessage?.let { errorMessage ->
                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = errorMessage,
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.padding(12.dp)
                    )
                }
            }

            // Submit Button
            Button(
                onClick = {
                    val budgetValue = budget.toDoubleOrNull()
                    val job = Job(
                        id = jobId ?: "",
                        title = title,
                        description = description,
                        location = selectedLocation,
                        latitude = null, // TODO: Get from location picker
                        longitude = null, // TODO: Get from location picker
                        datePosted = com.google.firebase.Timestamp.now(),
                        createdBy = "", // TODO: Get from auth
                        status = "open",
                        category = selectedCategory?.name,
                        budget = budgetValue
                    )
                    
                    if (jobId != null) {
                        viewModel.updateJob(job)
                    } else {
                        viewModel.createJob(job)
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = !uiState.isSubmitting && title.isNotBlank() && description.isNotBlank() && selectedLocation.isNotBlank()
            ) {
                if (uiState.isSubmitting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Text(
                    text = if (jobId != null) LocalizationManager.localized("update_job") else LocalizationManager.localized("post_job"),
                    fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold
                )
            }
        }
    }

    // Location Picker Sheet
    if (showLocationPicker) {
        LocationPickerSheet(
            onLocationSelected = { location ->
                selectedLocation = location
                showLocationPicker = false
            },
            onDismiss = { showLocationPicker = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun LocationPickerSheet(
    onLocationSelected: (String) -> Unit,
    onDismiss: () -> Unit
) {
    var searchText by remember { mutableStateOf("") }
    var selectedLocation by remember { mutableStateOf("") }

    androidx.compose.material3.ModalBottomSheet(
        onDismissRequest = onDismiss
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = LocalizationManager.localized("select_location"),
                style = MaterialTheme.typography.titleLarge,
                fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
            )

            OutlinedTextField(
                value = searchText,
                onValueChange = { searchText = it },
                label = { Text(LocalizationManager.localized("search_location")) },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            // Location suggestions (simplified for now)
            androidx.compose.foundation.lazy.LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(5) { index ->
                    val location = "Location ${index + 1}"
                    Card(
                        onClick = { 
                            selectedLocation = location
                            onLocationSelected(location)
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.LocationOn,
                                contentDescription = "Location",
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = location,
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                    }
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.weight(1f),
                    colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Text(LocalizationManager.localized("cancel"))
                }

                Button(
                    onClick = {
                        if (selectedLocation.isNotBlank()) {
                            onLocationSelected(selectedLocation)
                        }
                    },
                    modifier = Modifier.weight(1f),
                    enabled = selectedLocation.isNotBlank()
                ) {
                    Text(LocalizationManager.localized("select"))
                }
            }
        }
    }
}

data class JobFormUiState(
    val job: Job? = null,
    val isSubmitting: Boolean = false,
    val isSubmitted: Boolean = false,
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)