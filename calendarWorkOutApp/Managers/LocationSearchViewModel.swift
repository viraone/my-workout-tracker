import Foundation
import MapKit
import Observation

/// A MainActor-isolated ViewModel that manages MapKit's MKLocalSearchCompleter
/// to provide real-time address autocomplete suggestions. Conforms to Sendable.
@MainActor
@Observable
public final class LocationSearchViewModel: NSObject, MKLocalSearchCompleterDelegate, Sendable {
    private let completer = MKLocalSearchCompleter()
    
    public var queryFragment: String = "" {
        didSet {
            completer.queryFragment = queryFragment
        }
    }
    
    public var results: [MKLocalSearchCompletion] = []
    
    public override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
        
        // Define bounding box for the Pacific Northwest (Greater Seattle / Puget Sound area)
        // Seattle: Lat 47.6062, Lon -122.3321. Box covers WA/OR region comfortably.
        let center = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
        let span = MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        completer.region = MKCoordinateRegion(center: center, span: span)
    }
    
    public init(isGlobal: Bool) {
        super.init()
        completer.delegate = self
        if isGlobal {
            completer.resultTypes = [.pointOfInterest, .address, .query]
            // Let the region default to global/device locale bias
        } else {
            completer.resultTypes = [.pointOfInterest, .address]
            let center = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
            let span = MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
            completer.region = MKCoordinateRegion(center: center, span: span)
        }
    }
    
    /// Clears any cached results
    public func clearResults() {
        self.results = []
    }
    
    // MARK: - MKLocalSearchCompleterDelegate Methods
    
    public nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            // Filter results to only valid address locations or venues
            self.results = completer.results
        }
    }
    
    public nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("MapKit LocalSearchCompleter failed with error: \(error.localizedDescription)")
    }
}
