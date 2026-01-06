//
//  LocationManager.swift
//  Run
//
//  Created by Artem Menshikov on 04.01.2026.
//

import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var locations: [CLLocation] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        if !isTracking {
            locationManager.stopUpdatingLocation()
        }
    }
    
    func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        isTracking = true
        locations.removeAll()
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations newLocations: [CLLocation]) {
        guard let newLocation = newLocations.last else { return }
        
        if isTracking {
            locations.append(contentsOf: newLocations)
        }
        
        // Always keep the last location for map display
        if locations.isEmpty {
            locations.append(newLocation)
        } else if !isTracking {
            // Update last location when not tracking a run
            locations = [newLocation]
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func calculateDistance() -> Double {
        guard locations.count > 1 else { return 0.0 }
        var totalDistance: Double = 0.0
        for i in 1..<locations.count {
            totalDistance += locations[i].distance(from: locations[i-1])
        }
        return totalDistance / 1000.0 // Convert to kilometers
    }
    
    func getCoordinateData() -> Data? {
        let coordinates = locations.map { [$0.coordinate.latitude, $0.coordinate.longitude] }
        return try? JSONEncoder().encode(coordinates)
    }
}

