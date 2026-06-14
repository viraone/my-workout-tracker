import SwiftUI
import EventKit

/// A glassmorphic overlay component that displays the list of scheduled events.
public struct TimelineView: View {
    let events: [EKEvent]
    let glowColor: Color
    let onAddEvent: (() -> Void)?
    let onSelectEvent: ((EKEvent) -> Void)?
    
    public init(events: [EKEvent], glowColor: Color = .white, onAddEvent: (() -> Void)? = nil, onSelectEvent: ((EKEvent) -> Void)? = nil) {
        self.events = events
        self.glowColor = glowColor
        self.onAddEvent = onAddEvent
        self.onSelectEvent = onSelectEvent
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(colors: [.white, glowColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Text("Daily Agenda")
                    .font(.headline)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Pinned glass-morphic circular plus action button for event creation
                if let onAddEvent {
                    Button(action: onAddEvent) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(.thinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(LinearGradient(colors: [.white.opacity(0.4), glowColor.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                            )
                            .shadow(color: glowColor.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
                
                Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(glowColor.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 4)
            
            if events.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(colors: [.white.opacity(0.6), glowColor.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                        )
                    
                    Text("No events scheduled")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                    
                    Text("Enjoy your open, serene calendar day!")
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(LinearGradient(colors: [.white.opacity(0.2), glowColor.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(events, id: \.eventIdentifier) { event in
                        EventRow(event: event, timeFormatter: timeFormatter, glowColor: glowColor)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelectEvent?(event)
                            }
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.05), glowColor.opacity(0.35), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 8)
    }
}

private struct EventRow: View {
    let event: EKEvent
    let timeFormatter: DateFormatter
    let glowColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            // A colored bar representing the event's source calendar color
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 4)
                .frame(maxHeight: .infinity)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title ?? "Untitled Event")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(location)
                            .font(.caption2)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if event.isAllDay {
                    Text("All Day")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Text(timeFormatter.string(from: event.startDate))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(durationString)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(colors: [.white.opacity(0.2), glowColor.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
    
    private var durationString: String {
        let diff = event.endDate.timeIntervalSince(event.startDate)
        let mins = Int(diff / 60)
        if mins < 60 {
            return "\(mins)m"
        } else {
            let hrs = Double(mins) / 60.0
            return String(format: "%.1fh", hrs)
        }
    }
}
