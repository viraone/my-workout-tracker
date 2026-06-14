import Foundation
import SwiftUI

enum WorkoutCategory: String, Codable, CaseIterable, Identifiable {
    case strength = "Strength"
    case cardio = "Cardio"
    case hiit = "HIIT"
    case pilates = "Pilates"
    case walk = "Walking"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .strength: return "figure.strengthtraining.functional"
        case .cardio: return "figure.run"
        case .hiit: return "figure.highintensity.intervaltraining"
        case .pilates: return "figure.pilates"
        case .walk: return "figure.walk"
        }
    }
    
    var color: Color {
        switch self {
        case .strength: return .red
        case .cardio: return .orange
        case .hiit: return .purple
        case .pilates: return .teal
        case .walk: return .green
        }
    }
    
    var suggestions: [String] {
        switch self {
        case .strength: return ["Bench Press", "Squats", "Deadlifts", "Shoulder Press", "Bicep Curls", "Tricep Pushdowns"]
        case .cardio: return ["Outdoor Run", "Treadmill", "Cycling", "Elliptical", "Swimming", "Stair Climber"]
        case .hiit: return ["Burpees", "Kettlebell Swings", "Jumping Jacks", "Mountain Climbers", "Plank Jacks"]
        case .pilates: return ["Core Mat Pilates", "Hundred Series", "Leg Circles", "Teaser Prep"]
        case .walk: return ["Brisk Power Walk", "Nature Hike", "Interval Walking"]
        }
    }
}

struct ExerciseSet: Identifiable, Codable, Equatable {
    var id = UUID()
    var weight: Double // in lbs or kg
    var reps: Int
    var isCompleted: Bool = false
}

struct Exercise: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var sets: [ExerciseSet]
    var notes: String = ""
    var isCompleted: Bool {
        !sets.isEmpty && sets.allSatisfy { $0.isCompleted }
    }
}

struct WorkoutSession: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var date: Date
    var category: WorkoutCategory
    var notes: String = ""
    var exercises: [Exercise]
    var durationMinutes: Int = 30
    
    var totalWeightLifted: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                setTotal + (set.isCompleted ? (set.weight * Double(set.reps)) : 0)
            }
        }
    }
    
    var isCompleted: Bool {
        !exercises.isEmpty && exercises.allSatisfy { $0.isCompleted }
    }
}
