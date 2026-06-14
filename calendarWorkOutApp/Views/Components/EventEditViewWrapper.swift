import SwiftUI
import EventKit
import EventKitUI

/// A SwiftUI wrapper around the native EventKitUI `EKEventEditViewController`.
/// Allows seamless creation of calendar events in the app and triggers an agenda reload upon completion.
public struct EventEditViewWrapper: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    public let eventStore: EKEventStore
    public let defaultDate: Date
    public let event: EKEvent?
    public let onComplete: () -> Void
    
    public init(eventStore: EKEventStore, defaultDate: Date, event: EKEvent? = nil, onComplete: @escaping () -> Void) {
        self.eventStore = eventStore
        self.defaultDate = defaultDate
        self.event = event
        self.onComplete = onComplete
    }
    
    public class Coordinator: NSObject, EKEventEditViewDelegate {
        let parent: EventEditViewWrapper
        
        init(parent: EventEditViewWrapper) {
            self.parent = parent
        }
        
        public func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            parent.dismiss()
            if action == .saved {
                parent.onComplete()
            }
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        controller.editViewDelegate = context.coordinator
        
        if let event = event {
            controller.event = event
        } else {
            let newEvent = EKEvent(eventStore: eventStore)
            newEvent.startDate = defaultDate
            newEvent.endDate = defaultDate.addingTimeInterval(3600) // Default 1 hour block
            controller.event = newEvent
        }
        
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}
}
