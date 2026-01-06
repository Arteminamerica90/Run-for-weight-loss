//
//  ActiveRunView.swift
//  Run
//
//  Created by Artem Menshikov on 04.01.2026.
//

import SwiftUI
import MapKit

struct ActiveRunView: View {
    @ObservedObject var viewModel: RunTrackerViewModel
    @ObservedObject var locationManager: LocationManager
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        ZStack {
                Map(coordinateRegion: $region, annotationItems: locationManager.locations.enumerated().map { index, location in
                    RunLocation(id: index, coordinate: location.coordinate)
                }) { location in
                    MapMarker(coordinate: location.coordinate, tint: .blue)
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Stats Card
                    VStack(spacing: 20) {
                        HStack(spacing: 40) {
                            VStack {
                                Text(viewModel.formatTime(viewModel.duration))
                                    .font(.system(size: 32, weight: .bold))
                                Text("Время")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(viewModel.formatDistance(viewModel.distance))")
                                    .font(.system(size: 32, weight: .bold))
                                Text("км")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(viewModel.distance > 0 ? String(format: "%.1f", (viewModel.duration / 60.0) / viewModel.distance) : "0.0")
                                    .font(.system(size: 32, weight: .bold))
                                Text("мин/км")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        
                        // Control Buttons
                        HStack(spacing: 20) {
                            if viewModel.isRunning {
                                Button(action: {
                                    viewModel.stopRun()
                                }) {
                                    HStack {
                                        Image(systemName: "stop.fill")
                                        Text("Завершить")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                                }
                            } else {
                                Button(action: {
                                    viewModel.startRun()
                                }) {
                                    HStack {
                                        Image(systemName: "play.fill")
                                        Text("Старт")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding()
                }
            }
            .navigationTitle("Пробежка")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !viewModel.isRunning {
                    viewModel.startRun()
                }
                updateRegion()
            }
            .onChange(of: locationManager.locations.count) { _ in
                updateRegion()
            }
            .onDisappear {
                if viewModel.isRunning {
                    viewModel.stopRun()
                }
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

struct RunLocation: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
}

