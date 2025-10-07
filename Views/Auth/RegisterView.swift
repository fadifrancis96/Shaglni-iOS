//
//  RegisterView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var selectedRole: UserRole?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text(localization.localized("register"))
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(localization.localized("selectRole"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Role Selection
                VStack(spacing: 16) {
                    RoleCard(
                        role: .jobPoster,
                        title: localization.localized("jobPoster"),
                        icon: "briefcase.fill",
                        description: localization.localized("postJob"),
                        isSelected: selectedRole == .jobPoster
                    ) {
                        selectedRole = .jobPoster
                    }
                    
                    RoleCard(
                        role: .contractor,
                        title: localization.localized("contractor"),
                        icon: "hammer.fill",
                        description: localization.localized("findContractor"),
                        isSelected: selectedRole == .contractor
                    ) {
                        selectedRole = .contractor
                    }
                }
                .padding(.horizontal, 30)
                
                // Form
                if selectedRole != nil {
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localization.localized("displayName"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField(localization.localized("displayName"), text: $displayName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
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
                        
                        // Register Button
                        Button(action: handleRegister) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(localization.localized("signUp"))
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
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: selectedRole)
    }
    
    private var isFormValid: Bool {
        selectedRole != nil &&
        !displayName.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 6
    }
    
    private func handleRegister() {
        guard let role = selectedRole else { return }
        
        isLoading = true
        errorMessage = nil
        
        authViewModel.signUp(
            email: email,
            password: password,
            displayName: displayName,
            role: role
        ) { success, error in
            isLoading = false
            
            if success {
                dismiss()
            } else {
                errorMessage = error ?? "Registration failed"
            }
        }
    }
}

struct RoleCard: View {
    let role: UserRole
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthViewModel())
            .environmentObject(LocalizationManager())
    }
}
