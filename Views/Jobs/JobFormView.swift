//
//  JobFormView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct JobFormView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
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
                Section(header: Text("Job Details")) {
                    TextField(localization.localized("title"), text: $title)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text(localization.localized("description"))
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
                            Text(localization.localized("location"))
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedLocationName.isEmpty {
                                Text("Select Location")
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
                    
                    Picker(localization.localized("category"), selection: $selectedCategory) {
                        Text("Select Category").tag(nil as JobCategory?)
                        ForEach(JobCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category as JobCategory?)
                        }
                    }
                    
                    TextField(localization.localized("budget") + " (Optional)", text: $budget)
                        .keyboardType(.decimalPad)
                }
                
                // Photo Upload Section
                Section(header: Text("Job Requirements Photos")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { showPhotoPicker = true }) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                    .foregroundColor(.blue)
                                Text("Add Photos")
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
                        
                        Text("Add photos to help contractors understand the job requirements")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(localization.localized("postJob"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localization.localized("cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleSubmit) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text(localization.localized("submit"))
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
                    title: "Job Requirements"
                )
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
        
        // First upload photos if any are selected
        if !selectedImages.isEmpty {
            uploadPhotosAndCreateJob(userId: userId, coordinate: coordinate, budgetValue: budgetValue)
        } else {
            createJob(userId: userId, coordinate: coordinate, budgetValue: budgetValue, photoURLs: [])
        }
    }
    
    private func uploadPhotosAndCreateJob(userId: String, coordinate: CLLocationCoordinate2D, budgetValue: Double?) {
        // First create the job to get the actual job ID
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
            photoURLs: [] // Will be updated after photo upload
        )
        
        FirestoreService.shared.createJob(job) { result in
            switch result {
            case .success(let jobId):
                // Now upload photos with the actual job ID
                PhotoUploadService.shared.uploadJobRequirementPhotos(jobId: jobId, photos: self.selectedImages) { photoResult in
                    switch photoResult {
                    case .success(let photoURLs):
                        // Update the job with photo URLs
                        self.updateJobWithPhotos(jobId: jobId, photoURLs: photoURLs)
                    case .failure(let error):
                        self.isSubmitting = false
                        self.errorMessage = "Failed to upload photos: \(error.localizedDescription)"
                    }
                }
            case .failure(let error):
                self.isSubmitting = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func updateJobWithPhotos(jobId: String, photoURLs: [String]) {
        // Update the job document with photo URLs
        let db = Firestore.firestore()
        db.collection("jobs").document(jobId).updateData([
            "photoURLs": photoURLs
        ]) { error in
            self.isSubmitting = false
            if let error = error {
                self.errorMessage = "Failed to update job with photos: \(error.localizedDescription)"
            } else {
                self.dismiss()
            }
        }
    }
    
    private func createJob(userId: String, coordinate: CLLocationCoordinate2D, budgetValue: Double?, photoURLs: [String]) {
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
            photoURLs: photoURLs
        )
        
        FirestoreService.shared.createJob(job) { result in
            
            self.isSubmitting = false
            
            switch result {
            case .success:
                self.dismiss()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
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
                    
                    TextField("Search for city, village, or address...", text: $searchText)
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
                        
                        Text("Search for any location in Israel")
                            .font(.headline)
                        
                        Text("Cities, villages, neighborhoods, and addresses")
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
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
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
        .environmentObject(LocalizationManager())
}
