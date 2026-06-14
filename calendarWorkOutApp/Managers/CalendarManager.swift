import Foundation
import EventKit
import Observation

/// A manager responsible for EventKit calendar access and event fetching, isolated to the `@MainActor`.
@MainActor
@Observable
public final class CalendarManager: Sendable {
    public enum CalendarError: LocalizedError {
        case accessDenied
        case fetchFailed(String)
        
        public var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Full calendar access was denied by the user."
            case .fetchFailed(let details):
                return "Failed to fetch events: \(details)"
            }
        }
    }
    
    public enum PermissionStatus: Equatable, Sendable {
        case notDetermined
        case authorized
        case denied
    }
    
    public let eventStore = EKEventStore()
    
    public var permissionStatus: PermissionStatus {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            return .notDetermined
        case .fullAccess:
            return .authorized
        case .writeOnly, .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }
    
    public init() {}
    
    /// Requests full calendar access using modern iOS 17+ Swift 6 concurrency patterns.
    /// - Returns: A boolean indicating whether access was granted.
    public func requestCalendarAccess() async throws -> Bool {
        switch permissionStatus {
        case .authorized:
            return true
        case .denied:
            throw CalendarError.accessDenied
        case .notDetermined:
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                return granted
            } catch {
                throw CalendarError.accessDenied
            }
        }
    }
    
    /// Fetches all calendar events for a specific date, filtering out all-day events if necessary, sorted by start date.
    /// - Parameter date: The date for which to fetch events.
    /// - Returns: A sorted list of standard `EKEvent` calendar items.
    public func fetchEvents(for date: Date) async throws -> [EKEvent] {
        guard permissionStatus == .authorized else {
            throw CalendarError.accessDenied
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw CalendarError.fetchFailed("Could not calculate end of day boundary.")
        }
        
        // Query events across all readable user calendars
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: calendars)
        
        // Fetch events in a background-compatible way, then return them sorted
        let events = eventStore.events(matching: predicate)
        return events.sorted { $0.startDate < $1.startDate }
    }
}
