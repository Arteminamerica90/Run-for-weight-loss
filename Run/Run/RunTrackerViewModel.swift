//
//  RunTrackerViewModel.swift
//  Run
//
//  Created by Artem Menshikov on 04.01.2026.
//

import Foundation
import CoreData
import SwiftUI

class RunTrackerViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var distance: Double = 0.0
    @Published var duration: TimeInterval = 0
    @Published var startTime: Date?
    @Published var pausedTime: TimeInterval = 0
    @Published var pauseStartTime: Date?
    
    private var timer: Timer?
    let locationManager: LocationManager
    let viewContext: NSManagedObjectContext
    
    init(locationManager: LocationManager, viewContext: NSManagedObjectContext) {
        self.locationManager = locationManager
        self.viewContext = viewContext
    }
    
    func startRun() {
        isRunning = true
        isPaused = false
        startTime = Date()
        duration = 0
        distance = 0
        pausedTime = 0
        locationManager.startTracking()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            if !self.isPaused {
                let elapsed = Date().timeIntervalSince(startTime) - self.pausedTime
                self.duration = elapsed
                self.distance = self.locationManager.calculateDistance()
            }
        }
    }
    
    func pauseRun() {
        isPaused = true
        pauseStartTime = Date()
        locationManager.stopTracking()
    }
    
    func resumeRun() {
        guard let pauseStart = pauseStartTime else { return }
        isPaused = false
        pausedTime += Date().timeIntervalSince(pauseStart)
        pauseStartTime = nil
        locationManager.startTracking()
    }
    
    func stopRun() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        locationManager.stopTracking()
        saveRun()
    }
    
    private func saveRun() {
        guard let startTime = startTime else { return }
        
        // Сохраняем пробежку даже если дистанция 0, если была хотя бы минимальная длительность
        guard duration > 0 else { return }
        
        let run = Run(context: viewContext)
        run.timestamp = startTime
        run.distance = distance
        run.duration = duration
        run.coordinates = locationManager.getCoordinateData()
        run.averagePace = duration > 0 && distance > 0 ? (duration / 60.0) / distance : 0.0 // minutes per km
        run.calories = calculateCalories(distance: distance, duration: duration)
        
        do {
            try viewContext.save()
            print("Run saved successfully: distance=\(distance), duration=\(duration)")
        } catch {
            print("Error saving run: \(error)")
        }
    }
    
    private func calculateCalories(distance: Double, duration: TimeInterval) -> Double {
        // Rough estimate: 60 calories per km for average person
        return distance * 60.0
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func formatDistance(_ distance: Double) -> String {
        return String(format: "%.2f", distance)
    }
}

