import Foundation
import Supabase

@MainActor
final class WorkoutRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient? = nil) {
        self.client = client ?? SupabaseManager.shared.client
    }

    func fetchWorkouts() async throws -> [Workout] {
        let workoutRows: [WorkoutRow] = try await client
            .from("workouts")
            .select()
            .order("workout_date", ascending: false)
            .execute()
            .value

        let exerciseRows: [ExerciseRow] = try await client
            .from("exercises")
            .select()
            .order("order_index")
            .execute()
            .value

        let setRows: [ExerciseSetRow] = try await client
            .from("sets")
            .select()
            .order("set_number")
            .execute()
            .value

        let setsByExercise = Dictionary(grouping: setRows, by: \.exerciseID)
        let exercisesByWorkout = Dictionary(grouping: exerciseRows, by: \.workoutID)

        return try workoutRows.map { workoutRow in
            let date = try Self.date(from: workoutRow.workoutDate)
            let category = WorkoutCategory(rawValue: workoutRow.category) ?? .strength
            let exercises = exercisesByWorkout[workoutRow.id, default: []]
                .sorted { $0.orderIndex < $1.orderIndex }
                .map { exerciseRow in
                    Exercise(
                        id: exerciseRow.id,
                        name: exerciseRow.name,
                        sets: setsByExercise[exerciseRow.id, default: []]
                            .sorted { $0.setNumber < $1.setNumber }
                            .map {
                                ExerciseSet(
                                    id: $0.id,
                                    weight: $0.weight,
                                    reps: $0.reps,
                                    isCompleted: $0.isCompleted
                                )
                            },
                        notes: exerciseRow.notes
                    )
                }

            return Workout(
                id: workoutRow.id,
                title: workoutRow.title,
                date: date,
                category: category,
                notes: workoutRow.notes,
                exercises: exercises,
                durationMinutes: workoutRow.durationMinutes
            )
        }
    }

    func saveWorkout(_ workout: Workout) async throws {
        try await client
            .from("workouts")
            .upsert(WorkoutRow(workout: workout))
            .execute()

        // Replacing the child graph under a stable workout UUID removes stale
        // exercises and sets while preventing a second workout row.
        try await client
            .from("exercises")
            .delete()
            .eq("workout_id", value: workout.id.uuidString)
            .execute()

        let exerciseRows = workout.exercises.enumerated().map { index, exercise in
            ExerciseRow(exercise: exercise, workoutID: workout.id, orderIndex: index)
        }

        if !exerciseRows.isEmpty {
            try await client
                .from("exercises")
                .insert(exerciseRows)
                .execute()
        }

        let setRows = workout.exercises.flatMap { exercise in
            exercise.sets.enumerated().map { index, exerciseSet in
                ExerciseSetRow(
                    exerciseSet: exerciseSet,
                    exerciseID: exercise.id,
                    setNumber: index + 1
                )
            }
        }

        if !setRows.isEmpty {
            try await client
                .from("sets")
                .insert(setRows)
                .execute()
        }
    }

    func updateWorkout(_ workout: Workout) async throws {
        try await saveWorkout(workout)
    }

    func deleteWorkout(_ workout: Workout) async throws {
        try await client
            .from("workouts")
            .delete()
            .eq("id", value: workout.id.uuidString)
            .execute()
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fallbackDateFormatter = ISO8601DateFormatter()

    private static func date(from string: String) throws -> Date {
        if let date = dateFormatter.date(from: string) ?? fallbackDateFormatter.date(from: string) {
            return date
        }

        throw WorkoutRepositoryError.invalidWorkoutDate(string)
    }

    private struct WorkoutRow: Codable {
        let id: UUID
        let workoutDate: String
        let title: String
        let category: String
        let notes: String
        let durationMinutes: Int

        init(workout: Workout) {
            id = workout.id
            workoutDate = WorkoutRepository.dateFormatter.string(from: workout.date)
            title = workout.title
            category = workout.category.rawValue
            notes = workout.notes
            durationMinutes = workout.durationMinutes
        }

        enum CodingKeys: String, CodingKey {
            case id
            case workoutDate = "workout_date"
            case title
            case category
            case notes
            case durationMinutes = "duration_minutes"
        }
    }

    private struct ExerciseRow: Codable {
        let id: UUID
        let workoutID: UUID
        let name: String
        let notes: String
        let orderIndex: Int

        init(exercise: Exercise, workoutID: UUID, orderIndex: Int) {
            id = exercise.id
            self.workoutID = workoutID
            name = exercise.name
            notes = exercise.notes
            self.orderIndex = orderIndex
        }

        enum CodingKeys: String, CodingKey {
            case id
            case workoutID = "workout_id"
            case name
            case notes
            case orderIndex = "order_index"
        }
    }

    private struct ExerciseSetRow: Codable {
        let id: UUID
        let exerciseID: UUID
        let weight: Double
        let reps: Int
        let setNumber: Int
        let isCompleted: Bool

        init(exerciseSet: ExerciseSet, exerciseID: UUID, setNumber: Int) {
            id = exerciseSet.id
            self.exerciseID = exerciseID
            weight = exerciseSet.weight
            reps = exerciseSet.reps
            self.setNumber = setNumber
            isCompleted = exerciseSet.isCompleted
        }

        enum CodingKeys: String, CodingKey {
            case id
            case exerciseID = "exercise_id"
            case weight
            case reps
            case setNumber = "set_number"
            case isCompleted = "is_completed"
        }
    }
}

enum WorkoutRepositoryError: LocalizedError {
    case invalidWorkoutDate(String)

    var errorDescription: String? {
        switch self {
        case .invalidWorkoutDate(let value):
            return "Supabase returned an invalid workout date: \(value)"
        }
    }
}
