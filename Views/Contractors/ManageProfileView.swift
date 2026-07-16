//
//  ManageProfileView.swift
//  Shaglni
//

import SwiftUI
import PhotosUI

struct ManageProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
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
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else {
                    VStack(spacing: 24) {
                        profilePictureAvatar
                            .padding(.top)
                        
                        if isEditing {
                            // Edit Form
                            VStack(spacing: 20) {
                                // Bio
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L10n.Field.bio.string)
                                        .font(.headline)

                                    TextEditor(text: $bio)
                                        .frame(minHeight: 100)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                                
                                // Skills
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L10n.Field.skills.string)
                                        .font(.headline)

                                    FlowLayout(spacing: 8) {
                                        ForEach(skills, id: \.self) { skill in
                                            HStack(spacing: 4) {
                                                Text(skill)
                                                    .font(.subheadline)
                                                
                                                Button(action: { removeSkill(skill) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(8)
                                        }
                                    }
                                    
                                    HStack {
                                        TextField(L10n(key: "manageProfile.addSkill").string, text: $newSkill)
                                            .textFieldStyle(.roundedBorder)
                                        
                                        Button(action: addSkill) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.blue)
                                        }
                                        .disabled(newSkill.isEmpty)
                                    }
                                }
                                
                                // Contact Info
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L10n.Field.contactInfo.string)
                                        .font(.headline)

                                    TextField(L10n.Common.email.string, text: $contactEmail)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)

                                    TextField(L10n.Field.phone.string, text: $phone)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.phonePad)

                                    TextField(L10n.Field.website.string, text: $website)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.URL)
                                        .textInputAutocapitalization(.never)
                                }
                                
                                // Location
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L10n.Field.location.string)
                                        .font(.headline)

                                    TextField(L10n.Field.location.string, text: $location)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                // Availability
                                Toggle(L10n.Field.availableForWork.string, isOn: $availableForWork)
                                    .font(.headline)
                                
                                // Save Button
                                Button(action: saveProfile) {
                                    if isSaving {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(L10n.Common.save.string)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .disabled(isSaving)
                            }
                            .padding()
                        } else {
                            // View Mode
                            if let profile = profile {
                                VStack(spacing: 20) {
                                    Text(profile.displayName)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    if !profile.bio.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(L10n.Field.bio.string)
                                                .font(.headline)
                                            Text(profile.bio)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    if !profile.skills.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text(L10n.Field.skills.string)
                                                .font(.headline)
                                            
                                            FlowLayout(spacing: 8) {
                                                ForEach(profile.skills, id: \.self) { skill in
                                                    Text(skill)
                                                        .font(.subheadline)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(Color.blue.opacity(0.1))
                                                        .foregroundColor(.blue)
                                                        .cornerRadius(8)
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    Button(action: { isEditing = true }) {
                                        Text(L10n.Common.edit.string)
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.Action.manageProfile.string)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadProfile)
        }
    }
    
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

    @ViewBuilder
    private var profilePictureAvatar: some View {
        PhotosPicker(selection: $pickedItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let url = profile?.profilePicture {
                        RemoteImage(urlString: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        }
                    } else {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.accentColor)
                            )
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())

                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Group {
                            if isUploadingPic {
                                ProgressView().tint(.white).controlSize(.small)
                            } else {
                                Image(systemName: "camera.fill").foregroundColor(.white).font(.caption)
                            }
                        }
                    )
            }
        }
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task { await uploadPickedPicture(item: newItem) }
        }
        if let picUploadError {
            Text(picUploadError).font(.caption).foregroundColor(.red)
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

#Preview {
    ManageProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
        .environmentObject(ContractorsRepository.shared)
}
