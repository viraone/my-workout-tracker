import SwiftUI

@main
struct CalendarWorkOutApp: App {
    @StateObject private var workoutManager = WorkoutManager()
    
    var body: some Scene {
        WindowGroup {
            DailyCanvasView()
                .environmentObject(workoutManager)
                .preferredColorScheme(.dark) // Dark mode compliments our glassmorphic backgrounds beautifully
        }
    }
}
