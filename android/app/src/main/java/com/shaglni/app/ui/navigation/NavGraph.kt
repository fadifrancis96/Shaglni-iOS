package com.shaglni.app.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.shaglni.app.ui.screens.*
import com.shaglni.app.ui.screens.dashboard.*
import com.shaglni.app.ui.screens.jobs.*
import com.shaglni.app.ui.screens.offers.*
import com.shaglni.app.ui.screens.profile.*
import com.shaglni.app.ui.screens.contractors.*
import com.shaglni.app.ui.auth.AuthViewModel
import com.shaglni.app.ui.localization.LocalizationManager

sealed class Screen(val route: String, val labelKey: String, val icon: ImageVector) {
    data object Dashboard : Screen("dashboard", "dashboard", Icons.Filled.Home)
    data object Jobs : Screen("jobs", "jobs", Icons.Filled.Work)
    data object Map : Screen("map", "map", Icons.Filled.Map)
    data object Contractors : Screen("contractors", "contractors", Icons.Filled.Group)
    data object MyOffers : Screen("my_offers", "my_offers", Icons.Filled.Description)
    data object Profile : Screen("profile", "profile", Icons.Filled.AccountCircle)
    
    // Detail screens
    data object JobDetail : Screen("job_detail/{jobId}", "job_details", Icons.Filled.Work)
    data object JobForm : Screen("job_form/{jobId}", "create_job", Icons.Filled.Work)
    data object OfferDetail : Screen("offer_detail/{jobId}/{offerId}", "offer_details", Icons.Filled.Description)
    data object OfferForm : Screen("offer_form/{jobId}", "submit_offer", Icons.Filled.Description)
    data object ContractorProfile : Screen("contractor_profile/{contractorId}", "contractor_profile", Icons.Filled.Group)
    
    fun getLabel(): String = LocalizationManager.localized(labelKey)
}

@Composable
fun ShaglniRootNavigation(
    isJobPoster: Boolean,
    isContractor: Boolean
) {
    val navController = rememberNavController()
    val authViewModel: AuthViewModel = hiltViewModel()
    val tabs = buildList {
        add(Screen.Dashboard)
        add(Screen.Jobs)
        add(Screen.Map)
        if (isJobPoster) add(Screen.Contractors)
        if (isContractor) add(Screen.MyOffers)
        add(Screen.Profile)
    }

    ScaffoldWithBottomBar(navController, tabs, isJobPoster, isContractor, authViewModel)
}

@Composable
private fun ScaffoldWithBottomBar(
    navController: NavHostController,
    tabs: List<Screen>,
    isJobPoster: Boolean,
    isContractor: Boolean,
    authViewModel: AuthViewModel
) {
    androidx.compose.material3.Scaffold(
        bottomBar = {
            NavigationBar {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentRoute = navBackStackEntry?.destination?.route
                tabs.forEach { screen ->
                    NavigationBarItem(
                        selected = currentRoute == screen.route,
                        onClick = {
                            navController.navigate(screen.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(screen.icon, contentDescription = screen.getLabel()) },
                        label = { Text(screen.getLabel()) }
                    )
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Dashboard.route
        ) {
            composable(Screen.Dashboard.route) { 
                if (isJobPoster) {
                    JobPosterDashboardView(
                        onCreateJobClick = { navController.navigate("job_form/new") },
                        onJobClick = { jobId -> navController.navigate("job_detail/$jobId") }
                    )
                } else {
                    ContractorDashboardView(
                        onOfferClick = { offer -> navController.navigate("offer_detail/${offer.jobId}/${offer.id ?: ""}") }
                    )
                }
            }
            composable(Screen.Jobs.route) {
                JobListView(
                    onJobClick = { job -> navController.navigate("job_detail/${job.id}") },
                    onCreateJobClick = { navController.navigate("job_form/new") }
                )
            }
            composable(Screen.Map.route) {
                JobMapView(
                    onJobClick = { jobId -> navController.navigate("job_detail/$jobId") }
                )
            }
            if (isJobPoster) {
                composable(Screen.Contractors.route) { 
                    ContractorListView(
                        onContractorClick = { contractorId -> navController.navigate("contractor_profile/$contractorId") }
                    )
                }
            }
            if (isContractor) {
                composable(Screen.MyOffers.route) { 
                    MyOffersView(
                        onOfferClick = { offer -> navController.navigate("offer_detail/${offer.jobId}/${offer.id ?: ""}") }
                    )
                }
            }
            composable(Screen.Profile.route) { 
                ProfileView(
                    onSignOut = { /* Handled by MainActivity */ }
                )
            }
            
            // Detail screens
            composable(Screen.JobDetail.route) { backStackEntry ->
                val jobId = backStackEntry.arguments?.getString("jobId") ?: ""
                // Create a minimal Job object for navigation - TODO: Load actual job data
                val job = com.shaglni.app.data.model.Job(
                    id = jobId,
                    title = "Loading...",
                    description = "Loading job details...",
                    location = "",
                    createdBy = "",
                    status = "open",
                    datePosted = com.google.firebase.Timestamp.now()
                )
                JobDetailView(
                    job = job,
                    onOfferClick = { offer ->
                        navController.navigate("offer_detail/$jobId/${offer.id ?: ""}")
                    },
                    onSubmitOfferClick = {
                        navController.navigate("offer_form/$jobId")
                    }
                )
            }
            
            composable(Screen.JobForm.route) { backStackEntry ->
                val jobId = backStackEntry.arguments?.getString("jobId") ?: ""
                JobFormView(
                    jobId = if (jobId == "new") null else jobId,
                    onJobSubmitted = { navController.popBackStack() },
                    onBackClick = { navController.popBackStack() }
                )
            }
            
            composable(Screen.OfferDetail.route) { backStackEntry ->
                val jobId = backStackEntry.arguments?.getString("jobId") ?: ""
                val offerId = backStackEntry.arguments?.getString("offerId") ?: ""
                // Create a minimal Offer object for navigation - TODO: Load actual offer data
                val offer = com.shaglni.app.data.model.Offer(
                    id = offerId,
                    jobId = jobId,
                    contractorId = "",
                    contractorName = "Loading...",
                    message = "Loading offer details...",
                    price = 0.0,
                    status = "pending",
                    createdAt = com.google.firebase.Timestamp.now()
                )
                OfferDetailView(
                    offer = offer,
                    jobId = jobId,
                    onBackClick = { navController.popBackStack() },
                    onContractorProfileClick = { contractor ->
                        navController.navigate("${Screen.ContractorProfile.route.replace("{contractorId}", contractor.userId)}")
                    }
                )
            }
            
            composable(Screen.OfferForm.route) { backStackEntry ->
                val jobId = backStackEntry.arguments?.getString("jobId") ?: ""
                OfferFormView(
                    jobId = jobId,
                    onOfferSubmitted = { navController.popBackStack() },
                    onBackClick = { navController.popBackStack() }
                )
            }
            
            composable(Screen.ContractorProfile.route) { backStackEntry ->
                val contractorId = backStackEntry.arguments?.getString("contractorId") ?: ""
                // Create a minimal ContractorProfile object for navigation - TODO: Load actual contractor data
                val contractor = com.shaglni.app.data.model.ContractorProfile(
                    userId = contractorId,
                    displayName = "Loading...",
                    bio = "",
                    skills = emptyList(),
                    completedJobsCount = 0,
                    availableForWork = true
                )
                ContractorProfileView(
                    contractor = contractor,
                    onBackClick = { navController.popBackStack() }
                )
            }
        }
    }
}


