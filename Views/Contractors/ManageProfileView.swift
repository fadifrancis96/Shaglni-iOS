//
//  ManageProfileView.swift
//  Shaglni
//
//  Contractor profile management: avatar upload, bio, skills, contact
//  info and availability — view and edit modes on the design system.
//

import SwiftUI
import PhotosUI

struct ManageProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var contractorsRepo: ContractorsRepository

    @State private var profile: ContractorProfile?
    @State private var isLoading = true
    @State private var isEditing = false

    @State private var bio = ""
    @State private var skills: [String] = []
    @State private var newSkill = ""
    @State private var contactEmail = ""
    @State private var phone = ""
    @State private var website = ""
    @State private var location = ""
    @State private var availableForWork = true
    @State private var isSaving = false

    // Profile-picture state
    @State private var pickedItem: PhotosPickerItem?
    @State private var isUploadingPic = false
    @State private var picUploadError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.xl) {
                        if isLoading {
                            ProgressView()
                                .tint(Color.brand)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 48)
                        } else {
                            profilePictureAvatar
                                .padding(.top, DS.Space.s)

                            if isEditing {
                                editForm
                            } else {
                                viewMode
                            }
                        }
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.vertical, DS.Space.l)
                }
            }
            .navigationTitle(L10n.Action.manageProfile.string)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadProfile)
        }
    }

    // MARK: - Edit mode

    private var editForm: some View {
        VStack(spacing: DS.Space.xl) {
            // Bio
            DSTextEditor(
                label: L10n.Field.bio.string,
                text: $bio,
                minHeight: 110
            )

            // Skills
            VStack(alignment: .leading, spacing: DS.Space.s) {
                Text(L10n.Field.skills.string)
                    .font(.dsCaptionBold)
                    .foregroundStyle(Color.inkMuted)

                if !skills.isEmpty {
                    DSFlowLayout(spacing: DS.Space.s) {
                        ForEach(skills, id: \.self) { skill in
                            EditableSkillChip(title: skill) { removeSkill(skill) }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: DS.Space.m) {
                    TextField(L10n(key: "manageProfile.addSkill").string, text: $newSkill)
                        .font(.dsBody)
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, DS.Space.l)
                        .padding(.vertical, 12)
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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(newSkill.isEmpty ? Color.inkFaint : Color.onBrand)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                                    .fill(newSkill.isEmpty ? Color.surfaceAlt : Color.brand)
                            )
                    }
                    .disabled(newSkill.isEmpty)
                }
            }

            // Contact info
            VStack(alignment: .leading, spacing: DS.Space.l) {
                Text(L10n.Field.contactInfo.string)
                    .font(.dsTitle2)
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                DSTextField(
                    label: L10n.Common.email.string,
                    systemImage: "envelope.fill",
                    text: $contactEmail,
                    keyboard: .emailAddress,
                    contentType: .emailAddress
                )

                DSTextField(
                    label: L10n.Field.phone.string,
                    systemImage: "phone.fill",
                    text: $phone,
                    keyboard: .phonePad,
                    contentType: .telephoneNumber
                )

                DSTextField(
                    label: L10n.Field.website.string,
                    systemImage: "globe",
                    text: $website,
                    keyboard: .URL,
                    contentType: .URL
                )

                DSTextField(
                    label: L10n.Field.location.string,
                    systemImage: "mappin.and.ellipse",
                    text: $location,
                    autocapitalization: .words
                )
            }

            // Availability
            Toggle(isOn: $availableForWork) {
                Text(L10n.Field.availableForWork.string)
                    .font(.dsHeadline)
                    .foregroundStyle(Color.ink)
            }
            .tint(Color.brand)
            .dsCard()

            // Save
            Button(action: saveProfile) {
                if isSaving {
                    ProgressView()
                        .tint(Color.onBrand)
                } else {
                    Text(L10n.Common.save.string)
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .disabled(isSaving)
        }
    }

    // MARK: - View mode

    @ViewBuilder
    private var viewMode: some View {
        if let profile = profile {
            VStack(spacing: DS.Space.xl) {
                Text(profile.displayName)
                    .font(.dsTitle)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)

                if !profile.bio.isEmpty {
                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        DSSectionHeader(title: L10n.Field.bio.string)

                        Text(profile.bio)
                            .font(.dsSub)
                            .foregroundStyle(Color.inkMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .dsCard()
                    }
                }

                if !profile.skills.isEmpty {
                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        DSSectionHeader(title: L10n.Field.skills.string)

                        DSFlowLayout(spacing: DS.Space.s) {
                            ForEach(profile.skills, id: \.self) { skill in
                                DSTag(title: skill, tint: .brand, background: .brandSoft)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .dsCard()
                    }
                }

                Button {
                    isEditing = true
                } label: {
                    Text(L10n.Common.edit.string)
                }
                .buttonStyle(DSPrimaryButtonStyle())
            }
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var profilePictureAvatar: some View {
        PhotosPicker(selection: $pickedItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                DSAvatar(
                    name: profile?.displayName ?? authViewModel.currentUserData?.displayName ?? "",
                    urlString: profile?.profilePicture,
                    size: 96
                )

                Circle()
                    .fill(Color.brand)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Group {
                            if isUploadingPic {
                                ProgressView()
                                    .tint(Color.onBrand)
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.onBrand)
                            }
                        }
                    )
                    .overlay(Circle().strokeBorder(Color.surface, lineWidth: 2))
            }
        }
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task { await uploadPickedPicture(item: newItem) }
        }
        if let picUploadError {
            DSBanner(kind: .error, message: picUploadError)
        }
    }

    // MARK: - Data

    private func loadProfile() {
        guard let userId = authViewModel.currentUser?.uid else { return }
        Task {
            do {
                let fetched = try await contractorsRepo.fetchProfile(userId: userId)
                profile = fetched
                populateFields(from: fetched)
            } catch {
                AppLogger.contractors.warning("loadProfile failed: \(error.localizedDescription, privacy: .public)")
            }
            isLoading = false
        }
    }

    private func uploadPickedPicture(item: PhotosPickerItem) async {
        guard let userId = authViewModel.currentUser?.uid else { return }
        isUploadingPic = true
        defer { isUploadingPic = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                picUploadError = L10n(key: "manageProfile.imageReadError").string
                return
            }
            let url = try await PhotoUploadService.shared.uploadProfilePicture(userId: userId, image: image)
            try await contractorsRepo.updateProfilePictureURL(userId: userId, urlString: url)
            // Reflect locally so the UI updates instantly while the listener catches up.
            if var p = profile { p.profilePicture = url; profile = p }
            picUploadError = nil
        } catch {
            picUploadError = error.localizedDescription
        }
    }

    private func populateFields(from profile: ContractorProfile) {
        bio = profile.bio
        skills = profile.skills
        contactEmail = profile.contactEmail ?? ""
        phone = profile.phone ?? ""
        website = profile.website ?? ""
        location = profile.location ?? ""
        availableForWork = profile.availableForWork
    }

    private func addSkill() {
        let trimmedSkill = newSkill.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSkill.isEmpty && !skills.contains(trimmedSkill) {
            skills.append(trimmedSkill)
            newSkill = ""
        }
    }

    private func removeSkill(_ skill: String) {
        skills.removeAll { $0 == skill }
    }

    private func saveProfile() {
        guard let userId = authViewModel.currentUser?.uid,
              let userName = authViewModel.currentUserData?.displayName else { return }

        isSaving = true
        let updatedProfile = ContractorProfile(
            userId: userId,
            displayName: userName,
            bio: bio,
            skills: skills,
            rating: profile?.rating,
            completedJobsCount: profile?.completedJobsCount ?? 0,
            contactEmail: contactEmail.isEmpty ? nil : contactEmail,
            phone: phone.isEmpty ? nil : phone,
            website: website.isEmpty ? nil : website,
            profilePicture: profile?.profilePicture,
            location: location.isEmpty ? nil : location,
            latitude: profile?.latitude,
            longitude: profile?.longitude,
            availableForWork: availableForWork
        )

        Task {
            do {
                try await contractorsRepo.upsertProfile(updatedProfile)
                profile = updatedProfile
                isEditing = false
            } catch {
                AppLogger.contractors.error("save profile failed: \(error.localizedDescription, privacy: .public)")
            }
            isSaving = false
        }
    }
}

// MARK: - Skill chip (edit mode, removable)

private struct EditableSkillChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.dsCaptionBold)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.brand)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.brandSoft))
    }
}

#Preview {
    ManageProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
        .environmentObject(ContractorsRepository.shared)
}
