//
//  LoginView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text(localization.localized("welcome"))
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(localization.localized("login"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized("email"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField(localization.localized("email"), text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized("password"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        SecureField(localization.localized("password"), text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Login Button
                    Button(action: handleLogin) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(localization.localized("signIn"))
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!isFormValid || isLoading)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func handleLogin() {
        isLoading = true
        errorMessage = nil
        
        authViewModel.signIn(email: email, password: password) { success, error in
            isLoading = false
            
            if success {
                dismiss()
            } else {
                errorMessage = error ?? "Login failed"
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthViewModel())
            .environmentObject(LocalizationManager())
    }
}
