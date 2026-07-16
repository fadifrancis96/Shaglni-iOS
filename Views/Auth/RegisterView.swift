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
        ZStack {
            Color.bgCanvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Space.xl) {
                    header
                    StepProgressBar(current: step, total: totalSteps)

                    Group {
                        switch step {
                        case 0: roleStep
                        case 1: accountStep
                        default: contractorStep
                        }
                    }
                    .transition(.opacity)

                    if let errorMessage {
                        DSBanner(kind: .error, message: errorMessage)
                    }

                    actionRow
                        .padding(.bottom, DS.Space.xl)
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.top, DS.Space.l)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: step)
    }

    private var totalSteps: Int { selectedRole == .contractor ? 3 : 2 }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.AuthUI.createAccount.string)
                .font(.dsTitle)
                .foregroundStyle(Color.ink)
            Text(L10n.AuthUI.registerSubtitle.string)
                .font(.dsSub)
                .foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Steps

    private var roleStep: some View {
        VStack(spacing: DS.Space.l) {
            Text(L10n.Role.select.string)
                .font(.dsTitle2)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            RoleCard(
                title: L10n.Role.jobPoster.string,
                icon: "briefcase.fill",
                description: L10n.AuthUI.jobPosterDesc.string,
                isSelected: selectedRole == .jobPoster
            ) { selectedRole = .jobPoster }

            RoleCard(
                title: L10n.Role.contractor.string,
                icon: "hammer.fill",
                description: L10n.AuthUI.contractorDesc.string,
                isSelected: selectedRole == .contractor
            ) { selectedRole = .contractor }
        }
    }

    private var accountStep: some View {
        VStack(spacing: DS.Space.l) {
            DSTextField(
                label: L10n.Common.displayName.string,
                systemImage: "person",
                text: $displayName,
                contentType: .name,
                autocapitalization: .words
            )
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
                contentType: .newPassword
            )
        }
    }

    private var contractorStep: some View {
        VStack(spacing: DS.Space.l) {
            // Skills entry
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Field.skills.string)
                    .font(.dsCaptionBold)
                    .foregroundStyle(Color.inkMuted)

                HStack(spacing: DS.Space.m) {
                    TextField(L10n.Field.skills.string, text: $newSkill)
                        .font(.dsBody)
                        .padding(.horizontal, DS.Space.l)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                                .fill(Color.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                                .strokeBorder(Color.divider, lineWidth: 1)
                        )
                        .onSubmit(addSkill)

                    Button(action: addSkill) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.onBrand)
                            .frame(width: 48, height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                                    .fill(Color.brand)
                            )
                    }
                    .disabled(newSkill.isEmpty)
                    .opacity(newSkill.isEmpty ? 0.4 : 1)
                }

                if !skills.isEmpty {
                    DSFlowLayout(spacing: 8) {
                        ForEach(skills, id: \.self) { skill in
                            HStack(spacing: 5) {
                                Text(skill)
                                    .font(.dsCaptionBold)
                                    .foregroundStyle(Color.brand)
                                Button { skills.removeAll { $0 == skill } } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color.brand.opacity(0.7))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.brandSoft))
                        }
                    }
                    .padding(.top, DS.Space.s)
                }
            }

            DSTextField(
                label: "\(L10n.Field.location.string) (\(L10n.Common.optional.string))",
                systemImage: "mappin.and.ellipse",
                text: $location,
                autocapitalization: .words
            )
            DSTextField(
                label: "\(L10n.Field.phone.string) (\(L10n.Common.optional.string))",
                systemImage: "phone",
                text: $phone,
                keyboard: .phonePad,
                contentType: .telephoneNumber
            )

            Toggle(isOn: $availableForWork) {
                Text(L10n.Field.availableForWork.string)
                    .font(.dsHeadline)
                    .foregroundStyle(Color.ink)
            }
            .tint(Color.brand)
            .padding(DS.Space.l)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .fill(Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(Color.divider, lineWidth: 1)
            )
        }
    }

    private func addSkill() {
        let trimmed = newSkill.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, !skills.contains(trimmed) { skills.append(trimmed) }
        newSkill = ""
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: DS.Space.m) {
            if step > 0 {
                Button(L10n.Common.back.string) { step -= 1 }
                    .buttonStyle(DSOutlineButtonStyle())
                    .frame(width: 110)
            }

            Button {
                if step == totalSteps - 1 {
                    Task { await submit() }
                } else {
                    step += 1
                }
            } label: {
                if isWorking {
                    ProgressView().tint(Color.onBrand)
                } else {
                    Text(step == totalSteps - 1 ? L10n.Common.signUp.string : L10n.Common.next.string)
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .disabled(!canAdvance || isWorking)
            .opacity(canAdvance ? 1 : 0.5)
        }
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

// MARK: - Step progress

struct StepProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { idx in
                Capsule()
                    .fill(idx <= current ? Color.brand : Color.divider)
                    .frame(height: 5)
            }
        }
        .animation(.easeOut(duration: 0.25), value: current)
    }
}

// MARK: - Role card

struct RoleCard: View {
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.l) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.onBrand : Color.brand)
                    .frame(width: 54, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous)
                            .fill(isSelected ? Color.brand : Color.brandSoft)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.dsHeadline)
                        .foregroundStyle(Color.ink)
                    Text(description)
                        .font(.dsCaption)
                        .foregroundStyle(Color.inkMuted)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.brand : Color.divider)
            }
            .padding(DS.Space.l)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .fill(Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .strokeBorder(isSelected ? Color.brand : Color.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(DSPressableStyle())
        .animation(.easeOut(duration: 0.15), value: isSelected)
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
