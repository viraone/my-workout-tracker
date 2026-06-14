import Foundation
import CoreLocation
import Observation

/// A MainActor-isolated LocationManager designed to safely retrieve GPS coordinates
/// for fetching local WeatherKit forecasts. Conforms to Sendable.
@MainActor
@Observable
public final class LocationManager: NSObject, CLLocationManagerDelegate, Sendable {
    public enum PermissionStatus: Equatable, Sendable {
        case notDetermined
        case authorized
        case denied
    }
    
    private let locationManager = CLLocationManager()
    
    public var lastLocation: CLLocation? = nil
    
    // Store permission status explicitly so SwiftUI's Observable detects modifications
    public var permissionStatus: PermissionStatus = .notDetermined
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        updatePermissionStatus()
    }
    
    private func updatePermissionStatus() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            self.permissionStatus = .notDetermined
        case .authorizedAlways, .authorizedWhenInUse:
            self.permissionStatus = .authorized
        case .restricted, .denied:
            self.permissionStatus = .denied
        @unknown default:
            self.permissionStatus = .denied
        }
    }
    
    /// Requests Location Services authorizations
    public func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Begins fetching location, updating asynchronously
    public func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    /// Stops updating location to save battery
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.lastLocation = location
        }
    }
    
    public nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.updatePermissionStatus()
            if self.permissionStatus == .authorized {
                self.startUpdatingLocation()
            }
        }
    }
}
