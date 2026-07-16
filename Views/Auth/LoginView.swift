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
        ZStack {
            Color.bgCanvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Space.xxl) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.AuthUI.welcomeBack.string)
                            .font(.dsTitle)
                            .foregroundStyle(Color.ink)
                        Text(L10n.AuthUI.loginSubtitle.string)
                            .font(.dsSub)
                            .foregroundStyle(Color.inkMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, DS.Space.xl)

                    // Form
                    VStack(spacing: DS.Space.l) {
                        DSTextField(
                            label: L10n.Common.email.string,
                            systemImage: "envelope",
                            text: $email,
                            keyboard: .emailAddress,
                            contentType: .emailAddress
                        )
                        DSTextField(
                            label: L10n.Common.password.string,
                            systemImage: "lock",
                            text: $password,
                            isSecure: true,
                            contentType: .password
                        )

                        Button { showResetSheet = true } label: {
                            Text(L10n.Action.forgotPassword.string)
                                .font(.dsCaptionBold)
                                .foregroundStyle(Color.brand)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    if let errorMessage {
                        DSBanner(kind: .error, message: errorMessage)
                    }

                    // Submit
                    Button(action: handleLogin) {
                        if isLoading {
                            ProgressView().tint(Color.onBrand)
                        } else {
                            Text(L10n.Common.signIn.string)
                        }
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                    .disabled(!isFormValid || isLoading)
                    .opacity(isFormValid ? 1 : 0.5)

                    // Footer → register
                    NavigationLink {
                        RegisterView()
                    } label: {
                        HStack(spacing: 6) {
                            Text(L10n.AuthUI.noAccount.string)
                                .foregroundStyle(Color.inkMuted)
                            Text(L10n.Common.signUp.string)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.brand)
                        }
                        .font(.dsSub)
                    }
                    .padding(.bottom, DS.Space.xl)
                }
                .padding(.horizontal, DS.Space.screen)
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
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                VStack(spacing: DS.Space.xl) {
                    DSTextField(
                        label: L10n.Common.email.string,
                        systemImage: "envelope",
                        text: $email,
                        keyboard: .emailAddress,
                        contentType: .emailAddress
                    )

                    if let status {
                        DSBanner(kind: .success, message: status)
                    }

                    Button {
                        working = true
                        Task {
                            try? await authViewModel.sendPasswordReset(to: email)
                            status = L10n.Auth.resetEmailSent.string
                            working = false
                        }
                    } label: {
                        if working {
                            ProgressView().tint(Color.onBrand)
                        } else {
                            Text(L10n.Action.sendResetEmail.string)
                        }
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                    .disabled(email.isEmpty || working)
                    .opacity(email.isEmpty ? 0.5 : 1)

                    Spacer()
                }
                .padding(DS.Space.screen)
            }
            .navigationTitle(L10n.Action.forgotPassword.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel.string) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthViewModel())
            .environmentObject(LocalizationManager.shared)
    }
}
