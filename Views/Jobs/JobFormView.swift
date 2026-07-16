//
//  JobFormView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI
import MapKit

struct JobFormView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var jobsRepo: JobsRepository
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var locationSearchText = ""
    @State private var locationSuggestions: [MKLocalSearchCompletion] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocationName = ""
    @State private var showLocationPicker = false
    @State private var selectedCategory: JobCategory?
    @State private var budget = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    // Photo upload
    @State private var selectedImages: [UIImage] = []
    @State private var showPhotoPicker = false
    @State private var uploadedPhotoURLs: [String] = []
    
    @StateObject private var locationSearchService = LocationSearchService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L10n(key: "job.details").string)) {
                    TextField(L10n.Field.title.string, text: $title)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text(L10n.Field.description.string)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 4)
                                        .padding(.top, 8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                    
                    // Location Picker
                    Button(action: { showLocationPicker = true }) {
                        HStack {
                            Text(L10n.Field.location.string)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedLocationName.isEmpty {
                                Text(L10n(key: "jobForm.selectLocation").string)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(selectedLocationName)
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Picker(L10n.Field.category.string, selection: $selectedCategory) {
                        Text(L10n(key: "jobForm.selectCategory").string).tag(nil as JobCategory?)
                        ForEach(JobCategory.allCases, id: \.self) { category in
                            Text(category.localized).tag(category as JobCategory?)
                        }
                    }

                    TextField("\(L10n.Field.budget.string) (\(L10n.Common.optional.string))", text: $budget)
                        .keyboardType(.decimalPad)
                }
                
                // Photo Upload Section
                Section(header: Text(L10n(key: "jobForm.requirementsPhotos").string)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { showPhotoPicker = true }) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                    .foregroundColor(.blue)
                                Text(L10n(key: "jobForm.addPhotos").string)
                                    .foregroundColor(.blue)
                                Spacer()
                                if !selectedImages.isEmpty {
                                    Text("(\(selectedImages.count))")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if !selectedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                        PhotoPreviewCard(
                                            image: image,
                                            onRemove: {
                                                selectedImages.remove(at: index)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 0)
                            }
                        }
                        
                        Text(L10n(key: "jobForm.addPhotosHint").string)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
            }
            .navigationTitle(L10n.Action.postJob.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.Common.cancel.string) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleSubmit) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text(L10n.Common.submit.string)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    locationSearchService: locationSearchService,
                    selectedLocationName: $selectedLocationName,
                    selectedCoordinate: $selectedCoordinate
                )
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerView(
                    selectedImages: $selectedImages,
                    isPresented: $showPhotoPicker,
                    maxPhotos: 5,
                    title: L10n(key: "job.requirements").string
                )
            }
            .alert(L10n.Common.error.string, isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button(L10n(key: "common.ok").string, role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && !selectedLocationName.isEmpty && selectedCoordinate != nil
    }
    
    private func handleSubmit() {
        guard let userId = authViewModel.currentUser?.uid,
              let coordinate = selectedCoordinate else { return }

        isSubmitting = true
        errorMessage = nil

        let budgetValue = Double(budget)
        let job = Job(
            title: title,
            description: description,
            location: selectedLocationName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            datePosted: Date(),
            createdBy: userId,
            status: .open,
            category: selectedCategory,
            budget: budgetValue,
            photoURLs: nil
        )

        Task {
            do {
                let jobId = try await jobsRepo.create(job)

                if !selectedImages.isEmpty {
                    let urls = try await PhotoUploadService.shared.uploadJobRequirementPhotos(
                        jobId: jobId,
                        images: selectedImages
                    )
                    if !urls.isEmpty {
                        try await jobsRepo.attachPhotoURLs(jobId: jobId, urls: urls)
                    }
                }

                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = AppError(error).errorDescription
                }
            }
        }
    }
}

// MARK: - Location Search Service
class LocationSearchService: NSObject, ObservableObject {
    @Published var searchQuery = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []
    
    private let searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        searchCompleter.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 31.5, longitude: 34.75), // Center of Israel
            span: MKCoordinateSpan(latitudeDelta: 3.0, longitudeDelta: 3.0)
        )
    }
    
    func search(_ query: String) {
        searchQuery = query
        searchCompleter.queryFragment = query
    }
    
    func getCoordinate(for completion: MKLocalSearchCompletion, completionHandler: @escaping (CLLocationCoordinate2D?, String?) -> Void) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            if let error = error {
                print("Error getting coordinate: \(error.localizedDescription)")
                completionHandler(nil, nil)
                return
            }
            
            guard let mapItem = response?.mapItems.first else {
                completionHandler(nil, nil)
                return
            }
            
            let coordinate = mapItem.placemark.coordinate
            let name = mapItem.name ?? completion.title
            completionHandler(coordinate, name)
        }
    }
}

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }
}

// MARK: - Location Picker View
struct LocationPickerView: View {
    @ObservedObject var locationSearchService: LocationSearchService
    @Binding var selectedLocationName: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField(L10n(key: "jobForm.searchLocationPlaceholder").string, text: $searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: searchText) { _, newValue in
                            locationSearchService.search(newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Suggestions List
                if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text(L10n(key: "jobForm.searchLocationTitle").string)
                            .font(.headline)

                        Text(L10n(key: "jobForm.searchLocationSubtitle").string)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(locationSearchService.suggestions, id: \.self) { suggestion in
                        Button(action: {
                            selectLocation(suggestion)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.title)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text(suggestion.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(L10n(key: "jobForm.selectLocation").string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.Common.cancel.string) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func selectLocation(_ completion: MKLocalSearchCompletion) {
        locationSearchService.getCoordinate(for: completion) { coordinate, name in
            if let coordinate = coordinate, let name = name {
                selectedLocationName = name
                selectedCoordinate = coordinate
                dismiss()
            }
        }
    }
}

#Preview {
    JobFormView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
        .environmentObject(JobsRepository.shared)
}
