import Foundation
import Combine
import SwiftUI

class WorkoutManager: ObservableObject {
    @Published var workouts: [WorkoutSession] = [] {
        didSet {
            saveWorkouts()
        }
    }
    
    private let userDefaultsKey = "calendarWorkoutApp_saved_workouts"
    
    init() {
        loadWorkouts()
        if workouts.isEmpty || !workouts.contains(where: { $0.title == "Today Work" }) {
            createSampleWorkouts()
        }
        
        // Ensure June 11, 2026 promoted workout is initialized synchronously
        let calendar = Calendar.current
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 6
        comp.day = 11
        comp.hour = 12
        if let june11 = calendar.date(from: comp) {
            ensureTodayWorkExists(for: june11)
        }
    }
    
    func targetTemplateExercises(for date: Date) -> [Exercise] {
        let calendar = Calendar.current
        let comp = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Hardcoded AI Promoted Leg Session for June 11, 2026
        if comp.year == 2026 && comp.month == 6 && comp.day == 11 {
            return [
                Exercise(name: "Dumbbell Lunges", sets: [
                    ExerciseSet(weight: 15, reps: 12, isCompleted: false),
                    ExerciseSet(weight: 15, reps: 12, isCompleted: false),
                    ExerciseSet(weight: 15, reps: 12, isCompleted: false)
                ], notes: "Torso upright, deep steps"),
                Exercise(name: "Calf Raises", sets: [
                    ExerciseSet(weight: 45, reps: 15, isCompleted: false),
                    ExerciseSet(weight: 45, reps: 15, isCompleted: false),
                    ExerciseSet(weight: 45, reps: 15, isCompleted: false),
                    ExerciseSet(weight: 45, reps: 15, isCompleted: false)
                ], notes: "Full stretch at bottom, peak squeeze")
            ]
        }
        
        // Fallback target suggestion templates based on day of week (even/odd day alternation)
        let weekday = calendar.component(.weekday, from: date)
        switch weekday {
        case 1, 7: // Weekend Recovery
            return [
                Exercise(name: "Core Mat Pilates", sets: [
                    ExerciseSet(weight: 0, reps: 10, isCompleted: false),
                    ExerciseSet(weight: 0, reps: 10, isCompleted: false),
                    ExerciseSet(weight: 0, reps: 10, isCompleted: false)
                ], notes: "Slow control and core focus")
            ]
        case 2, 4, 6: // Mon/Wed/Fri Upper/Lower alternation
            if comp.day ?? 1 % 2 == 0 {
                return [
                    Exercise(name: "Squats", sets: [
                        ExerciseSet(weight: 25, reps: 6, isCompleted: false),
                        ExerciseSet(weight: 25, reps: 6, isCompleted: false),
                        ExerciseSet(weight: 25, reps: 6, isCompleted: false)
                    ], notes: "Focus on form and deep range of motion"),
                    Exercise(name: "Leg raises", sets: [
                        ExerciseSet(weight: 90, reps: 10, isCompleted: false),
                        ExerciseSet(weight: 90, reps: 10, isCompleted: false),
                        ExerciseSet(weight: 90, reps: 10, isCompleted: false)
                    ], notes: "Slow negatives and tight core")
                ]
            } else {
                return [
                    Exercise(name: "Bench Press", sets: [
                        ExerciseSet(weight: 45, reps: 10, isCompleted: false),
                        ExerciseSet(weight: 45, reps: 10, isCompleted: false),
                        ExerciseSet(weight: 45, reps: 10, isCompleted: false)
                    ], notes: "Keep shoulders retracted"),
                    Exercise(name: "Bicep Curls", sets: [
                        ExerciseSet(weight: 15, reps: 12, isCompleted: false),
                        ExerciseSet(weight: 15, reps: 12, isCompleted: false),
                        ExerciseSet(weight: 15, reps: 12, isCompleted: false)
                    ], notes: "Squeeze biceps at the top")
                ]
            }
        default: // Tue/Thu HIIT / Cardio
            return [
                Exercise(name: "Burpees", sets: [
                    ExerciseSet(weight: 0, reps: 15, isCompleted: false),
                    ExerciseSet(weight: 0, reps: 15, isCompleted: false),
                    ExerciseSet(weight: 0, reps: 15, isCompleted: false)
                ], notes: "High intensity pace"),
                Exercise(name: "Kettlebell Swings", sets: [
                    ExerciseSet(weight: 25, reps: 20, isCompleted: false),
                    ExerciseSet(weight: 25, reps: 20, isCompleted: false),
                    ExerciseSet(weight: 25, reps: 20, isCompleted: false)
                ], notes: "Snap hips at peak")
            ]
        }
    }
    
    func ensureTodayWorkExists(for date: Date) {
        let calendar = Calendar.current
        let exists = workouts.contains { $0.title == "Today Work" && calendar.isDate($0.date, inSameDayAs: date) }
        if !exists {
            let baselineExercises = targetTemplateExercises(for: date)
            let promotedWorkout = WorkoutSession(
                title: "Today Work",
                date: date,
                category: .strength,
                notes: "AI Promoted Session! Let's get moving.",
                exercises: baselineExercises,
                durationMinutes: 40
            )
            self.workouts.append(promotedWorkout)
        }
    }
    
    func carryoverUncompletedWorkouts(upTo currentDate: Date) {
        let calendar = Calendar.current
        let currentDateStart = calendar.startOfDay(for: currentDate)
        
        // Find all "Today Work" sessions before the current date that have incomplete exercises
        let pastTodayWorkouts = workouts.filter { workout in
            workout.title == "Today Work" && calendar.startOfDay(for: workout.date) < currentDateStart
        }
        
        guard !pastTodayWorkouts.isEmpty else { return }
        
        var incompleteExercisesToCarry: [Exercise] = []
        var workoutsToRemove: [UUID] = []
        var workoutsToUpdate: [UUID: [Exercise]] = [:]
        
        for pastWorkout in pastTodayWorkouts {
            var completedExercises: [Exercise] = []
            
            for exercise in pastWorkout.exercises {
                let incompleteSets = exercise.sets.filter { !$0.isCompleted }
                if !incompleteSets.isEmpty {
                    let exerciseToCarry = Exercise(
                        id: UUID(),
                        name: exercise.name,
                        sets: incompleteSets,
                        notes: exercise.notes
                    )
                    incompleteExercisesToCarry.append(exerciseToCarry)
                }
                
                let completedSets = exercise.sets.filter { $0.isCompleted }
                if !completedSets.isEmpty {
                    let completedExercise = Exercise(
                        id: exercise.id,
                        name: exercise.name,
                        sets: completedSets,
                        notes: exercise.notes
                    )
                    completedExercises.append(completedExercise)
                }
            }
            
            if completedExercises.isEmpty {
                workoutsToRemove.append(pastWorkout.id)
            } else {
                workoutsToUpdate[pastWorkout.id] = completedExercises
            }
        }
        
        // Apply mutations synchronously to make state operations completely clean and avoid race-conditions/duplications
        for id in workoutsToRemove {
            self.workouts.removeAll { $0.id == id }
        }
        
        for (id, exercises) in workoutsToUpdate {
            if let index = self.workouts.firstIndex(where: { $0.id == id }) {
                self.workouts[index].exercises = exercises
            }
        }
        
        guard !incompleteExercisesToCarry.isEmpty else { return }
        
        if let todayWorkoutIndex = self.workouts.firstIndex(where: { $0.title == "Today Work" && calendar.isDate($0.date, inSameDayAs: currentDate) }) {
            var todayWorkout = self.workouts[todayWorkoutIndex]
            for carriedExercise in incompleteExercisesToCarry {
                if let existingIndex = todayWorkout.exercises.firstIndex(where: { $0.name.lowercased() == carriedExercise.name.lowercased() }) {
                    let existingSetsCount = todayWorkout.exercises[existingIndex].sets.count
                    let carriedSetsCount = carriedExercise.sets.count
                    // Only carry over if we don't already have these sets loaded, making this idempotent
                    if existingSetsCount < carriedSetsCount {
                        todayWorkout.exercises[existingIndex].sets = carriedExercise.sets
                    }
                } else {
                    todayWorkout.exercises.append(carriedExercise)
                }
            }
            self.workouts[todayWorkoutIndex] = todayWorkout
        } else {
            let carryoverWorkout = WorkoutSession(
                title: "Today Work",
                date: currentDate,
                category: .strength,
                notes: "Carried over incomplete exercises from missed session.",
                exercises: incompleteExercisesToCarry,
                durationMinutes: 45
            )
            self.workouts.append(carryoverWorkout)
        }
    }
    
    func deleteExercise(from workout: WorkoutSession, exerciseId: UUID) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            var updatedWorkout = workouts[index]
            updatedWorkout.exercises.removeAll { $0.id == exerciseId }
            workouts[index] = updatedWorkout
        }
    }
    
    func duplicateSet(in workout: WorkoutSession, exerciseId: UUID, setId: UUID) {
        if let wIndex = workouts.firstIndex(where: { $0.id == workout.id }) {
            var updatedWorkout = workouts[wIndex]
            if let eIndex = updatedWorkout.exercises.firstIndex(where: { $0.id == exerciseId }) {
                var updatedExercise = updatedWorkout.exercises[eIndex]
                if let sIndex = updatedExercise.sets.firstIndex(where: { $0.id == setId }) {
                    let sourceSet = updatedExercise.sets[sIndex]
                    let duplicatedSet = ExerciseSet(
                        weight: sourceSet.weight,
                        reps: sourceSet.reps,
                        isCompleted: false
                    )
                    updatedExercise.sets.insert(duplicatedSet, at: sIndex + 1)
                    updatedWorkout.exercises[eIndex] = updatedExercise
                    workouts[wIndex] = updatedWorkout
                }
            }
        }
    }
    
    func prepareWorkouts(for date: Date) {
        carryoverUncompletedWorkouts(upTo: date)
        ensureTodayWorkExists(for: date)
    }
    
    func workouts(for date: Date) -> [WorkoutSession] {
        return workouts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func addWorkout(_ workout: WorkoutSession) {
        workouts.append(workout)
    }
    
    func updateWorkout(_ workout: WorkoutSession) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index] = workout
        }
    }
    
    func removeWorkout(_ workout: WorkoutSession) {
        workouts.removeAll { $0.id == workout.id }
    }
    
    private func saveWorkouts() {
        do {
            let data = try JSONEncoder().encode(workouts)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save workouts: \(error.localizedDescription)")
        }
    }
    
    private func loadWorkouts() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            workouts = try JSONDecoder().decode([WorkoutSession].self, from: data)
        } catch {
            print("Failed to load workouts: \(error.localizedDescription)")
        }
    }
    
    private func createSampleWorkouts() {
        let calendar = Calendar.current
        
        // Ensure we target exactly 6/10/2026 for 'Today Work'
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 10
        components.hour = 12
        let targetDate = calendar.date(from: components) ?? Date()
        
        let strengthWorkout = WorkoutSession(
            title: "Today Work",
            date: targetDate,
            category: .strength,
            notes: "Focused on heavy lower body and core. Let's make progress!",
            exercises: [
                Exercise(name: "Squats", sets: [
                    ExerciseSet(weight: 25, reps: 6, isCompleted: false),
                    ExerciseSet(weight: 25, reps: 6, isCompleted: false),
                    ExerciseSet(weight: 25, reps: 6, isCompleted: false)
                ], notes: "Focus on form and deep range of motion"),
                Exercise(name: "Leg raises", sets: [
                    ExerciseSet(weight: 90, reps: 10, isCompleted: false),
                    ExerciseSet(weight: 90, reps: 10, isCompleted: false),
                    ExerciseSet(weight: 90, reps: 10, isCompleted: false)
                ], notes: "Slow negatives and tight core")
            ],
            durationMinutes: 45
        )
        
        let cardioWorkout = WorkoutSession(
            title: "HIIT Cardio & Core",
            date: calendar.date(byAdding: .day, value: -1, to: targetDate) ?? targetDate,
            category: .hiit,
            notes: "Extremely sweaty. Rest intervals: 30s.",
            exercises: [
                Exercise(name: "Burpees", sets: [
                    ExerciseSet(weight: 0, reps: 15, isCompleted: true),
                    ExerciseSet(weight: 0, reps: 15, isCompleted: true)
                ]),
                Exercise(name: "Kettlebell Swings", sets: [
                    ExerciseSet(weight: 25, reps: 20, isCompleted: true),
                    ExerciseSet(weight: 25, reps: 20, isCompleted: true)
                ])
            ],
            durationMinutes: 20
        )
        
        workouts = [strengthWorkout, cardioWorkout]
    }
    
    // Level-Up Data Collection Engine: continuous logging of completed workouts by date
    var completedWorkoutsHistory: [String: [CompletedExerciseLog]] {
        var history: [String: [CompletedExerciseLog]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for workout in workouts {
            let dateKey = formatter.string(from: workout.date)
            for exercise in workout.exercises {
                // If any sets are completed, log them
                let completedSets = exercise.sets.filter { $0.isCompleted }
                if !completedSets.isEmpty {
                    let avgWeight = completedSets.map { $0.weight }.reduce(0, +) / Double(completedSets.count)
                    let reps = completedSets.first?.reps ?? 0
                    let log = CompletedExerciseLog(
                        date: workout.date,
                        exerciseName: exercise.name,
                        weight: avgWeight,
                        setsCount: completedSets.count,
                        repsPerSet: reps
                    )
                    if history[dateKey] == nil {
                        history[dateKey] = []
                    }
                    history[dateKey]?.append(log)
                }
            }
        }
        return history
    }
}

struct CompletedExerciseLog: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let exerciseName: String
    let weight: Double
    let setsCount: Int
    let repsPerSet: Int
}
