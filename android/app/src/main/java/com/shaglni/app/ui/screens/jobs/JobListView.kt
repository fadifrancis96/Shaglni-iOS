package com.shaglni.app.ui.screens.jobs

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.shaglni.app.data.model.Job
import com.shaglni.app.ui.components.EmptyStateView
import com.shaglni.app.ui.components.FilterChip
import com.shaglni.app.ui.components.JobCardView
import com.shaglni.app.ui.localization.LocalizationManager

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun JobListView(
    onJobClick: (Job) -> Unit,
    onCreateJobClick: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: JobListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var searchQuery by remember { mutableStateOf("") }
    var selectedStatus by remember { mutableStateOf<String?>(null) }
    val keyboardController = LocalSoftwareKeyboardController.current

    LaunchedEffect(searchQuery, selectedStatus) {
        viewModel.searchJobs(searchQuery, selectedStatus)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(LocalizationManager.localized("jobs")) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = onCreateJobClick,
                containerColor = MaterialTheme.colorScheme.primary
            ) {
                Icon(Icons.Default.Add, contentDescription = "Create Job")
            }
        }
    ) { paddingValues ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Search Bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text(LocalizationManager.localized("search_jobs")) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = "Search") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(
                    onSearch = { keyboardController?.hide() }
                )
            )

            // Filter Chips
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    title = LocalizationManager.localized("all"),
                    isSelected = selectedStatus == null,
                    onClick = { selectedStatus = null }
                )
                
                FilterChip(
                    title = LocalizationManager.localized("open"),
                    isSelected = selectedStatus == "open",
                    onClick = { selectedStatus = "open" }
                )
                
                FilterChip(
                    title = LocalizationManager.localized("in_progress"),
                    isSelected = selectedStatus == "in_progress",
                    onClick = { selectedStatus = "in_progress" }
                )
                
                FilterChip(
                    title = LocalizationManager.localized("completed"),
                    isSelected = selectedStatus == "completed",
                    onClick = { selectedStatus = "completed" }
                )
            }

            // Jobs List
            when {
                uiState.isLoading -> {
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        CircularProgressIndicator()
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(LocalizationManager.localized("loading"))
                    }
                }
                
                uiState.jobs.isEmpty() -> {
                    EmptyStateView(
                        icon = "💼",
                        title = LocalizationManager.localized("no_jobs_found"),
                        subtitle = if (searchQuery.isNotBlank() || selectedStatus != null) {
                            LocalizationManager.localized("try_adjusting_search")
                        } else {
                            LocalizationManager.localized("be_first_to_post")
                        }
                    )
                }
                
                else -> {
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(uiState.jobs) { job ->
                            JobCardView(
                                job = job,
                                onClick = { onJobClick(job) }
                            )
                        }
                    }
                }
            }
        }
    }
}

data class JobListUiState(
    val jobs: List<Job> = emptyList(),
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)
