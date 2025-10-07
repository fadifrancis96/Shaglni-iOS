//
//  ManageProfileView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct ManageProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @State private var profile: ContractorProfile?
    @State private var isLoading = true
    @State private var isEditing = false
    
    // Form fields
    @State private var bio = ""
    @State private var skills: [String] = []
    @State private var newSkill = ""
    @State private var contactEmail = ""
    @State private var phone = ""
    @State private var website = ""
    @State private var location = ""
    @State private var availableForWork = true
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else {
                    VStack(spacing: 24) {
                        // Profile Picture
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.blue)
                            )
                            .padding(.top)
                        
                        if isEditing {
                            // Edit Form
                            VStack(spacing: 20) {
                                // Bio
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(localization.localized("bio"))
                                        .font(.headline)
                                    
                                    TextEditor(text: $bio)
                                        .frame(minHeight: 100)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                                
                                // Skills
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(localization.localized("skills"))
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
                                        TextField("Add skill", text: $newSkill)
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
                                    Text(localization.localized("contactInfo"))
                                        .font(.headline)
                                    
                                    TextField(localization.localized("email"), text: $contactEmail)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                    
                                    TextField(localization.localized("phone"), text: $phone)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.phonePad)
                                    
                                    TextField(localization.localized("website"), text: $website)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.URL)
                                        .textInputAutocapitalization(.never)
                                }
                                
                                // Location
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(localization.localized("location"))
                                        .font(.headline)
                                    
                                    TextField(localization.localized("location"), text: $location)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                // Availability
                                Toggle(localization.localized("availableForWork"), isOn: $availableForWork)
                                    .font(.headline)
                                
                                // Save Button
                                Button(action: saveProfile) {
                                    if isSaving {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(localization.localized("save"))
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
                                            Text(localization.localized("bio"))
                                                .font(.headline)
                                            Text(profile.bio)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    if !profile.skills.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text(localization.localized("skills"))
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
                                        Text(localization.localized("edit"))
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
            .navigationTitle(localization.localized("manageProfile"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadProfile)
        }
    }
    
    private func loadProfile() {
        guard let userId = authViewModel.currentUser?.uid else { return }
        
        FirestoreService.shared.fetchContractorProfile(userId: userId) { result in
            isLoading = false
            switch result {
            case .success(let fetchedProfile):
                profile = fetchedProfile
                populateFields(from: fetchedProfile)
            case .failure(let error):
                print("Error loading profile: \(error.localizedDescription)")
            }
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
            location: location.isEmpty ? nil : location,
            availableForWork: availableForWork
        )
        
        FirestoreService.shared.updateContractorProfile(updatedProfile) { result in
            isSaving = false
            switch result {
            case .success:
                profile = updatedProfile
                isEditing = false
            case .failure(let error):
                print("Error saving profile: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ManageProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager())
}
