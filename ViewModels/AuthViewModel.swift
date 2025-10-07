//
//  AuthViewModel.swift
//  Shaglni
//
//  Created on October 2025
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    @Published var currentUserData: UserData?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            if let user = user {
                self?.fetchUserData(userId: user.uid)
                // Save FCM token when user logs in
                // TODO: Uncomment after adding FirebaseMessaging package to Xcode
                // if let fcmToken = PushNotificationService.shared.fcmToken {
                //     PushNotificationService.shared.saveFCMToken(userId: user.uid, token: fcmToken)
                // }
            } else {
                self?.currentUserData = nil
                self?.isLoading = false
            }
        }
    }
    
    private func fetchUserData(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                self?.isLoading = false
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                do {
                    self?.currentUserData = try snapshot.data(as: UserData.self)
                } catch {
                    print("Error decoding user data: \(error.localizedDescription)")
                }
            }
            self?.isLoading = false
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            completion(true, nil)
        }
    }
    
    func signUp(email: String, password: String, displayName: String, role: UserRole, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            guard let userId = result?.user.uid else {
                completion(false, "Failed to get user ID")
                return
            }
            
            // Create user document in Firestore
            let userData = UserData(
                id: userId,
                email: email,
                displayName: displayName,
                role: role,
                createdAt: Date()
            )
            
            do {
                try self?.db.collection("users").document(userId).setData(from: userData) { error in
                    if let error = error {
                        completion(false, error.localizedDescription)
                        return
                    }
                    
                    // If contractor, create profile
                    if role == .contractor {
                        self?.createInitialContractorProfile(userId: userId, displayName: displayName)
                    }
                    
                    completion(true, nil)
                }
            } catch {
                completion(false, error.localizedDescription)
            }
        }
    }
    
    private func createInitialContractorProfile(userId: String, displayName: String) {
        let profile = ContractorProfile(
            userId: userId,
            displayName: displayName,
            bio: "",
            skills: [],
            rating: nil,
            completedJobsCount: 0,
            availableForWork: true
        )
        
        do {
            try db.collection("contractorProfiles").document(userId).setData(from: profile)
        } catch {
            print("Error creating contractor profile: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        // Remove FCM token before signing out
        // TODO: Uncomment after adding FirebaseMessaging package to Xcode
        // if let userId = currentUser?.uid {
        //     PushNotificationService.shared.removeFCMToken(userId: userId)
        // }
        
        try? Auth.auth().signOut()
        currentUser = nil
        currentUserData = nil
    }
    
    var isJobPoster: Bool {
        currentUserData?.role == .jobPoster
    }
    
    var isContractor: Bool {
        currentUserData?.role == .contractor
    }
}
