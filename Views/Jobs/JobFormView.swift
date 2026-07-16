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
    @EnvironmentObject var localization: LocalizationManager
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
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.xl) {
                        detailsSection

                        photosSection

                        if let errorMessage = errorMessage {
                            DSBanner(kind: .error, message: errorMessage)
                        }
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, DS.Space.m)
                    .padding(.bottom, DS.Space.xxl)
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
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            DSTextField(
                label: L10n.Field.title.string,
                systemImage: "textformat",
                text: $title,
                placeholder: L10n.Field.title.string,
                autocapitalization: .sentences
            )

            DSTextEditor(
                label: L10n.Field.description.string,
                text: $description,
                placeholder: L10n.Field.description.string
            )

            locationField

            categoryField

            DSTextField(
                label: L10n.Field.budget.string + " (" + L10n.Common.optional.string + ")",
                systemImage: "banknote",
                text: $budget,
                placeholder: "0",
                keyboard: .decimalPad
            )
        }
    }

    private var locationField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.Field.location.string)
                .font(.dsCaptionBold)
                .foregroundStyle(Color.inkMuted)

            Button(action: { showLocationPicker = true }) {
                HStack(spacing: DS.Space.m) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(selectedLocationName.isEmpty ? Color.inkFaint : Color.brand)
                        .frame(width: 20)

                    Text(selectedLocationName.isEmpty ? L10n(key: "jobForm.selectLocation").string : selectedLocationName)
                        .font(.dsBody)
                        .foregroundStyle(selectedLocationName.isEmpty ? Color.inkFaint : Color.ink)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.forward")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.inkFaint)
                        .flipsForRightToLeftLayoutDirection(true)
                }
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
            }
            .buttonStyle(DSPressableStyle())
        }
    }

    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.Field.category.string)
                .font(.dsCaptionBold)
                .foregroundStyle(Color.inkMuted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Space.s) {
                    ForEach(JobCategory.allCases, id: \.self) { category in
                        DSChip(
                            title: category.localized,
                            systemImage: category.symbol,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n(key: "jobForm.requirementsPhotos").string)
                .font(.dsCaptionBold)
                .foregroundStyle(Color.inkMuted)

            VStack(alignment: .leading, spacing: DS.Space.m) {
                Button(action: { showPhotoPicker = true }) {
                    HStack(spacing: DS.Space.s) {
                        Image(systemName: "photo.badge.plus")
                        Text(L10n(key: "jobForm.addPhotos").string)
                        if !selectedImages.isEmpty {
                            Text("(\(selectedImages.count))")
                        }
                    }
                }
                .buttonStyle(DSTonalButtonStyle())

                if !selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Space.m) {
                            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                PhotoPreviewCard(
                                    image: image,
                                    onRemove: {
                                        selectedImages.remove(at: index)
                                    }
                                )
                            }
                        }
                        .padding(.top, 6)
                        .padding(.trailing, 6)
                    }
                }

                Text(L10n(key: "jobForm.addPhotosHint").string)
                    .font(.dsCaption)
                    .foregroundStyle(Color.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard()
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
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    DSSearchBar(text: $searchText, placeholder: L10n(key: "jobForm.searchLocationPlaceholder").string)
                        .padding(.horizontal, DS.Space.screen)
                        .padding(.vertical, DS.Space.m)
                        .onChange(of: searchText) { _, newValue in
                            locationSearchService.search(newValue)
                        }

                    if searchText.isEmpty {
                        DSEmptyState(
                            systemImage: "map.fill",
                            title: L10n(key: "jobForm.searchLocationTitle").string,
                            message: L10n(key: "jobForm.searchLocationSubtitle").string
                        )

                        Spacer()
                    } else {
                        // Suggestions List
                        ScrollView {
                            VStack(spacing: DS.Space.s) {
                                ForEach(locationSearchService.suggestions, id: \.self) { suggestion in
                                    Button(action: {
                                        selectLocation(suggestion)
                                    }) {
                                        HStack(spacing: DS.Space.m) {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.system(size: 17, weight: .medium))
                                                .foregroundStyle(Color.brand)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(suggestion.title)
                                                    .font(.dsBody)
                                                    .foregroundStyle(Color.ink)
                                                    .multilineTextAlignment(.leading)

                                                if !suggestion.subtitle.isEmpty {
                                                    Text(suggestion.subtitle)
                                                        .font(.dsCaption)
                                                        .foregroundStyle(Color.inkMuted)
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }

                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .dsCard(padding: DS.Space.m)
                                    }
                                    .buttonStyle(DSPressableStyle())
                                }
                            }
                            .padding(.horizontal, DS.Space.screen)
                            .padding(.bottom, DS.Space.xl)
                        }
                    }
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
