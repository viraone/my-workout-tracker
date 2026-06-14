import SwiftUI

/// An overlay component displayed when critical system permissions (Calendar or Location)
/// are not yet granted, keeping the application user-friendly and fully functional.
public struct PermissionsOverlayView: View {
    let calendarStatus: CalendarManager.PermissionStatus
    let locationStatus: LocationManager.PermissionStatus
    let onRequestCalendar: () -> Void
    let onRequestLocation: () -> Void
    
    public init(
        calendarStatus: CalendarManager.PermissionStatus,
        locationStatus: LocationManager.PermissionStatus,
        onRequestCalendar: @escaping () -> Void,
        onRequestLocation: @escaping () -> Void
    ) {
        self.calendarStatus = calendarStatus
        self.locationStatus = locationStatus
        self.onRequestCalendar = onRequestCalendar
        self.onRequestLocation = onRequestLocation
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("Permissions Needed")
                    .font(.title2)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                
                Text("To create the ultimate weather-integrated planner view, we need permission to connect with your calendar events and local weather coordinates.")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            
            VStack(spacing: 14) {
                // Calendar Access Request Button
                PermissionRow(
                    title: "Device Calendar Access",
                    description: "Required to sync and overlay calendar events.",
                    isGranted: calendarStatus == .authorized,
                    icon: "calendar",
                    actionButtonTitle: calendarStatus == .denied ? "Denied" : "Grant Access",
                    actionDisabled: calendarStatus == .denied,
                    action: onRequestCalendar
                )
                
                // Location Access Request Button
                PermissionRow(
                    title: "Hyper-Local Weather Location",
                    description: "Required to fetch high-detail local weather forecasts.",
                    isGranted: locationStatus == .authorized,
                    icon: "location.fill",
                    actionButtonTitle: locationStatus == .denied ? "Denied" : "Grant Access",
                    actionDisabled: locationStatus == .denied,
                    action: onRequestLocation
                )
            }
            .padding(.top, 6)
            
            if calendarStatus == .denied || locationStatus == .denied {
                Text("Note: Permissions are denied. Please enable them in iOS Settings > CalendarWeather.")
                    .font(.caption2)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .padding(10)
    }
}

private struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    let icon: String
    let actionButtonTitle: String
    let actionDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isGranted ? .green : .white.opacity(0.8))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption2)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white.opacity(0.55))
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            } else {
                Button(action: action) {
                    Text(actionButtonTitle)
                        .font(.caption)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundStyle(actionDisabled ? .white.opacity(0.5) : .black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(actionDisabled ? Color.white.opacity(0.15) : Color.white)
                        .cornerRadius(12)
                }
                .disabled(actionDisabled)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
