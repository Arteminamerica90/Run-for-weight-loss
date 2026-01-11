//
//  HomeView.swift
//  Run
//
//  Created by Artem Menshikov on 04.01.2026.
//

import SwiftUI
import CoreData
import MapKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static let neomorphicBase = Color(hex: "9EFFF7")
    static let neomorphicLight = Color(hex: "B8FFF8")
    static let neomorphicDark = Color(hex: "84E5E0")
}

extension View {
    func neomorphicStyle(isPressed: Bool = false) -> some View {
        self
            .background(
                ZStack {
                    // Base gradient
                    LinearGradient(
                        gradient: Gradient(colors: [Color.neomorphicLight, Color.neomorphicBase]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Shadow overlay for depth
                    if !isPressed {
                        // Light shadow (top-left)
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]),
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .blur(radius: 20)
                            .offset(x: -10, y: -10)
                        
                        // Dark shadow (bottom-right)
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.clear, Color.neomorphicDark.opacity(0.3)]),
                                    startPoint: .center,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: 20)
                            .offset(x: 10, y: 10)
                    } else {
                        // Inverted shadows for pressed state
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.neomorphicDark.opacity(0.3), Color.clear]),
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .blur(radius: 15)
                            .offset(x: 5, y: 5)
                    }
                }
            )
            .shadow(color: Color.neomorphicDark.opacity(0.3), radius: isPressed ? 5 : 15, x: isPressed ? 2 : 8, y: isPressed ? 2 : 8)
            .shadow(color: Color.white.opacity(0.5), radius: isPressed ? 5 : 15, x: isPressed ? -2 : -8, y: isPressed ? -2 : -8)
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: RunTrackerViewModel
    @ObservedObject var locationManager: LocationManager
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Run.timestamp, ascending: false)],
        animation: .default)
    private var runs: FetchedResults<Run>
    
    @State private var goalKm: Double = 50.0 // Monthly goal in km
    @AppStorage("monthlyGoal") private var storedGoal: Double = 50.0
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var lastRunCoordinates: [[Double]] = []
    
    private var currentRunCoordinates: [[Double]] {
        if viewModel.isRunning {
            return locationManager.locations.map { [$0.coordinate.latitude, $0.coordinate.longitude] }
        }
        // Show last run if available, otherwise show current location
        if lastRunCoordinates.isEmpty, let currentLocation = locationManager.locations.last {
            return [[currentLocation.coordinate.latitude, currentLocation.coordinate.longitude]]
        }
        return lastRunCoordinates
    }
    
    private var currentRunDistance: Double {
        if viewModel.isRunning {
            return viewModel.distance
        }
        return runs.first?.distance ?? 0.0
    }
    
    private var lastRunDistance: Double {
        return runs.first?.distance ?? 0.0
    }
    
    private var runProgress: Double {
        // Progress relative to 5 km goal for the run
        let targetDistance: Double = 5.0
        let distance = viewModel.isRunning ? viewModel.distance : (runs.first?.distance ?? 0.0)
        return min(distance / targetDistance, 1.0)
    }
    
    private let motivationalMessages = [
        "Every run makes you stronger!",
        "Get up and run towards your goals!",
        "Today is the perfect day for a run!",
        "Run not away from problems, but towards your dreams!",
        "One step at a time - and you'll reach the top!",
        "Sweat today - strength tomorrow!",
        "Your body can do anything - your mind just needs to be convinced!",
        "Running is freedom, feel it!",
        "Don't wait for the perfect moment - start right now!",
        "Every kilometer is a victory over yourself!",
        "Run forward, leaving doubts behind!",
        "Your legs may get tired, but your heart never will!",
        "A run is the best way to start the day!",
        "Don't stop until you're proud of yourself!",
        "Running changes not only the body, but also the mind!",
        "Take a step towards a better version of yourself!",
        "Remember: even champions start with the first step!",
        "A run is your time, your space!",
        "Run because you can!",
        "Every run brings you closer to your goal!"
    ]
    
    private var motivationalMessage: String {
        if runs.count == 0 {
            return motivationalMessages.randomElement() ?? "Start your first run!"
        }
        return "Run"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map Background - Full Screen
                Map(coordinateRegion: $region, annotationItems: currentRunCoordinates.enumerated().map { index, coord in
                    RunMapLocation(id: index, coordinate: CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1]))
                }) { location in
                    MapMarker(coordinate: location.coordinate, tint: Color(hex: "7DFCF2"))
                }
                .ignoresSafeArea()
                
                // Content Overlay
                ScrollView {
                    VStack(spacing: 30) {
                        // Progress Circle at Top
                        VStack(spacing: 10) {
                            Text(viewModel.isRunning ? "Current Run" : motivationalMessage)
                                .font(.headline)
                                .foregroundColor(Color(hex: "C393FF"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                                .zIndex(20)
                            
                            ZStack {
                                // Neomorphic background circle
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.neomorphicLight, Color.neomorphicBase]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 180, height: 180)
                                    .shadow(color: Color.neomorphicDark.opacity(0.4), radius: 15, x: 8, y: 8)
                                    .shadow(color: Color.white.opacity(0.6), radius: 15, x: -8, y: -8)
                                    .opacity(0.5)
                                
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.white.opacity(0.6), Color.neomorphicDark.opacity(0.3)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 18
                                    )
                                    .frame(width: 180, height: 180)
                                    .opacity(0.5)
                                
                                // Progress circle
                                Circle()
                                    .trim(from: 0, to: runProgress)
                                    .stroke(
                                        Color(hex: "66FFDB"),
                                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                                    )
                                    .frame(width: 180, height: 180)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.spring(response: 0.5), value: runProgress)
                                
                                VStack(spacing: 3) {
                                    Text("\(String(format: "%.2f", currentRunDistance))")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(Color(hex: "C393FF"))
                                    Text("km")
                                        .font(.subheadline)
                                        .foregroundColor(Color(hex: "C393FF").opacity(0.9))
                                }
                                .zIndex(20)
                            }
                        }
                        .padding(.top, 5)
                        
                        Spacer()
                            .frame(height: UIScreen.main.bounds.height * 0.2 - 15)
                        
                        // Stats and Button
                        VStack(spacing: 20) {
                            HStack(spacing: 30) {
                                VStack {
                                    Text(viewModel.formatTime(viewModel.duration))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(Color(hex: "C393FF"))
                                    Text("Time")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack {
                                    Text(viewModel.distance > 0 ? String(format: "%.1f", (viewModel.duration / 60.0) / viewModel.distance) : "0.0")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(Color(hex: "C393FF"))
                                    Text("min/km")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack {
                                    Text(formatSpeed())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(Color(hex: "C393FF"))
                                    Text("km/h")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                            
                            // Control Buttons
                            if viewModel.isRunning {
                                HStack(spacing: 15) {
                                    // Pause/Resume Button
                                    Button(action: {
                                        if viewModel.isPaused {
                                            viewModel.resumeRun()
                                        } else {
                                            viewModel.pauseRun()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                                            Text(viewModel.isPaused ? "Resume" : "Pause")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(viewModel.isPaused ? Color.green : Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                    }
                                    
                                    // Stop Button
                                    Button(action: {
                                        viewModel.stopRun()
                                    }) {
                                        HStack {
                                            Image(systemName: "stop.fill")
                                            Text("Finish")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                    }
                                }
                            } else {
                                Button(action: {
                                    viewModel.startRun()
                                }) {
                                    HStack {
                                        Image(systemName: "play.fill")
                                        Text("Start Run")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "66FFDB"))
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Overall Stats Section
                        VStack(spacing: 15) {
                            HStack {
                                Spacer()
                                Text("Overall Statistics")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            
                            HStack(spacing: 15) {
                                StatBox(title: "Total Runs", value: "\(runs.count)", icon: "figure.run", color: .blue)
                                StatBox(title: "Total km", value: String(format: "%.1f", totalDistance), icon: "map", color: .green)
                            }
                            
                            HStack(spacing: 15) {
                                StatBox(title: "Total Time", value: formatTotalTime(), icon: "clock", color: .orange)
                                StatBox(title: "Avg Pace", value: averagePace > 0 ? String(format: "%.1f", averagePace) : "—", icon: "speedometer", color: .purple)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        // Gamification - Achievements
                        VStack(spacing: 20) {
                            HStack {
                                Spacer()
                                Text("Ranks and Achievements")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            
                            AchievementRow(
                                title: "First Run",
                                icon: "star.fill",
                                unlocked: runs.count >= 1,
                                description: "Complete your first run"
                            )
                            
                            AchievementRow(
                                title: "Week of Running",
                                icon: "calendar",
                                unlocked: hasWeekStreak(),
                                description: "Run every day for a week"
                            )
                            
                            AchievementRow(
                                title: "Month of Running",
                                icon: "calendar.badge.clock",
                                unlocked: hasMonthStreak(),
                                description: "Run regularly for a month"
                            )
                            
                            AchievementRow(
                                title: "Year of Running",
                                icon: "trophy.fill",
                                unlocked: hasYearStreak(),
                                description: "Run all year"
                            )
                            
                            AchievementRow(
                                title: "100 km",
                                icon: "figure.run.circle.fill",
                                unlocked: totalDistance >= 100,
                                description: "Run 100 kilometers"
                            )
                            
                            AchievementRow(
                                title: "300 km",
                                icon: "figure.run.circle.fill",
                                unlocked: totalDistance >= 300,
                                description: "Run 300 kilometers"
                            )
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Run Tracker")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            goalKm = storedGoal
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()
            } else {
                locationManager.startLocationUpdates()
            }
            loadLastRunCoordinates()
            updateMapRegion()
        }
        .onDisappear {
            locationManager.stopLocationUpdates()
        }
        .onChange(of: runs.count) { _ in
            if !viewModel.isRunning {
                loadLastRunCoordinates()
                updateMapRegion()
            }
        }
        .onChange(of: locationManager.locations.count) { _ in
            if viewModel.isRunning {
                updateMapRegionForCurrentRun()
            } else if let lastLocation = locationManager.locations.last {
                // Update map to current location when not running
                region = MKCoordinateRegion(
                    center: lastLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
        .onChange(of: locationManager.authorizationStatus) { status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                locationManager.startLocationUpdates()
            }
        }
    }
    
    private var totalDistance: Double {
        runs.reduce(0) { $0 + $1.distance }
    }
    
    private var totalDuration: TimeInterval {
        runs.reduce(0) { $0 + $1.duration }
    }
    
    private var averagePace: Double {
        guard totalDistance > 0 else { return 0 }
        return (totalDuration / 60.0) / totalDistance
    }
    
    private var last7Days: [DayStat] {
        let calendar = Calendar.current
        let now = Date()
        var days: [DayStat] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let dayRuns = runs.filter { run in
                guard let timestamp = run.timestamp else { return false }
                return timestamp >= startOfDay && timestamp < endOfDay
            }
            
            let distance = dayRuns.reduce(0.0) { $0 + $1.distance }
            let duration = dayRuns.reduce(0.0) { $0 + $1.duration }
            
            days.append(DayStat(date: date, distance: distance, duration: duration, count: dayRuns.count))
        }
        
        return days.sorted { $0.date > $1.date }
    }
    
    private func formatTotalTime() -> String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration) / 60 % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private func formatSpeed() -> String {
        guard viewModel.duration > 0 && viewModel.distance > 0 else { return "0.0" }
        let speedKmh = (viewModel.distance / viewModel.duration) * 3600.0
        return String(format: "%.1f", speedKmh)
    }
    
    private func hasWeekStreak() -> Bool {
        guard runs.count >= 7 else { return false }
        let calendar = Calendar.current
        let now = Date()
        var daysWithRuns = Set<Int>()
        
        for run in runs.prefix(30) {
            if let date = run.timestamp {
                let daysAgo = calendar.dateComponents([.day], from: date, to: now).day ?? 0
                if daysAgo < 7 {
                    daysWithRuns.insert(daysAgo)
                }
            }
        }
        return daysWithRuns.count >= 7
    }
    
    private func hasMonthStreak() -> Bool {
        guard runs.count >= 12 else { return false }
        let calendar = Calendar.current
        let now = Date()
        var weeksWithRuns = Set<Int>()
        
        for run in runs.prefix(50) {
            if let date = run.timestamp {
                let daysAgo = calendar.dateComponents([.day], from: date, to: now).day ?? 0
                if daysAgo < 30 {
                    let weekAgo = daysAgo / 7
                    weeksWithRuns.insert(weekAgo)
                }
            }
        }
        return weeksWithRuns.count >= 4
    }
    
    private func hasYearStreak() -> Bool {
        guard runs.count >= 52 else { return false }
        let calendar = Calendar.current
        let now = Date()
        var monthsWithRuns = Set<Int>()
        
        for run in runs {
            if let date = run.timestamp {
                let monthsAgo = calendar.dateComponents([.month], from: date, to: now).month ?? 0
                if monthsAgo < 12 {
                    monthsWithRuns.insert(monthsAgo)
                }
            }
        }
        return monthsWithRuns.count >= 12
    }
    
    private func loadLastRunCoordinates() {
        guard let lastRun = runs.first, let data = lastRun.coordinates else {
            lastRunCoordinates = []
            return
        }
        if let coords = try? JSONDecoder().decode([[Double]].self, from: data) {
            lastRunCoordinates = coords
        } else {
            lastRunCoordinates = []
        }
    }
    
    private func updateMapRegion() {
        if let firstCoord = lastRunCoordinates.first {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: firstCoord[0], longitude: firstCoord[1]),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        } else if let currentLocation = locationManager.locations.last {
            region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    private func updateMapRegionForCurrentRun() {
        guard let lastLocation = locationManager.locations.last else { return }
        region = MKCoordinateRegion(
            center: lastLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

struct DayStat {
    let date: Date
    let distance: Double
    let duration: TimeInterval
    let count: Int
}

struct DayStatRow: View {
    let day: DayStat
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(day.date, style: .date)
                    .font(.headline)
                Text(day.date, format: .dateTime.weekday(.wide))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if day.count > 0 {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(String(format: "%.2f", day.distance)) km")
                        .fontWeight(.semibold)
                    Text("\(day.count) runs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No runs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(day.count > 0 ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(10)
    }
}

struct AchievementRow: View {
    let title: String
    let icon: String
    let unlocked: Bool
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(unlocked ? Color(hex: "7DFCF2").opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(unlocked ? Color(hex: "7DFCF2") : .gray)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(unlocked ? .primary : .secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "7DFCF2"))
                    .font(.title2)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray.opacity(0.5))
                    .font(.title3)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

