import SwiftUI

struct DailyWorkoutsListView: View {
    @EnvironmentObject private var workoutManager: WorkoutManager

    let date: Date
    let onLogWorkout: () -> Void
    let onDeleteWorkout: (WorkoutSession) -> Void
    let onToggleExerciseSet: (WorkoutSession, UUID, UUID) -> Void // Toggle a set's completeness!
    let onSelectWorkout: (WorkoutSession) -> Void
    let onToggleExerciseAllSets: (WorkoutSession, UUID, Bool) -> Void
    let onSelectExercise: (WorkoutSession, Exercise, Bool) -> Void
    let glowColor: Color

    private var workouts: [WorkoutSession] {
        workoutManager.workouts(for: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("TODAY'S WORKOUTS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .kerning(1.2)
                    .foregroundStyle(.white.opacity(0.6))
                
                Spacer()
                
                Button(action: onLogWorkout) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("Log")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            if workouts.isEmpty {
                // Empty state card
                VStack(spacing: 12) {
                    Image(systemName: "figure.run.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.top, 8)
                    
                    Text("No Workouts Logged Yet")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text("Stay active! Log a workout session for today or use the suggestion above to get started.")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    Button(action: onLogWorkout) {
                        Text("Log a Workout")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.12))
                            .cornerRadius(20)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            } else {
                ForEach(workouts) { workout in
                    WorkoutSessionCard(
                        workout: workout,
                        onDeleteWorkout: onDeleteWorkout,
                        onToggleExerciseSet: onToggleExerciseSet,
                        onSelectWorkout: onSelectWorkout,
                        onToggleExerciseAllSets: onToggleExerciseAllSets,
                        onSelectExercise: onSelectExercise
                    )
                }
            }
        }
        .padding(.horizontal, 0)
    }
}

struct ExerciseSetButton: View {
    let index: Int
    let set: ExerciseSet
    let category: WorkoutCategory

    var body: some View {
        HStack(spacing: 4) {
            Text("S\(index + 1):")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
            if set.weight > 0 {
                Text("\(Int(set.weight))lbs")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            Text("x\(set.reps)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(set.isCompleted ? category.color.opacity(0.12) : .white.opacity(0.04))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(set.isCompleted ? category.color.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .foregroundStyle(.white)
    }
}

struct WorkoutSessionCard: View {
    let workout: WorkoutSession
    let onDeleteWorkout: (WorkoutSession) -> Void
    let onToggleExerciseSet: (WorkoutSession, UUID, UUID) -> Void
    let onSelectWorkout: (WorkoutSession) -> Void
    let onToggleExerciseAllSets: (WorkoutSession, UUID, Bool) -> Void
    let onSelectExercise: (WorkoutSession, Exercise, Bool) -> Void
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var newInlineExerciseName: String = ""
    // Minimalist Rest Timer State
    @State private var activeTimerExerciseId: UUID? = nil
    @State private var restTimeRemaining: Int = 90
    @State private var timerSubscription: Timer? = nil
    @State private var isHighIntensityTimerActive: Bool = false
    // Live Insights expanded/collapsed state
    @State private var isInsightsExpanded: Bool = false
    
    // Exercise Deletion Confirmation State
    @State private var exerciseToDelete: Exercise? = nil
    @State private var showDeleteConfirmation = false
    // Computed Properties for Session Insights
    private var liveTotalVolume: Double {
        var total = 0.0
        for exercise in workout.exercises {
            for set in exercise.sets {
                if set.isCompleted {
                    total += set.weight * Double(set.reps)
                }
            }
        }
        return total
    }
    private var strengthVolume: Double {
        var total = 0.0
        for exercise in workout.exercises {
            for set in exercise.sets {
                if set.isCompleted && set.reps <= 6 {
                    total += set.weight * Double(set.reps)
                }
            }
        }
        return total
    }
    private var hypertrophyVolume: Double {
        var total = 0.0
        for exercise in workout.exercises {
            for set in exercise.sets {
                if set.isCompleted && set.reps > 6 {
                    total += set.weight * Double(set.reps)
                }
            }
        }
        return total
    }
    private var strengthRatio: Double {
        let total = strengthVolume + hypertrophyVolume
        guard total > 0 else { return 0.5 }
        return strengthVolume / total
    }

    private var stimulusBreakdownView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Strength: \(Int(strengthVolume)) lbs")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan)

                Spacer()

                Text("Hypertrophy: \(Int(hypertrophyVolume)) lbs")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
            }

            GeometryReader { geometry in
                let strengthWidth = geometry.size.width * CGFloat(strengthRatio)
                let hypertrophyWidth = geometry.size.width - strengthWidth

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.cyan)
                        .frame(width: strengthWidth)

                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: hypertrophyWidth)
                }
            }
            .frame(height: 6)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private var insightsFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isInsightsExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "waveform.path.ecg.gradient")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(workout.category.color)

                    Text("Live Session Insights")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(isInsightsExpanded ? "Collapse" : "Expand")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))

                    Image(systemName: isInsightsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if isInsightsExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(workout.category.color)

                        Text("\(Int(liveTotalVolume)) lbs")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("total volume lifted today")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    stimulusBreakdownView

                    if !workout.notes.isEmpty {
                        Divider()
                            .background(Color.white.opacity(0.08))

                        Text(workout.notes)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .italic()
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 2)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if !workout.notes.isEmpty {
                Text(workout.notes)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .italic()
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var exercisesSection: some View {
        if !workout.exercises.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(workout.exercises) { exercise in
                    exerciseRow(exercise)
                }

                if workout.title == "Today Work" {
                    inlineExerciseEntry
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.vertical, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, exerciseSet in
                        exerciseSetControl(
                            exerciseSet,
                            index: index,
                            exerciseID: exercise.id
                        )
                    }
                }
            }
        }
        .padding(.leading, 6)
        .opacity(exercise.isCompleted ? 0.45 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelectExercise(workout, exercise, true)
        }
        .onLongPressGesture(minimumDuration: 0.8) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            exerciseToDelete = exercise
            showDeleteConfirmation = true
        }
    }

    private func exerciseSetControl(
        _ exerciseSet: ExerciseSet,
        index: Int,
        exerciseID: UUID
    ) -> some View {
        HStack(spacing: 4) {
            ExerciseSetButton(
                index: index,
                set: exerciseSet,
                category: workout.category
            )

            Button {
                Task<Void, Never> {
                    _ = await workoutManager.duplicateSet(
                        in: workout,
                        exerciseId: exerciseID,
                        setId: exerciseSet.id
                    )
                }
            } label: {
                Image(systemName: "plus.square.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .buttonStyle(.plain)
        }
        .padding(.trailing, 2)
    }

    private var inlineExerciseEntry: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 2)

            HStack {
                TextField("", text: $newInlineExerciseName)
                    .disabled(true)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }

                Button {
                    let name = newInlineExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }

                    onSelectExercise(workout, Exercise(name: name, sets: []), false)
                    newInlineExerciseName = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(workout.category.color)
                }
                .disabled(newInlineExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 6)
    }

    private func getNextSetPreviewText(for exercise: Exercise) -> String {
        if let nextIncompleteIndex = exercise.sets.firstIndex(where: { !$0.isCompleted }) {
            let nextSet = exercise.sets[nextIncompleteIndex]
            let weightText = nextSet.weight > 0 ? "\(Int(nextSet.weight))lbs " : ""
            let motivationalQuote: String
            if nextIncompleteIndex == exercise.sets.count - 1 {
                motivationalQuote = "Finish strong!"
            } else {
                motivationalQuote = "Focus on explosive tempo."
            }
            return "Up Next: Set \(nextIncompleteIndex + 1) — Target \(weightText)x\(nextSet.reps). \(motivationalQuote)"
        } else {
            return "Session Complete!"
        }
    }
    private func startRestTimer(for exerciseId: UUID, highIntensity: Bool = false) {
        stopRestTimer()
        activeTimerExerciseId = exerciseId
        isHighIntensityTimerActive = highIntensity
        restTimeRemaining = highIntensity ? 120 : 90
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if restTimeRemaining > 1 {
                restTimeRemaining -= 1
            } else {
                stopRestTimer()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timerSubscription = timer
    }
    private func stopRestTimer() {
        timerSubscription?.invalidate()
        timerSubscription = nil
        activeTimerExerciseId = nil
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title / Header
            HStack(alignment: .top) {
                Circle()
                    .fill(workout.category.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: workout.category.iconName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(workout.category.color)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Text(workout.category.rawValue)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(workout.category.color)
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("\(workout.durationMinutes)m")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                        if workout.totalWeightLifted > 0 {
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.3))
                            Image(systemName: "scalemass")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("\(Int(workout.totalWeightLifted)) lbs")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
                Spacer()
                Button(action: { onDeleteWorkout(workout) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            // Exercises list
            exercisesSection
            
            // Feature: Expanding Live Insights Dashboard Footer
            insightsFooter
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(red: 1, green: 1, blue: 1, opacity: 0.12), lineWidth: 1)
        )
        .contentShape(Rectangle()) // Make the whole card area tappable
        .onTapGesture {
            onSelectWorkout(workout)
        }
        .alert("Delete Exercise?", isPresented: $showDeleteConfirmation, presenting: exerciseToDelete) { exercise in
            Button("Delete", role: .destructive) {
                Task<Void, Never> {
                    _ = await workoutManager.deleteExercise(from: workout, exerciseId: exercise.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { exercise in
            Text("Are you sure you want to completely delete '\(exercise.name)' from this workout session?")
        }
    }
}

struct SuggestionDetail: Identifiable {
    var id: String { name }
    let name: String
    let subtitle: String
    let muscles: [String]
    let formHints: [String]
    let loadStrategy: String
    let iconName: String
    let color: Color
}

struct TomorrowsPreviewCard: View {
    let workout: WorkoutSession
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var selectedSuggestion: SuggestionDetail? = nil
    @State private var forceGenerateSuggestions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.purple)
                
                Text("Tomorrow Suggested Workout")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .kerning(1.2)
                    .foregroundStyle(.white.opacity(0.6))
                
                Spacer()
                
                // Status Pill
                Text(workout.isCompleted || forceGenerateSuggestions ? "Unlocked" : "Locked")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(workout.isCompleted || forceGenerateSuggestions ? Color.green.opacity(0.12) : Color.white.opacity(0.06))
                    .foregroundStyle(workout.isCompleted || forceGenerateSuggestions ? Color.green : Color.white.opacity(0.4))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(workout.isCompleted || forceGenerateSuggestions ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            
            if workout.isCompleted || forceGenerateSuggestions {
                // SUGGESTIONS UNLOCKED STATE
                VStack(alignment: .leading, spacing: 10) {
                    Text("Based on today's leg-dominant movements, our local AI engine recommends targeting complementary muscle chains tomorrow:")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(spacing: 8) {
                        // Suggestion 1: Dumbbell Lunges
                        Button(action: {
                            selectedSuggestion = SuggestionDetail(
                                name: "Dumbbell Lunges",
                                subtitle: "3 sets x 12 reps",
                                muscles: ["Quadriceps", "Glutes", "Hamstrings"],
                                formHints: [
                                    "Step forward and lower your hips until back knee is near floor",
                                    "Keep your torso upright and core tightly engaged",
                                    "Avoid letting front knee pass beyond toes"
                                ],
                                loadStrategy: "Hold moderately heavy dumbbells. Focus on slow, controlled vertical descent.",
                                iconName: "figure.strengthtraining.functional",
                                color: .purple
                            )
                        }) {
                            HStack {
                                Image(systemName: "circle.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.purple)
                                
                                Text("Suggested: Dumbbell Lunges")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                Text("3 sets x 12 reps")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // Suggestion 2: Calf Raises
                        Button(action: {
                            selectedSuggestion = SuggestionDetail(
                                name: "Calf Raises",
                                subtitle: "4 sets x 15 reps",
                                muscles: ["Gastrocnemius", "Soleus"],
                                formHints: [
                                    "Stand on a raised edge with heels hanging off",
                                    "Lower heels fully for deep stretch, then press up high on toes",
                                    "Pause for 1 second at peak contraction"
                                ],
                                loadStrategy: "Hold a single heavy dumbbell or use bodyweight with 3s slow negatives.",
                                iconName: "figure.strengthtraining.functional",
                                color: .blue
                            )
                        }) {
                            HStack {
                                Image(systemName: "circle.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.blue)
                                
                                Text("Suggested: Calf Raises")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                Text("4 sets x 15 reps")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // SUGGESTIONS GATED/LOCKED EMPTY STATE
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 18))
                            .foregroundStyle(.purple.opacity(0.7))
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Suggestions Gated")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Text("Complete today's Squats and Leg raises to unlock tomorrow's personalized leg-progression recommendations!")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.55))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(12)
                    
                    // Fallback button: "Generate Suggestion Plan Anyway"
                    Button(action: {
                        withAnimation(.spring()) {
                            forceGenerateSuggestions = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 12, weight: .bold))
                            Text("Generate Suggestion Plan Anyway")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [.purple.opacity(0.35), .blue.opacity(0.35)], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .sheet(item: $selectedSuggestion) { suggestion in
            SuggestionDetailSheet(suggestion: suggestion)
        }
    }
}

struct SuggestionDetailSheet: View {
    let suggestion: SuggestionDetail
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Glassy dark gradient background
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.1, blue: 0.2), Color(red: 0.02, green: 0.03, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // Top drag indicator and close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.top, 16)
                
                // Header details
                HStack(spacing: 16) {
                    Circle()
                        .fill(suggestion.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: suggestion.iconName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(suggestion.color)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text(suggestion.subtitle)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(suggestion.color)
                    }
                }
                
                // Section 1: Muscle Group Activation
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "figure.strengthtraining.functional")
                            .font(.system(size: 14))
                            .foregroundStyle(suggestion.color)
                        Text("MUSCLE GROUP ACTIVATION")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(suggestion.muscles, id: \.self) { muscle in
                            Text(muscle)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(suggestion.color.opacity(0.12))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(suggestion.color.opacity(0.25), lineWidth: 1)
                                )
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(14)
                .background(.white.opacity(0.04))
                .cornerRadius(16)
                
                // Section 2: Form & Setup
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(suggestion.color)
                        Text("EXPECTED FORM & SETUP")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    ForEach(suggestion.formHints, id: \.self) { hint in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(suggestion.color)
                                .fontWeight(.black)
                            Text(hint)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(14)
                .background(.white.opacity(0.04))
                .cornerRadius(16)
                
                // Section 3: Load Strategy
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "gauge.with.needle")
                            .font(.system(size: 14))
                            .foregroundStyle(suggestion.color)
                        Text("LOAD STRATEGY")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    Text(suggestion.loadStrategy)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(.white.opacity(0.04))
                .cornerRadius(16)
                
                Spacer()
                
                // Dismiss button
                Button(action: { dismiss() }) {
                    Text("Got It")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(suggestion.color)
                        .cornerRadius(14)
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
    }
}

struct RestTimerView: View {
    let timeRemaining: Int
    let totalDuration: Int
    let tintColor: Color
    let isHighIntensity: Bool
    let nextSetPreview: String
    let onSkip: () -> Void
    let onAddSeconds: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 3)
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(timeRemaining) / CGFloat(totalDuration))
                        .stroke(tintColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: timeRemaining)
                    
                    Text("\(timeRemaining)s")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Rest Active")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        if isHighIntensity {
                            Text("🔥 High Intensity (+30s)")
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    Text("Next set in \(timeRemaining) seconds")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                Button(action: onAddSeconds) {
                    Text("+30s")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tintColor.opacity(0.2))
                        .cornerRadius(6)
                        .foregroundStyle(tintColor)
                }
                .buttonStyle(.plain)
            }
            
            // Faint, elegant ghost-text marquee/label for Next Set Preview
            Text(nextSetPreview)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .italic()
                .padding(.leading, 4)
                .padding(.top, 2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
