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
            .navigationTitle(L10n(key: "jobMap.title").format(jobs.count))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.done.string) {
                        dismiss()
                    }
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
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                jobHeader(for: job)
                
                if let category = job.category {
                    categoryBadge(category)
                }
                
                Text(job.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                if let budget = job.budget {
                    budgetView(budget)
                }
                
                viewDetailsButton(for: job)
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 20, y: -5)
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private func jobHeader(for job: Job) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text(job.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    selectedJob = nil
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func categoryBadge(_ category: JobCategory) -> some View {
        HStack {
            Image(systemName: "tag.fill")
                .font(.caption)
            Text(category.localized)
                .font(.caption)
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
    
    private func budgetView(_ budget: Double) -> some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.green)
            Text("\(L10n.Field.budget.string): \(Money.string(budget))")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
    
    private func viewDetailsButton(for job: Job) -> some View {
        NavigationLink(destination: JobDetailView(job: job)) {
            HStack {
                Text(L10n.Action.viewDetails.string)
                    .font(.headline)
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var mapStyleButton: some View {
        if selectedJob == nil {
            VStack {
                HStack {
                    Spacer()
                    Menu {
                        Button(action: { mapStyle = .standard }) {
                            Label(L10n(key: "jobMap.styleStandard").string, systemImage: "map")
                        }
                        Button(action: { mapStyle = .hybrid }) {
                            Label(L10n(key: "jobMap.styleSatellite").string, systemImage: "globe")
                        }
                    } label: {
                        Image(systemName: "map.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Custom Job Marker View
struct JobMarkerView: View {
    let job: Job
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .scaleEffect(isSelected ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isSelected)
                }
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [categoryColor, categoryColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                    .shadow(color: categoryColor.opacity(0.5), radius: isSelected ? 8 : 4)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: isSelected ? 20 : 16))
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            
            Triangle()
                .fill(categoryColor)
                .frame(width: 12, height: 8)
                .offset(y: -4)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    private var categoryColor: Color {
        guard let category = job.category else { return .blue }
        switch category {
        case .plumbing: return .blue
        case .electrical: return .yellow
        case .carpentry: return .brown
        case .painting: return .purple
        case .cleaning: return .green
        case .landscaping: return .mint
        case .hvac: return .cyan
        case .roofing: return .red
        case .flooring: return .orange
        case .masonry: return .gray
        case .welding: return .indigo
        case .automotive: return .black
        case .appliance: return .teal
        case .pest: return .pink
        case .moving: return .blue
        case .other: return .secondary
        }
    }
    
    private var categoryIcon: String {
        guard let category = job.category else { return "briefcase.fill" }
        switch category {
        case .plumbing: return "wrench.and.screwdriver.fill"
        case .electrical: return "bolt.fill"
        case .carpentry: return "hammer.fill"
        case .painting: return "paintbrush.fill"
        case .cleaning: return "sparkles"
        case .landscaping: return "leaf.fill"
        case .hvac: return "fan.fill"
        case .roofing: return "house.fill"
        case .flooring: return "square.grid.3x3.fill"
        case .masonry: return "building.2.fill"
        case .welding: return "flame.fill"
        case .automotive: return "car.fill"
        case .appliance: return "refrigerator.fill"
        case .pest: return "ant.fill"
        case .moving: return "shippingbox.fill"
        case .other: return "briefcase.fill"
        }
    }
}

// Triangle shape for marker pointer
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// Helper extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
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