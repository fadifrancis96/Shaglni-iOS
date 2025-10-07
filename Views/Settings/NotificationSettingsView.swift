//
//  NotificationSettingsView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var notificationsEnabled = false
    @State private var newOfferNotifications = true
    @State private var offerResponseNotifications = true
    @State private var isCheckingStatus = true
    
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Push Notifications")
                            .font(.headline)
                        if !notificationsEnabled {
                            Text("Enable in Settings to receive notifications")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if isCheckingStatus {
                        ProgressView()
                    } else {
                        Image(systemName: notificationsEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(notificationsEnabled ? .green : .red)
                            .font(.title2)
                    }
                }
                
                if !notificationsEnabled {
                    Button(action: openSettings) {
                        Label("Open Settings", systemImage: "gear")
                            .foregroundColor(.blue)
                    }
                }
            } header: {
                Text("Status")
            } footer: {
                Text("Receive real-time updates about your offers and jobs")
            }
            
            if notificationsEnabled {
                Section(header: Text("Notification Types")) {
                    Toggle(isOn: $newOfferNotifications) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("New Offers", systemImage: "envelope.badge.fill")
                                .font(.subheadline)
                            Text("Get notified when contractors submit offers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    Toggle(isOn: $offerResponseNotifications) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Offer Responses", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                            Text("Get notified about accepted, declined, or counter offers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.blue)
                        Text("Stay Updated")
                            .font(.headline)
                    }
                    
                    Text("Enable notifications to:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BenefitRow(icon: "💼", text: "Respond quickly to new offers")
                        BenefitRow(icon: "💰", text: "Know when your offers are accepted")
                        BenefitRow(icon: "🔔", text: "Never miss important updates")
                        BenefitRow(icon: "⚡", text: "Stay ahead of the competition")
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkNotificationStatus()
        }
        .refreshable {
            checkNotificationStatus()
        }
    }
    
    private func checkNotificationStatus() {
        isCheckingStatus = true
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
                isCheckingStatus = false
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.body)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}

