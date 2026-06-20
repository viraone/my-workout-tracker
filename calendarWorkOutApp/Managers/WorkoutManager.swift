import Foundation
import Combine
import SwiftUI

@MainActor
final class WorkoutManager: ObservableObject {
    @Published private(set) var workouts: [WorkoutSession] = []
    @Published var errorMessage: String?
    @Published private(set) var isSaving = false

    private let repository: WorkoutRepository
    private let primaryWorkoutTitle = "Today Work"
    private let promotedSessionNotes = "AI Promoted Session! Let's get moving."
    private let recommendationSessionNotes = "AI Promoted Session! Based on your completed workout."
    private let carryoverSessionNotes = "Carried over incomplete exercises from missed session."

    init(repository: WorkoutRepository? = nil) {
        self.repository = repository ?? WorkoutRepository()
    }

    func targetTemplateExercises(for date: Date) -> [Exercise] {
        let calendar = Calendar.current
        let comp = calendar.dateComponents([.year, .month, .day], from: date)

        // Hardcoded AI Promoted Leg Session for June 11, 2026
        if comp.year == 2026 && comp.month == 6 && comp.day == 11 {
            return suggestedNextWorkoutExercises()
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
            if (comp.day ?? 1) % 2 == 0 {
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
        guard todayWorkIndex(on: date) == nil else { return }

        let previousWorkout = mostRecentTodayWork(before: date)
        let shouldUseRecommendation = previousWorkout?.isCompleted == true
        let baselineExercises = shouldUseRecommendation ? suggestedNextWorkoutExercises() : targetTemplateExercises(for: date)
        let notes = shouldUseRecommendation ? recommendationSessionNotes : promotedSessionNotes

        let promotedWorkout = WorkoutSession(
            title: primaryWorkoutTitle,
            date: date,
            category: .strength,
            notes: notes,
            exercises: baselineExercises,
            durationMinutes: 40
        )
        self.workouts.append(promotedWorkout)
    }

    @discardableResult
    func carryoverUncompletedWorkouts(upTo currentDate: Date) -> Bool {
        let calendar = Calendar.current
        let currentDateStart = calendar.startOfDay(for: currentDate)

        guard todayWorkIndex(on: currentDate) == nil,
              let sourceIndex = mostRecentTodayWorkIndex(before: currentDateStart) else { return false }

        let sourceWorkout = workouts[sourceIndex]
        let incompleteExercisesToCarry = incompleteExercises(from: sourceWorkout)
        guard !incompleteExercisesToCarry.isEmpty else { return false }

        archiveCompletedPortionOfWorkout(at: sourceIndex)

        let carryoverWorkout = WorkoutSession(
            title: primaryWorkoutTitle,
            date: currentDate,
            category: sourceWorkout.category,
            notes: carryoverSessionNotes,
            exercises: incompleteExercisesToCarry,
            durationMinutes: sourceWorkout.durationMinutes
        )
        self.workouts.append(carryoverWorkout)
        return true
    }

    @discardableResult
    func deleteExercise(from workout: WorkoutSession, exerciseId: UUID) async -> Bool {
        var updatedWorkout = workouts.first(where: { $0.id == workout.id }) ?? workout
        updatedWorkout.exercises.removeAll { $0.id == exerciseId }
        return await updateWorkout(updatedWorkout)
    }

    @discardableResult
    func duplicateSet(in workout: WorkoutSession, exerciseId: UUID, setId: UUID) async -> Bool {
        var updatedWorkout = workouts.first(where: { $0.id == workout.id }) ?? workout
        guard let exerciseIndex = updatedWorkout.exercises.firstIndex(where: { $0.id == exerciseId }),
              let setIndex = updatedWorkout.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setId }) else {
            return false
        }

        let sourceSet = updatedWorkout.exercises[exerciseIndex].sets[setIndex]
        let duplicatedSet = ExerciseSet(
            weight: sourceSet.weight,
            reps: sourceSet.reps,
            isCompleted: false
        )
        updatedWorkout.exercises[exerciseIndex].sets.insert(duplicatedSet, at: setIndex + 1)
        return await updateWorkout(updatedWorkout)
    }

    func prepareWorkouts(for date: Date) async {
        let previousWorkouts = workouts
        reconcileSystemGeneratedWorkoutIfNeeded(for: date)
        if todayWorkIndex(on: date) == nil {
            if !carryoverUncompletedWorkouts(upTo: date) {
                ensureTodayWorkExists(for: date)
            }
        }

        guard workouts != previousWorkouts else { return }
        await persistPreparedChanges(previousWorkouts: previousWorkouts)
    }

    private func reconcileSystemGeneratedWorkoutIfNeeded(for date: Date) {
        guard let currentIndex = todayWorkIndex(on: date) else { return }

        let currentWorkout = workouts[currentIndex]
        guard isSystemGenerated(currentWorkout),
              !hasCompletedSets(in: currentWorkout),
              let sourceIndex = mostRecentTodayWorkIndex(before: date) else { return }

        let sourceWorkout = workouts[sourceIndex]
        let carriedExercises = incompleteExercises(from: sourceWorkout)
        let currentWorkoutID = currentWorkout.id

        if !carriedExercises.isEmpty {
            guard !sameExerciseNames(currentWorkout.exercises, carriedExercises) else { return }

            var updatedWorkout = currentWorkout
            updatedWorkout.category = sourceWorkout.category
            updatedWorkout.notes = carryoverSessionNotes
            updatedWorkout.exercises = carriedExercises
            updatedWorkout.durationMinutes = sourceWorkout.durationMinutes

            archiveCompletedPortionOfWorkout(at: sourceIndex)
            if let updatedIndex = workouts.firstIndex(where: { $0.id == currentWorkoutID }) {
                workouts[updatedIndex] = updatedWorkout
            }
        } else if sourceWorkout.isCompleted {
            let suggestedExercises = suggestedNextWorkoutExercises()
            guard !sameExerciseNames(currentWorkout.exercises, suggestedExercises) else { return }

            var updatedWorkout = currentWorkout
            updatedWorkout.category = .strength
            updatedWorkout.notes = recommendationSessionNotes
            updatedWorkout.exercises = suggestedExercises
            updatedWorkout.durationMinutes = 40
            workouts[currentIndex] = updatedWorkout
        }
    }

    private func todayWorkIndex(on date: Date) -> Int? {
        let calendar = Calendar.current
        return workouts.firstIndex {
            $0.title == primaryWorkoutTitle && calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    private func mostRecentTodayWork(before date: Date) -> WorkoutSession? {
        guard let index = mostRecentTodayWorkIndex(before: date) else { return nil }
        return workouts[index]
    }

    private func mostRecentTodayWorkIndex(before date: Date) -> Int? {
        let calendar = Calendar.current
        let currentDateStart = calendar.startOfDay(for: date)

        return workouts.indices
            .filter {
                workouts[$0].title == primaryWorkoutTitle
                    && calendar.startOfDay(for: workouts[$0].date) < currentDateStart
            }
            .max {
                workouts[$0].date < workouts[$1].date
            }
    }

    private func incompleteExercises(from workout: WorkoutSession) -> [Exercise] {
        workout.exercises.compactMap { exercise in
            let incompleteSets = exercise.sets.filter { !$0.isCompleted }
            guard !incompleteSets.isEmpty else { return nil }
            return Exercise(
                id: UUID(),
                name: exercise.name,
                sets: incompleteSets,
                notes: exercise.notes
            )
        }
    }

    private func completedExercises(from workout: WorkoutSession) -> [Exercise] {
        workout.exercises.compactMap { exercise in
            let completedSets = exercise.sets.filter { $0.isCompleted }
            guard !completedSets.isEmpty else { return nil }
            return Exercise(
                id: exercise.id,
                name: exercise.name,
                sets: completedSets,
                notes: exercise.notes
            )
        }
    }

    private func archiveCompletedPortionOfWorkout(at index: Int) {
        guard workouts.indices.contains(index) else { return }

        let completedExercises = completedExercises(from: workouts[index])
        if completedExercises.isEmpty {
            workouts.remove(at: index)
        } else {
            workouts[index].exercises = completedExercises
        }
    }

    private func suggestedNextWorkoutExercises() -> [Exercise] {
        [
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

    private func isSystemGenerated(_ workout: WorkoutSession) -> Bool {
        workout.notes == promotedSessionNotes
            || workout.notes == recommendationSessionNotes
            || workout.notes == carryoverSessionNotes
    }

    private func hasCompletedSets(in workout: WorkoutSession) -> Bool {
        workout.exercises.contains { exercise in
            exercise.sets.contains { $0.isCompleted }
        }
    }

    private func sameExerciseNames(_ lhs: [Exercise], _ rhs: [Exercise]) -> Bool {
        lhs.map { normalizedExerciseName($0.name) } == rhs.map { normalizedExerciseName($0.name) }
    }

    func workouts(for date: Date) -> [WorkoutSession] {
        return workouts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    @discardableResult
    func fetchWorkouts() async -> Bool {
        do {
            workouts = try await fetchRemoteWorkouts()
            clearError()
            return true
        } catch {
            report(error, action: "fetch workouts")
            return false
        }
    }

    @discardableResult
    func saveWorkout(
        _ workout: WorkoutSession,
        mergeExistingExercises: Bool = false,
        removedExerciseIDs: Set<UUID> = []
    ) async -> Bool {
        let persistedWorkout: WorkoutSession

        if mergeExistingExercises, let index = mergeTargetIndex(for: workout) {
            persistedWorkout = mergedWorkout(
                existing: workouts[index],
                incoming: workout,
                removedExerciseIDs: removedExerciseIDs
            )
        } else {
            persistedWorkout = workout
        }

        let alreadyExists = workouts.contains { $0.id == persistedWorkout.id }
        return await persistWorkout(persistedWorkout, alreadyExists: alreadyExists)
    }

    @discardableResult
    func saveExercise(_ exercise: Exercise, in workout: WorkoutSession) async -> Bool {
        guard let workoutIndex = workouts.firstIndex(where: { $0.id == workout.id }) else {
            var workoutWithExercise = workout
            if let exerciseIndex = workoutWithExercise.exercises.firstIndex(where: { $0.id == exercise.id }) {
                workoutWithExercise.exercises[exerciseIndex] = exercise
            } else {
                workoutWithExercise.exercises.append(exercise)
            }
            return await saveWorkout(workoutWithExercise, mergeExistingExercises: true)
        }

        var updatedWorkout = workouts[workoutIndex]
        if let exerciseIndex = updatedWorkout.exercises.firstIndex(where: { $0.id == exercise.id }) {
            updatedWorkout.exercises[exerciseIndex] = exercise
        } else {
            updatedWorkout.exercises.append(exercise)
        }
        return await updateWorkout(updatedWorkout)
    }

    private func mergeTargetIndex(for workout: WorkoutSession) -> Int? {
        if let idMatch = workouts.firstIndex(where: { $0.id == workout.id }) {
            return idMatch
        }

        let calendar = Calendar.current
        if let sameTitleSameDay = workouts.firstIndex(where: {
            $0.title == workout.title && calendar.isDate($0.date, inSameDayAs: workout.date)
        }) {
            return sameTitleSameDay
        }

        let sameDayIndices = workouts.indices.filter {
            calendar.isDate(workouts[$0].date, inSameDayAs: workout.date)
        }
        return sameDayIndices.count == 1 ? sameDayIndices[0] : nil
    }

    private func mergedWorkout(
        existing: WorkoutSession,
        incoming: WorkoutSession,
        removedExerciseIDs: Set<UUID>
    ) -> WorkoutSession {
        let shouldUseIncomingMetadata = existing.id == incoming.id
        var merged = shouldUseIncomingMetadata ? incoming : existing
        merged.id = existing.id

        var mergedExercises: [Exercise] = []
        var consumedIncomingIDs = Set<UUID>()

        for existingExercise in existing.exercises {
            guard !removedExerciseIDs.contains(existingExercise.id) else { continue }

            if let incomingExercise = incoming.exercises.first(where: { $0.id == existingExercise.id }) {
                mergedExercises.append(incomingExercise)
                consumedIncomingIDs.insert(incomingExercise.id)
            } else if let incomingExercise = incoming.exercises.first(where: {
                !consumedIncomingIDs.contains($0.id)
                    && normalizedExerciseName($0.name) == normalizedExerciseName(existingExercise.name)
            }) {
                mergedExercises.append(incomingExercise)
                consumedIncomingIDs.insert(incomingExercise.id)
            } else {
                mergedExercises.append(existingExercise)
            }
        }

        for incomingExercise in incoming.exercises {
            guard !removedExerciseIDs.contains(incomingExercise.id),
                  !consumedIncomingIDs.contains(incomingExercise.id) else { continue }

            if let matchingIndex = mergedExercises.firstIndex(where: {
                normalizedExerciseName($0.name) == normalizedExerciseName(incomingExercise.name)
            }) {
                mergedExercises[matchingIndex] = incomingExercise
            } else {
                mergedExercises.append(incomingExercise)
            }
        }

        merged.exercises = mergedExercises
        return merged
    }

    private func normalizedExerciseName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    @discardableResult
    func addWorkout(_ workout: WorkoutSession) async -> Bool {
        await saveWorkout(workout)
    }

    @discardableResult
    func updateWorkout(_ workout: WorkoutSession) async -> Bool {
        await persistWorkout(workout, alreadyExists: true)
    }

    @discardableResult
    func removeWorkout(_ workout: WorkoutSession) async -> Bool {
        isSaving = true
        clearError()
        defer { isSaving = false }

        do {
            try await repository.deleteWorkout(workout)
            workouts = try await fetchRemoteWorkouts()
            return true
        } catch {
            report(error, action: "delete workout")
            return false
        }
    }

    private func persistWorkout(_ workout: WorkoutSession, alreadyExists: Bool) async -> Bool {
        isSaving = true
        clearError()
        print("Saving workout...")
        defer { isSaving = false }

        do {
            if alreadyExists {
                try await repository.updateWorkout(workout)
            } else {
                try await repository.saveWorkout(workout)
            }
            print("Workout saved")
            workouts = try await fetchRemoteWorkouts()
            return true
        } catch {
            report(error, action: "save workout")
            return false
        }
    }

    private func fetchRemoteWorkouts() async throws -> [WorkoutSession] {
        print("Fetching workouts...")
        let fetchedWorkouts = try await repository.fetchWorkouts()
        print("Fetched \(fetchedWorkouts.count)")
        return fetchedWorkouts
    }

    private func persistPreparedChanges(previousWorkouts: [WorkoutSession]) async {
        let preparedWorkouts = workouts
        let previousByID = Dictionary(uniqueKeysWithValues: previousWorkouts.map { ($0.id, $0) })
        let preparedByID = Dictionary(uniqueKeysWithValues: preparedWorkouts.map { ($0.id, $0) })

        isSaving = true
        clearError()
        defer { isSaving = false }

        do {
            for removedWorkout in previousWorkouts where preparedByID[removedWorkout.id] == nil {
                try await repository.deleteWorkout(removedWorkout)
            }

            for preparedWorkout in preparedWorkouts {
                if let previousWorkout = previousByID[preparedWorkout.id] {
                    if previousWorkout != preparedWorkout {
                        try await repository.updateWorkout(preparedWorkout)
                    }
                } else {
                    try await repository.saveWorkout(preparedWorkout)
                }
            }

            workouts = try await fetchRemoteWorkouts()
        } catch {
            workouts = previousWorkouts
            report(error, action: "prepare workouts")
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func report(_ error: Error, action: String) {
        let message: String

        if Self.containsCannotFindHostError(error) {
            let host = SupabaseManager.projectURL.host ?? SupabaseManager.projectURL.absoluteString
            message = """
            Unable to \(action): Supabase host \(host) could not be found. Copy the current Project URL from Supabase Settings → API and replace the URL in SupabaseManager.swift.
            """
        } else {
            message = "Unable to \(action): \(error.localizedDescription)"
        }

        errorMessage = message
        print(message)
    }

    private static func containsCannotFindHostError(_ error: Error) -> Bool {
        var currentError: NSError? = error as NSError
        var visitedErrors = Set<ObjectIdentifier>()

        while let candidate = currentError {
            let identifier = ObjectIdentifier(candidate)
            guard visitedErrors.insert(identifier).inserted else { break }

            if candidate.domain == NSURLErrorDomain,
               candidate.code == URLError.cannotFindHost.rawValue {
                return true
            }

            currentError = candidate.userInfo[NSUnderlyingErrorKey] as? NSError
        }

        return false
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
