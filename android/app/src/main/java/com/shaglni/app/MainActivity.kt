package com.shaglni.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.shaglni.app.ui.auth.AuthScreen
import com.shaglni.app.ui.auth.AuthViewModel
import com.shaglni.app.ui.navigation.ShaglniRootNavigation
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            Surface(color = MaterialTheme.colorScheme.background) {
                ShaglniAppRoot()
            }
        }
    }
}

@Composable
fun ShaglniAppRoot() {
    val vm: AuthViewModel = viewModel()
    val state = vm.state.collectAsStateWithLifecycle().value
    
    if (state.isLoading) {
        androidx.compose.material3.Text("Loading...")
    } else if (!state.isAuthenticated) {
        AuthScreen(
            onSignInClick = { email, password -> vm.signIn(email, password) },
            onSignUpClick = { email, password, role -> vm.signUp(email, password, role) },
            isLoading = state.isLoading,
            errorMessage = state.errorMessage
        )
    } else {
        ShaglniRootNavigation(
            isJobPoster = state.isJobPoster,
            isContractor = state.isContractor
        )
    }
}

@Preview
@Composable
fun PreviewRoot() {
    ShaglniAppRoot()
}


