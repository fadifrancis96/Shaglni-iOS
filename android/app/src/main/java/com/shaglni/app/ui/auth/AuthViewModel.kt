package com.shaglni.app.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

data class AuthState(
    val isLoading: Boolean = true,
    val isAuthenticated: Boolean = false,
    val isJobPoster: Boolean = false,
    val isContractor: Boolean = false,
    val currentUser: com.google.firebase.auth.FirebaseUser? = null,
    val errorMessage: String? = null
)

class AuthViewModel : ViewModel() {
    private val auth: FirebaseAuth = FirebaseAuth.getInstance()
    private val db: FirebaseFirestore = FirebaseFirestore.getInstance()

    private val _state = MutableStateFlow(AuthState())
    val state: StateFlow<AuthState> = _state

    init {
        // Observe auth changes
        auth.addAuthStateListener {
            loadUserRole()
        }
        loadUserRole()
    }

    private fun loadUserRole() {
        val user = auth.currentUser
        if (user == null) {
            _state.value = AuthState(isLoading = false, isAuthenticated = false, currentUser = null)
            return
        }

        _state.value = _state.value.copy(isLoading = true, isAuthenticated = true, currentUser = user)

        viewModelScope.launch {
            try {
                val snap = db.collection("users").document(user.uid).get().await()
                val role = snap.getString("role")?.lowercase()
                val isPoster = role == "job_poster" || role == "jobposter"
                val isContr = role == "contractor"
                _state.value = AuthState(
                    isLoading = false,
                    isAuthenticated = true,
                    isJobPoster = isPoster,
                    isContractor = isContr,
                    currentUser = user
                )
            } catch (e: Exception) {
                // Default to contractor=false, jobPoster=false on error
                _state.value = AuthState(isLoading = false, isAuthenticated = true, currentUser = user)
            }
        }
    }

    fun signIn(email: String, password: String) {
        _state.value = _state.value.copy(isLoading = true, errorMessage = null)
        
        viewModelScope.launch {
            try {
                auth.signInWithEmailAndPassword(email, password).await()
                // loadUserRole() will be called automatically by the auth state listener
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Sign in failed"
                )
            }
        }
    }

    fun signUp(email: String, password: String, role: UserRole) {
        _state.value = _state.value.copy(isLoading = true, errorMessage = null)
        
        viewModelScope.launch {
            try {
                val result = auth.createUserWithEmailAndPassword(email, password).await()
                val user = result.user
                
                if (user != null) {
                    // Create user document in Firestore
                    val userData = mapOf(
                        "email" to email,
                        "role" to role.name.lowercase(),
                        "createdAt" to com.google.firebase.Timestamp.now()
                    )
                    db.collection("users").document(user.uid).set(userData).await()
                    
                    // loadUserRole() will be called automatically by the auth state listener
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    errorMessage = e.message ?: "Sign up failed"
                )
            }
        }
    }

    fun signOut() {
        auth.signOut()
    }
}


