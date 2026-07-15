//
//  RegisterView.swift
//  Shaglni
//
//  Three-step onboarding wizard:
//   1) Role: Job poster or contractor
//   2) Account: name / email / password
//   3) Contractor profile (skills + location + availability) — only shown for contractors
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var contractorsRepo: ContractorsRepository
    @Environment(\.dismiss) var dismiss

    @State private var step = 0
    @State private var selectedRole: UserRole?
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var skills: [String] = []
    @State private var newSkill = ""
    @State private var location = ""
    @State private var phone = ""
    @State private var availableForWork = true

    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                ProgressIndicator(current: step, total: totalSteps)
                    .padding(.horizontal, 30)

                Group {
                    switch step {
                    case 0: roleStep
                    case 1: accountStep
                    default: contractorStep
                    }
                }
                .transition(.opacity)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }

                actionRow
                Spacer()
            }
            .padding(.top, 30)
        }
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: step)
    }

    private var totalSteps: Int { selectedRole == .contractor ? 3 : 2 }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 54))
                .foregroundStyle(.tint)
            L10n.Common.register.text.font(.title).fontWeight(.bold)
        }
    }

    // MARK: - Steps

    private var roleStep: some View {
        VStack(spacing: 16) {
            Text(L10n.Role.select.string)
                .font(.title3)
                .foregroundStyle(.secondary)

            RoleCard(
                role: .jobPoster,
                title: L10n.Role.jobPoster.string,
                icon: "briefcase.fill",
                description: L10n.Action.postJob.string,
                isSelected: selectedRole == .jobPoster
            ) { selectedRole = .jobPoster }

            RoleCard(
                role: .contractor,
                title: L10n.Role.contractor.string,
                icon: "hammer.fill",
                description: L10n.Action.findContractor.string,
                isSelected: selectedRole == .contractor
            ) { selectedRole = .contractor }
        }
        .padding(.horizontal, 30)
    }

    private var accountStep: some View {
        VStack(spacing: 16) {
            LabeledField(title: L10n.Common.displayName.string) {
                TextField(L10n.Common.displayName.string, text: $displayName)
                    .textFieldStyle(.roundedBorder)
            }
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
        }
        .padding(.horizontal, 30)
    }

    private var contractorStep: some View {
        VStack(spacing: 16) {
            LabeledField(title: L10n.Field.skills.string) {
                HStack {
                    TextField(L10n.Field.skills.string, text: $newSkill)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        let trimmed = newSkill.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty, !skills.contains(trimmed) { skills.append(trimmed) }
                        newSkill = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(newSkill.isEmpty)
                }
                if !skills.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(skills, id: \.self) { skill in
                            HStack(spacing: 4) {
                                Text(skill).font(.subheadline)
                                Button { skills.removeAll { $0 == skill } } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            LabeledField(title: L10n.Field.location.string + " (" + L10n.Common.optional.string + ")") {
                TextField(L10n.Field.location.string, text: $location)
                    .textFieldStyle(.roundedBorder)
            }
            LabeledField(title: L10n.Field.phone.string + " (" + L10n.Common.optional.string + ")") {
                TextField(L10n.Field.phone.string, text: $phone)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.phonePad)
            }
            Toggle(L10n.Field.availableForWork.string, isOn: $availableForWork)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack {
            if step > 0 {
                Button(L10n.Common.back.string) { step -= 1 }
                    .buttonStyle(.bordered)
            }
            Spacer()
            Button {
                if step == totalSteps - 1 {
                    Task { await submit() }
                } else {
                    step += 1
                }
            } label: {
                if isWorking {
                    ProgressView().tint(.white)
                } else {
                    Text(step == totalSteps - 1 ? L10n.Common.signUp.string : L10n.Common.next.string)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 12)
            .background(canAdvance ? Color.accentColor : Color.gray)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(!canAdvance || isWorking)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Validation

    private var canAdvance: Bool {
        switch step {
        case 0: return selectedRole != nil
        case 1: return !displayName.isEmpty && email.contains("@") && password.count >= 6
        default: return true
        }
    }

    // MARK: - Submit

    private func submit() async {
        guard let role = selectedRole else { return }
        isWorking = true
        errorMessage = nil
        do {
            try await authViewModel.signUp(email: email, password: password, displayName: displayName, role: role)
            // For contractors, immediately patch the profile we just created with the
            // information they entered in step 3.
            if role == .contractor, let uid = authViewModel.currentUser?.uid {
                let profile = ContractorProfile(
                    userId: uid,
                    displayName: displayName,
                    bio: "",
                    skills: skills,
                    rating: nil,
                    completedJobsCount: 0,
                    contactEmail: email,
                    phone: phone.isEmpty ? nil : phone,
                    website: nil,
                    profilePicture: nil,
                    location: location.isEmpty ? nil : location,
                    latitude: nil,
                    longitude: nil,
                    availableForWork: availableForWork
                )
                try await contractorsRepo.upsertProfile(profile)
            }
            isWorking = false
            dismiss()
        } catch {
            isWorking = false
            errorMessage = error.localizedDescription
        }
    }
}

struct ProgressIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { idx in
                Capsule()
                    .fill(idx <= current ? Color.accentColor : Color(.systemGray5))
                    .frame(height: 4)
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
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    Text(description).font(.caption)
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
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthViewModel())
            .environmentObject(ContractorsRepository.shared)
            .environmentObject(LocalizationManager.shared)
    }
}
