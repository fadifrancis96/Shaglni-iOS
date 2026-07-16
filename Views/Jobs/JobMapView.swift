//
//  JobMapView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI
import MapKit

struct JobMapView: View {
    let jobs: [Job]
    @Environment(\.dismiss) var dismiss
    @State private var selectedJob: Job?
    @State private var position: MapCameraPosition = .automatic
    @State private var mapStyle: MapStyle = .standard

    private var jobsWithCoordinates: [Job] {
        jobs.filter { $0.coordinate != nil }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapView
                selectedJobCard
                mapStyleButton
            }
            .navigationTitle("Jobs Map (\(jobs.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.done.string) {
                        dismiss()
                    }
                    .foregroundStyle(Color.brand)
                }
            }
            .onChange(of: selectedJob) { oldValue, newValue in
                if newValue != nil {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
        }
    }

    private var mapView: some View {
        Map(position: $position) {
            ForEach(jobsWithCoordinates) { job in
                if let coordinate = job.coordinate {
                    Annotation(job.title, coordinate: coordinate) {
                        JobMarkerView(job: job, isSelected: selectedJob?.id == job.id)
                            .onTapGesture {
                                selectJob(job, at: coordinate)
                            }
                    }
                }
            }
        }
        .mapStyle(mapStyle)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onTapGesture {
            // Don't dismiss on map tap - only dismiss via X button
        }
    }

    private func selectJob(_ job: Job, at coordinate: CLLocationCoordinate2D) {
        // If tapping the same job, don't do anything
        if selectedJob?.id == job.id {
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedJob = job
            position = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }

    @ViewBuilder
    private var selectedJobCard: some View {
        if let job = selectedJob {
            jobCardView(for: job)
        }
    }

    private func jobCardView(for job: Job) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.divider)
                .frame(width: 40, height: 5)
                .padding(.top, DS.Space.s)

            VStack(alignment: .leading, spacing: DS.Space.m) {
                jobHeader(for: job)

                if let category = job.category {
                    DSTag(
                        title: category.localized,
                        systemImage: category.symbol,
                        tint: category.tint,
                        background: category.tint.opacity(0.14)
                    )
                }

                Text(job.description)
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                if let budget = job.budget {
                    budgetView(budget)
                }

                viewDetailsButton(for: job)
            }
            .padding(DS.Space.l)
        }
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(Color.divider, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
        .padding(.horizontal, DS.Space.screen)
        .padding(.bottom, DS.Space.s)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func jobHeader(for job: Job) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .font(.dsTitle2)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.brand)
                    Text(job.location)
                        .font(.dsCaption)
                        .foregroundStyle(Color.inkMuted)
                }
            }

            Spacer()

            Button {
                withAnimation {
                    selectedJob = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.inkFaint)
            }
        }
    }

    private func budgetView(_ budget: Double) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(L10n.Field.budget.string)
                .font(.dsCaption)
                .foregroundStyle(Color.inkMuted)
            Spacer()
            DSPriceText(amount: budget)
        }
        .dsInset()
    }

    private func viewDetailsButton(for job: Job) -> some View {
        NavigationLink(destination: JobDetailView(job: job)) {
            HStack(spacing: DS.Space.s) {
                Text("View Full Details")
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .flipsForRightToLeftLayoutDirection(true)
            }
        }
        .buttonStyle(DSPrimaryButtonStyle())
    }

    @ViewBuilder
    private var mapStyleButton: some View {
        if selectedJob == nil {
            VStack {
                HStack {
                    Spacer()
                    Menu {
                        Button(action: { mapStyle = .standard }) {
                            Label("Standard", systemImage: "map")
                        }
                        Button(action: { mapStyle = .hybrid }) {
                            Label("Satellite", systemImage: "globe")
                        }
                    } label: {
                        Image(systemName: "map.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.onBrand)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.brand))
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(DS.Space.l)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Custom Job Marker View
private struct JobMarkerView: View {
    let job: Job
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.brand.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .scaleEffect(isSelected ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isSelected)
                }

                Circle()
                    .fill(markerColor)
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                    .overlay(Circle().strokeBorder(Color.surface, lineWidth: 2))
                    .shadow(color: markerColor.opacity(0.5), radius: isSelected ? 8 : 4)

                Image(systemName: markerSymbol)
                    .font(.system(size: isSelected ? 20 : 16, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.onBrand : Color.white)
            }

            Triangle()
                .fill(markerColor)
                .frame(width: 12, height: 8)
                .offset(y: -4)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }

    private var markerColor: Color {
        isSelected ? Color.brand : (job.category?.tint ?? .brand)
    }

    private var markerSymbol: String {
        job.category?.symbol ?? "briefcase.fill"
    }
}

// Triangle shape for marker pointer
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    JobMapView(jobs: [
        Job(
            id: "1",
            title: "Plumbing Work",
            description: "Fix kitchen pipes",
            location: "Tel Aviv",
            latitude: 32.0853,
            longitude: 34.7818,
            datePosted: Date(),
            createdBy: "user1",
            status: .open,
            category: .plumbing
        )
    ])
}
