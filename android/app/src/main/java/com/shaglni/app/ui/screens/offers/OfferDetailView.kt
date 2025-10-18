package com.shaglni.app.ui.screens.offers

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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.shaglni.app.data.model.ContractorProfile
import com.shaglni.app.data.model.Offer
import com.shaglni.app.ui.components.StatusBadge
import com.shaglni.app.ui.localization.LocalizationManager
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OfferDetailView(
    offer: Offer,
    jobId: String,
    onBackClick: () -> Unit,
    onContractorProfileClick: (ContractorProfile) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: OfferDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showAcceptConfirmation by remember { mutableStateOf(false) }
    var showRejectConfirmation by remember { mutableStateOf(false) }
    var showNegotiation by remember { mutableStateOf(false) }
    var showAcceptCounterConfirmation by remember { mutableStateOf(false) }
    var showDeclineCounterConfirmation by remember { mutableStateOf(false) }

    LaunchedEffect(offer.id) {
        viewModel.loadContractorProfile(offer.contractorId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(LocalizationManager.localized("offer_details")) },
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
            // Status Badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                StatusBadge(status = offer.status)
            }

            // Offer Details Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = LocalizationManager.localized("offer_details"),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    // Price Section
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = LocalizationManager.localized("offered_price"),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = "₪${String.format("%.0f", offer.price)}",
                                style = MaterialTheme.typography.headlineMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }

                        // Counter Offer Price
                        offer.counterPrice?.let { counterPrice ->
                            Column(horizontalAlignment = Alignment.End) {
                                Text(
                                    text = LocalizationManager.localized("counter_offer"),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Text(
                                    text = "₪${String.format("%.0f", counterPrice)}",
                                    style = MaterialTheme.typography.titleLarge,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.secondary
                                )
                            }
                        }
                    }

                    Divider()

                    // Message
                    Column {
                        Text(
                            text = LocalizationManager.localized("message"),
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = offer.message,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    // Negotiation Message
                    offer.negotiationMessage?.let { negotiationMsg ->
                        Divider()
                        Column {
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.SwapHoriz,
                                    contentDescription = "Negotiation",
                                    tint = MaterialTheme.colorScheme.secondary,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = LocalizationManager.localized("negotiation_note"),
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.secondary
                                )
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = negotiationMsg,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    Divider()

                    // Dates
                    Column {
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.CheckCircle,
                                contentDescription = "Submitted",
                                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "${LocalizationManager.localized("submitted")}: ${formatDate(offer.createdAt?.toDate())}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }

                        offer.respondedAt?.let { respondedAt ->
                            Spacer(modifier = Modifier.height(4.dp))
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.CheckCircle,
                                    contentDescription = "Responded",
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = "${LocalizationManager.localized("responded")}: ${formatDate(respondedAt.toDate())}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
            }

            // Contractor Info Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = LocalizationManager.localized("contractor"),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Button(
                        onClick = { 
                            uiState.contractorProfile?.let { onContractorProfileClick(it) }
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color.Transparent,
                            contentColor = MaterialTheme.colorScheme.onSurface
                        )
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Profile Picture
                            Box(
                                modifier = Modifier
                                    .size(50.dp)
                                    .clip(CircleShape),
                                contentAlignment = Alignment.Center
                            ) {
                                Box(
                                    modifier = Modifier
                                        .fillMaxSize()
                                        .clip(CircleShape),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        Icons.Default.Person,
                                        contentDescription = "Profile",
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(24.dp)
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.width(12.dp))

                            Column(
                                modifier = Modifier.weight(1f)
                            ) {
                                Text(
                                    text = offer.contractorName,
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )

                                uiState.contractorProfile?.let { profile ->
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        profile.rating?.let { rating ->
                                            Icon(
                                                Icons.Default.CheckCircle,
                                                contentDescription = "Rating",
                                                tint = MaterialTheme.colorScheme.secondary,
                                                modifier = Modifier.size(12.dp)
                                            )
                                            Spacer(modifier = Modifier.width(2.dp))
                                            Text(
                                                text = String.format("%.1f", rating),
                                                style = MaterialTheme.typography.bodySmall
                                            )
                                        }
                                        Text(
                                            text = "• ${profile.completedJobsCount} ${LocalizationManager.localized("jobs")}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                } ?: run {
                                    Text(
                                        text = LocalizationManager.localized("tap_to_view_profile"),
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }

                            Icon(
                                Icons.Default.ArrowBack,
                                contentDescription = "View Profile",
                                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
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

            // Action Buttons
            when {
                uiState.isJobPoster && offer.status == "pending" -> {
                    // Job Poster Actions for Pending Offers
                    Column(
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Accept Button
                        Button(
                            onClick = { showAcceptConfirmation = true },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.primary
                            )
                        ) {
                            Icon(Icons.Default.CheckCircle, contentDescription = "Accept")
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = LocalizationManager.localized("accept_offer"),
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        // Negotiate Button
                        Button(
                            onClick = { showNegotiation = true },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.secondary
                            )
                        ) {
                            Icon(Icons.Default.SwapHoriz, contentDescription = "Negotiate")
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = LocalizationManager.localized("negotiate_price"),
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        // Reject Button
                        Button(
                            onClick = { showRejectConfirmation = true },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.errorContainer,
                                contentColor = MaterialTheme.colorScheme.onErrorContainer
                            )
                        ) {
                            Icon(Icons.Default.Close, contentDescription = "Reject")
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = LocalizationManager.localized("decline_offer"),
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }

                !uiState.isJobPoster && offer.status == "counter_offer" -> {
                    // Contractor Actions for Counter Offers
                    Column(
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Counter Offer Info
                        Card(
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Text(
                                    text = LocalizationManager.localized("counter_offer_received"),
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.secondary
                                )

                                offer.counterPrice?.let { counterPrice ->
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween
                                    ) {
                                        Text(
                                            text = "${LocalizationManager.localized("job_poster_price")}:",
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                        Text(
                                            text = "₪${String.format("%.0f", counterPrice)}",
                                            style = MaterialTheme.typography.titleLarge,
                                            fontWeight = FontWeight.Bold,
                                            color = MaterialTheme.colorScheme.secondary
                                        )
                                    }
                                }

                                offer.negotiationMessage?.let { negotiationMsg ->
                                    Text(
                                        text = negotiationMsg,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }

                        // Accept Counter Offer Button
                        Button(
                            onClick = { showAcceptCounterConfirmation = true },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.primary
                            )
                        ) {
                            Icon(Icons.Default.CheckCircle, contentDescription = "Accept")
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = LocalizationManager.localized("accept_counter_offer"),
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        // Decline Counter Offer Button
                        Button(
                            onClick = { showDeclineCounterConfirmation = true },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.errorContainer,
                                contentColor = MaterialTheme.colorScheme.onErrorContainer
                            )
                        ) {
                            Icon(Icons.Default.Close, contentDescription = "Decline")
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = LocalizationManager.localized("decline_counter_offer"),
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }
        }
    }

    // Confirmation Dialogs
    if (showAcceptConfirmation) {
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { showAcceptConfirmation = false },
            title = { Text(LocalizationManager.localized("accept_offer")) },
            text = { Text("${LocalizationManager.localized("accept_offer_confirmation")} ₪${String.format("%.0f", offer.price)}?") },
            confirmButton = {
                Button(
                    onClick = {
                        showAcceptConfirmation = false
                        viewModel.acceptOffer(jobId, offer.id ?: "")
                    }
                ) {
                    Text(LocalizationManager.localized("accept"))
                }
            },
            dismissButton = {
                Button(onClick = { showAcceptConfirmation = false }) {
                    Text(LocalizationManager.localized("cancel"))
                }
            }
        )
    }

    if (showRejectConfirmation) {
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { showRejectConfirmation = false },
            title = { Text(LocalizationManager.localized("decline_offer")) },
            text = { Text(LocalizationManager.localized("decline_offer_confirmation")) },
            confirmButton = {
                Button(
                    onClick = {
                        showRejectConfirmation = false
                        viewModel.rejectOffer(jobId, offer.id ?: "")
                    }
                ) {
                    Text(LocalizationManager.localized("decline"))
                }
            },
            dismissButton = {
                Button(onClick = { showRejectConfirmation = false }) {
                    Text(LocalizationManager.localized("cancel"))
                }
            }
        )
    }

    if (showAcceptCounterConfirmation) {
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { showAcceptCounterConfirmation = false },
            title = { Text(LocalizationManager.localized("accept_counter_offer")) },
            text = { 
                offer.counterPrice?.let { counterPrice ->
                    Text("${LocalizationManager.localized("accept_counter_offer_confirmation")} ₪${String.format("%.0f", counterPrice)}?")
                } ?: Text(LocalizationManager.localized("accept_counter_offer_confirmation"))
            },
            confirmButton = {
                Button(
                    onClick = {
                        showAcceptCounterConfirmation = false
                        viewModel.acceptCounterOffer(jobId, offer.id ?: "")
                    }
                ) {
                    Text(LocalizationManager.localized("accept"))
                }
            },
            dismissButton = {
                Button(onClick = { showAcceptCounterConfirmation = false }) {
                    Text(LocalizationManager.localized("cancel"))
                }
            }
        )
    }

    if (showDeclineCounterConfirmation) {
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { showDeclineCounterConfirmation = false },
            title = { Text(LocalizationManager.localized("decline_counter_offer")) },
            text = { Text(LocalizationManager.localized("decline_counter_offer_confirmation")) },
            confirmButton = {
                Button(
                    onClick = {
                        showDeclineCounterConfirmation = false
                        viewModel.declineCounterOffer(jobId, offer.id ?: "")
                    }
                ) {
                    Text(LocalizationManager.localized("decline"))
                }
            },
            dismissButton = {
                Button(onClick = { showDeclineCounterConfirmation = false }) {
                    Text(LocalizationManager.localized("cancel"))
                }
            }
        )
    }

    // Negotiation Sheet
    if (showNegotiation) {
        NegotiationSheet(
            offer = offer,
            onDismiss = { showNegotiation = false },
            onSubmit = { counterPrice, message ->
                showNegotiation = false
                viewModel.sendCounterOffer(jobId, offer.id ?: "", counterPrice, message)
            }
        )
    }

    // Loading Overlay
    if (uiState.isLoading) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun NegotiationSheet(
    offer: Offer,
    onDismiss: () -> Unit,
    onSubmit: (Double, String) -> Unit
) {
    var counterPrice by remember { mutableStateOf("") }
    var negotiationMessage by remember { mutableStateOf("") }

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
                text = LocalizationManager.localized("negotiate_price"),
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )

            OutlinedTextField(
                value = counterPrice,
                onValueChange = { counterPrice = it },
                label = { Text(LocalizationManager.localized("your_price")) },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            OutlinedTextField(
                value = negotiationMessage,
                onValueChange = { negotiationMessage = it },
                label = { Text(LocalizationManager.localized("explain_counter_offer")) },
                modifier = Modifier.fillMaxWidth(),
                minLines = 3,
                maxLines = 5
            )

            Text(
                text = "${LocalizationManager.localized("original_price")}: ₪${String.format("%.0f", offer.price)}",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = onDismiss,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Text(LocalizationManager.localized("cancel"))
                }

                Button(
                    onClick = {
                        val price = counterPrice.toDoubleOrNull() ?: 0.0
                        onSubmit(price, negotiationMessage)
                    },
                    modifier = Modifier.weight(1f),
                    enabled = counterPrice.isNotBlank() && negotiationMessage.isNotBlank()
                ) {
                    Text(LocalizationManager.localized("send"))
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
        days == 0L -> LocalizationManager.localized("today")
        days == 1L -> LocalizationManager.localized("yesterday")
        days < 7L -> "$days ${LocalizationManager.localized("days_ago")}"
        else -> SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()).format(date)
    }
}

data class OfferDetailUiState(
    val contractorProfile: ContractorProfile? = null,
    val isLoading: Boolean = false,
    val isJobPoster: Boolean = false,
    val errorMessage: String? = null
)
