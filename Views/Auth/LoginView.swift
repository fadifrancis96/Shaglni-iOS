//
//  LoginView.swift
//  Shaglni
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResetSheet = false
    @State private var resetStatus: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(.tint)
                    L10n.welcome.text
                        .font(.title).fontWeight(.bold)
                    L10n.Common.signIn.text
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                VStack(spacing: 20) {
                    LabeledField(title: L10n.Common.email.string) {
                        TextField(L10n.Common.email.string, text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                    }
                    LabeledField(title: L10n.Common.password.string) {
                        SecureField(L10n.Common.password.string, text: $password)
                            .textFieldStyle(.roundedBorder)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: handleLogin) {
                        if isLoading {
                            ProgressView().progressViewStyle(.circular).tint(.white)
                        } else {
                            L10n.Common.signIn.text.fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(!isFormValid || isLoading)

                    Button { showResetSheet = true } label: {
                        L10n.Action.forgotPassword.text.font(.footnote)
                    }
                }
                .padding(.horizontal, 30)
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResetSheet) {
            ResetPasswordSheet(email: email, status: $resetStatus)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }

    private func handleLogin() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authViewModel.signIn(email: email, password: password)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

/// Reusable labeled field used across the auth forms.
struct LabeledField<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).fontWeight(.medium)
            content()
        }
    }
}

/// Password-reset sheet. Always reports a generic success so we don't leak whether
/// the email was registered.
struct ResetPasswordSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    @State var email: String
    @Binding var status: String?
    @State private var working = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.Common.email.string, text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                if let status {
                    Section { Text(status).foregroundStyle(.secondary) }
                }
                Section {
                    Button {
                        working = true
                        Task {
                            try? await authViewModel.sendPasswordReset(to: email)
                            status = L10n.Auth.resetEmailSent.string
                            working = false
                        }
                    } label: {
                        if working {
                            ProgressView()
                        } else {
                            L10n.Action.sendResetEmail.text
                        }
                    }
                    .disabled(email.isEmpty || working)
                }
            }
            .navigationTitle(L10n.Action.forgotPassword.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel.string) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthViewModel())
            .environmentObject(LocalizationManager.shared)
    }
}
