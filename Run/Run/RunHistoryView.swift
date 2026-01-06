//
//  RunHistoryView.swift
//  Run
//
//  Created by Artem Menshikov on 04.01.2026.
//

import SwiftUI
import CoreData
import MapKit

struct RunHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: RunTrackerViewModel
    @EnvironmentObject var locationManager: LocationManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Run.timestamp, ascending: false)],
        animation: .default)
    private var runs: FetchedResults<Run>
    
    var body: some View {
        NavigationView {
            ZStack {
                // Decorative neomorphic circles with different radii
                NeomorphicCircle(radius: 120, offset: CGSize(width: -100, height: -200))
                    .allowsHitTesting(false)
                NeomorphicCircle(radius: 150, offset: CGSize(width: 150, height: 300))
                    .allowsHitTesting(false)
                NeomorphicCircle(radius: 100, offset: CGSize(width: -120, height: 400))
                    .allowsHitTesting(false)
                NeomorphicCircle(radius: 80, offset: CGSize(width: 200, height: 100))
                    .allowsHitTesting(false)
                NeomorphicCircle(radius: 110, offset: CGSize(width: -150, height: 600))
                    .allowsHitTesting(false)
                
                List {
                // Active Run Section
                if viewModel.isRunning {
                    Section(header: Text("Current Run")) {
                        NavigationLink(destination: ActiveRunDetailView(viewModel: viewModel, locationManager: locationManager)) {
                            ActiveRunRowView(viewModel: viewModel)
                        }
                        .listRowBackground(Color.white.opacity(0.5))
                    }
                }
                
                // Completed Runs Section
                Section(header: Text(viewModel.isRunning ? "Completed Runs" : "Run History")) {
                    ForEach(runs) { run in
                        NavigationLink(destination: RunDetailView(run: run)) {
                            RunRowView(run: run)
                        }
                        .listRowBackground(Color.white.opacity(0.5))
                    }
                }
            }
            .listStyle(.plain)
            .listRowSeparator(.hidden)
            .background(Color.clear)
            .onAppear {
                // Make List background transparent
                UITableView.appearance().backgroundColor = .clear
            }
            .navigationTitle("Run History")
            }
        }
    }
}

struct RunRowView: View {
    let run: Run
    @State private var coordinates: [[Double]] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        HStack(spacing: 12) {
            // Mini Map
            if !coordinates.isEmpty {
                Map(coordinateRegion: .constant(region), annotationItems: coordinates.enumerated().map { index, coord in
                    RunMapLocation(id: index, coordinate: CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1]))
                }) { location in
                    MapMarker(coordinate: location.coordinate, tint: Color(hex: "7DFCF2"))
                }
                .frame(width: 80, height: 80)
                .cornerRadius(10)
                .disabled(true)
            } else {
                // Placeholder if no coordinates
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "map")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(run.timestamp ?? Date(), style: .date)
                    .font(.headline)
                Text(run.timestamp ?? Date(), style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text("\(String(format: "%.2f", run.distance)) км")
                    .font(.headline)
                Text(formatDuration(run.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            loadCoordinates()
        }
    }
    
    private func loadCoordinates() {
        guard let data = run.coordinates else { return }
        if let coords = try? JSONDecoder().decode([[Double]].self, from: data) {
            coordinates = coords
            if let first = coords.first {
                // Calculate region to fit all coordinates
                let lats = coords.map { $0[0] }
                let lons = coords.map { $0[1] }
                let minLat = lats.min() ?? first[0]
                let maxLat = lats.max() ?? first[0]
                let minLon = lons.min() ?? first[1]
                let maxLon = lons.max() ?? first[1]
                
                let centerLat = (minLat + maxLat) / 2
                let centerLon = (minLon + maxLon) / 2
                let latDelta = max((maxLat - minLat) * 1.5, 0.01)
                let lonDelta = max((maxLon - minLon) * 1.5, 0.01)
                
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
                )
            }
        }
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct RunDetailView: View {
    let run: Run
    @State private var coordinates: [[Double]] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        ZStack {
            // Map as Background - Full Screen
            if !coordinates.isEmpty {
                Map(coordinateRegion: $region, annotationItems: coordinates.enumerated().map { index, coord in
                    RunMapLocation(id: index, coordinate: CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1]))
                }) { location in
                    MapMarker(coordinate: location.coordinate, tint: Color(hex: "7DFCF2"))
                }
                .ignoresSafeArea()
            } else {
                // Placeholder if no coordinates
                Color.gray.opacity(0.2)
                    .ignoresSafeArea()
            }
            
            // Stats Overlay
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 20)
                    
                    // Stats Card
                    VStack(spacing: 15) {
                        StatRow(label: "Distance", value: "\(String(format: "%.2f", run.distance)) km")
                        StatRow(label: "Time", value: formatTime(run.duration))
                        StatRow(label: "Pace", value: run.averagePace > 0 ? String(format: "%.1f min/km", run.averagePace) : "—")
                        StatRow(label: "Calories", value: "\(Int(run.calories)) kcal")
                        StatRow(label: "Date", value: run.timestamp?.formatted(date: .long, time: .shortened) ?? "—")
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.95))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Run Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCoordinates()
        }
    }
    
    private func loadCoordinates() {
        guard let data = run.coordinates else { return }
        if let coords = try? JSONDecoder().decode([[Double]].self, from: data) {
            coordinates = coords
            if !coords.isEmpty {
                // Calculate region to fit all coordinates
                let lats = coords.map { $0[0] }
                let lons = coords.map { $0[1] }
                let minLat = lats.min() ?? coords.first![0]
                let maxLat = lats.max() ?? coords.first![0]
                let minLon = lons.min() ?? coords.first![1]
                let maxLon = lons.max() ?? coords.first![1]
                
                let centerLat = (minLat + maxLat) / 2
                let centerLon = (minLon + maxLon) / 2
                let latDelta = max((maxLat - minLat) * 1.5, 0.01)
                let lonDelta = max((maxLon - minLon) * 1.5, 0.01)
                
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                    span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
                )
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct RunMapLocation: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 5)
    }
}

struct ActiveRunRowView: View {
    @ObservedObject var viewModel: RunTrackerViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("In Progress...")
                    .font(.headline)
                    .foregroundColor(Color(hex: "C393FF"))
                Text(Date(), style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text("\(String(format: "%.2f", viewModel.distance)) км")
                    .font(.headline)
                Text(viewModel.formatTime(viewModel.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

struct ActiveRunDetailView: View {
    @ObservedObject var viewModel: RunTrackerViewModel
    @ObservedObject var locationManager: LocationManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Map
                if !locationManager.locations.isEmpty {
                    Map(coordinateRegion: $region, annotationItems: locationManager.locations.enumerated().map { index, location in
                        RunMapLocation(id: index, coordinate: location.coordinate)
                    }) { location in
                        MapMarker(coordinate: location.coordinate, tint: Color(hex: "7DFCF2"))
                    }
                    .frame(height: 300)
                    .cornerRadius(15)
                    .padding()
                }
                
                // Stats
                VStack(spacing: 15) {
                    StatRow(label: "Distance", value: "\(String(format: "%.2f", viewModel.distance)) km")
                    StatRow(label: "Time", value: viewModel.formatTime(viewModel.duration))
                    StatRow(label: "Pace", value: viewModel.distance > 0 ? String(format: "%.1f min/km", (viewModel.duration / 60.0) / viewModel.distance) : "—")
                    StatRow(label: "Speed", value: viewModel.duration > 0 && viewModel.distance > 0 ? String(format: "%.1f km/h", (viewModel.distance / viewModel.duration) * 3600.0) : "—")
                    StatRow(label: "Status", value: "In Progress")
                }
                .padding()
            }
        }
        .navigationTitle("Current Run")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateRegion()
        }
        .onChange(of: locationManager.locations.count) { _ in
            updateRegion()
        }
    }
    
    private func updateRegion() {
        guard let lastLocation = locationManager.locations.last else { return }
        region = MKCoordinateRegion(
            center: lastLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
    }
}

