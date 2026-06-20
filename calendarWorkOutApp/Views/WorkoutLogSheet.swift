import SwiftUI

struct ExerciseMetadata {
    let name: String
    let muscles: [String]
    let equipment: [String]
    let alternateSpellings: [String]
    let keywords: [String]
}

struct WorkoutLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    
    let defaultDate: Date
    let editingWorkout: WorkoutSession?
    let draftWorkoutID: UUID
    @State private var title: String = ""
    @State private var category: WorkoutCategory = .strength
    @State private var date: Date
    @State private var durationMinutes: Int = 45
    @State private var notes: String = ""
    @State private var exercises: [Exercise] = []
    @State private var expandedExerciseIDs: Set<UUID> = []
    @State private var removedExerciseIDs: Set<UUID> = []
    @State private var isSaving = false
    
    // Exercise input state
    @State private var newExerciseName: String = ""
    
    private let exerciseDatabase = [
        ExerciseMetadata(
            name: "Bench Press",
            muscles: ["chest", "pecs", "triceps", "shoulders", "arms"],
            equipment: ["barbell", "bench"],
            alternateSpellings: ["benchpres", "benchpress", "chest press", "pec press"],
            keywords: ["push", "upper body"]
        ),
        ExerciseMetadata(
            name: "Squats",
            muscles: ["quads", "quadriceps", "glutes", "hamstrings", "legs", "thighs"],
            equipment: ["barbell", "bodyweight", "rack"],
            alternateSpellings: ["squat", "skwat", "squats"],
            keywords: ["legs", "lower body"]
        ),
        ExerciseMetadata(
            name: "Deadlifts",
            muscles: ["back", "hamstrings", "glutes", "legs", "spinal erectors"],
            equipment: ["barbell"],
            alternateSpellings: ["deadlift", "dedlift", "dead lifts"],
            keywords: ["pull", "posterior chain", "lower body"]
        ),
        ExerciseMetadata(
            name: "Shoulder Press",
            muscles: ["shoulders", "deltoids", "delts", "triceps", "arms"],
            equipment: ["barbell", "dumbbell"],
            alternateSpellings: ["shoulderpress", "military press", "overhead press", "ohp"],
            keywords: ["push", "upper body"]
        ),
        ExerciseMetadata(
            name: "Bicep Curls",
            muscles: ["biceps", "arms"],
            equipment: ["dumbbell", "barbell", "cables"],
            alternateSpellings: ["bicepcurl", "arm curls", "curls"],
            keywords: ["pull", "upper body"]
        ),
        ExerciseMetadata(
            name: "Tricep Pushdowns",
            muscles: ["triceps", "arms"],
            equipment: ["cable", "rope"],
            alternateSpellings: ["triceppushdown", "tricep extensions", "pushdowns"],
            keywords: ["push", "upper body"]
        ),
        ExerciseMetadata(
            name: "Dumbbell Lunges",
            muscles: ["quads", "quadriceps", "glutes", "hamstrings", "legs"],
            equipment: ["dumbbell"],
            alternateSpellings: ["lunges", "db lunges", "dumbell lunge"],
            keywords: ["legs", "lower body"]
        ),
        ExerciseMetadata(
            name: "Calf Raises",
            muscles: ["calves", "calf", "legs", "lower legs"],
            equipment: ["bodyweight", "dumbbell", "machine"],
            alternateSpellings: ["calfs", "calfraises", "calf raise"],
            keywords: ["legs", "lower body"]
        ),
        ExerciseMetadata(
            name: "Dumbbell Bicep Curls",
            muscles: ["biceps", "arms"],
            equipment: ["dumbbell"],
            alternateSpellings: ["db curls", "dumbell curls"],
            keywords: ["pull", "upper body"]
        ),
        ExerciseMetadata(
            name: "Dumbbell Shoulder Press",
            muscles: ["shoulders", "delts", "arms"],
            equipment: ["dumbbell"],
            alternateSpellings: ["db press", "dumbell press", "db shoulder"],
            keywords: ["push", "upper body"]
        ),
        ExerciseMetadata(
            name: "Dumbbell Bench Press",
            muscles: ["chest", "pecs", "triceps", "arms"],
            equipment: ["dumbbell"],
            alternateSpellings: ["db bench", "dumbell bench"],
            keywords: ["push", "upper body"]
        ),
        ExerciseMetadata(
            name: "Dumbbell Rows",
            muscles: ["back", "lats", "biceps", "arms"],
            equipment: ["dumbbell"],
            alternateSpellings: ["db row", "dumbell row"],
            keywords: ["pull", "upper body"]
        ),
        ExerciseMetadata(
            name: "Dumbbell Lateral Raises",
            muscles: ["shoulders", "delts", "arms"],
            equipment: ["dumbbell"],
            alternateSpellings: ["lateral raises", "db lateral", "side raises"],
            keywords: ["upper body"]
        ),
        ExerciseMetadata(
            name: "Dumbbell Hammer Curls",
            muscles: ["biceps", "forearms", "arms"],
            equipment: ["dumbbell"],
            alternateSpellings: ["hammer curls", "db hammer"],
            keywords: ["pull", "upper body"]
        ),
        ExerciseMetadata(
            name: "Dumbbell Flyes",
            muscles: ["chest", "pecs"],
            equipment: ["dumbbell"],
            alternateSpellings: ["db flyes", "dumbell fly", "chest flyes"],
            keywords: ["upper body"]
        ),
        ExerciseMetadata(
            name: "Barbell Bench Press",
            muscles: ["chest", "pecs", "triceps", "shoulders", "arms"],
            equipment: ["barbell"],
            alternateSpellings: ["bb bench", "barbell bench"],
            keywords: ["push", "upper body"]
        ),
        ExerciseMetadata(
            name: "Barbell Squats",
            muscles: ["quads", "quadriceps", "glutes", "hamstrings", "legs"],
            equipment: ["barbell"],
            alternateSpellings: ["bb squats", "barbell squat"],
            keywords: ["legs", "lower body"]
        ),
        ExerciseMetadata(
            name: "Barbell Deadlifts",
            muscles: ["back", "hamstrings", "glutes", "legs"],
            equipment: ["barbell"],
            alternateSpellings: ["bb deadlift", "barbell deadlift"],
            keywords: ["pull", "lower body"]
        ),
        ExerciseMetadata(
            name: "Barbell Shoulder Press",
            muscles: ["shoulders", "delts", "triceps", "arms"],
            equipment: ["barbell"],
            alternateSpellings: ["bb shoulder", "barbell press"],
            keywords: ["push", "upper body"]
        ),
        ExerciseMetadata(
            name: "Barbell Rows",
            muscles: ["back", "lats", "biceps", "arms"],
            equipment: ["barbell"],
            alternateSpellings: ["bb rows", "barbell row"],
            keywords: ["pull", "upper body"]
        ),
        ExerciseMetadata(
            name: "Barbell Bicep Curls",
            muscles: ["biceps", "arms"],
            equipment: ["barbell"],
            alternateSpellings: ["bb curls", "barbell curl"],
            keywords: ["pull", "upper body"]
        ),
        ExerciseMetadata(
            name: "Leg raises",
            muscles: ["abs", "core", "abdominal", "stomach"],
            equipment: ["bodyweight"],
            alternateSpellings: ["legraises", "legraise", "leg lift"],
            keywords: ["core"]
        ),
        ExerciseMetadata(
            name: "Plank",
            muscles: ["abs", "core", "abdominal", "full body"],
            equipment: ["bodyweight"],
            alternateSpellings: ["planks", "plank hold"],
            keywords: ["core"]
        ),
        ExerciseMetadata(
            name: "Burpees",
            muscles: ["full body", "cardio", "legs", "chest"],
            equipment: ["bodyweight"],
            alternateSpellings: ["burpee", "burpy"],
            keywords: ["cardio", "hiit"]
        ),
        ExerciseMetadata(
            name: "Mountain Climbers",
            muscles: ["abs", "core", "cardio", "shoulders"],
            equipment: ["bodyweight"],
            alternateSpellings: ["mountainclimbers", "climbers"],
            keywords: ["cardio", "hiit", "core"]
        ),
        ExerciseMetadata(
            name: "Bicycle Crunches",
            muscles: ["abs", "core", "obliques"],
            equipment: ["bodyweight"],
            alternateSpellings: ["bicycle crunch", "bicycles"],
            keywords: ["core"]
        ),
        ExerciseMetadata(
            name: "Russian Twists",
            muscles: ["abs", "core", "obliques"],
            equipment: ["bodyweight", "medicine ball"],
            alternateSpellings: ["russiantwist", "twists"],
            keywords: ["core"]
        ),
        ExerciseMetadata(
            name: "Hanging Leg Raises",
            muscles: ["abs", "core", "grip"],
            equipment: ["pull-up bar"],
            alternateSpellings: ["hanging leg", "hanging leg raise"],
            keywords: ["core"]
        ),
        ExerciseMetadata(
            name: "Leg Press",
            muscles: ["quads", "quadriceps", "glutes", "hamstrings", "legs"],
            equipment: ["machine"],
            alternateSpellings: ["legpress", "sled press"],
            keywords: ["legs", "lower body"]
        ),
        ExerciseMetadata(
            name: "Leg Extension",
            muscles: ["quads", "quadriceps", "legs"],
            equipment: ["machine"],
            alternateSpellings: ["legextension", "extensions"],
            keywords: ["legs", "lower body"]
        ),
        ExerciseMetadata(
            name: "Hamstring Curls",
            muscles: ["hamstrings", "legs"],
            equipment: ["machine"],
            alternateSpellings: ["leg curls", "hamstring curl"],
            keywords: ["legs", "lower body"]
        ),
        ExerciseMetadata(
            name: "Walking Lunges",
            muscles: ["quads", "quadriceps", "glutes", "hamstrings", "legs"],
            equipment: ["bodyweight", "dumbbell"],
            alternateSpellings: ["walking lunge", "lunges"],
            keywords: ["legs", "lower body"]
        ),
        ExerciseMetadata(
            name: "Goblet Squats",
            muscles: ["quads", "quadriceps", "glutes", "legs"],
            equipment: ["dumbbell", "kettlebell"],
            alternateSpellings: ["goblet squat", "kettlebell squat"],
            keywords: ["legs", "lower body"]
        ),
        ExerciseMetadata(
            name: "Outdoor Run",
            muscles: ["legs", "cardio", "heart"],
            equipment: ["bodyweight"],
            alternateSpellings: ["running", "jogging", "run"],
            keywords: ["cardio"]
        ),
        ExerciseMetadata(
            name: "Treadmill Run",
            muscles: ["legs", "cardio"],
            equipment: ["treadmill"],
            alternateSpellings: ["treadmill", "indoor run"],
            keywords: ["cardio"]
        ),
        ExerciseMetadata(
            name: "Cycling",
            muscles: ["legs", "quads", "cardio"],
            equipment: ["bike", "stationary bike"],
            alternateSpellings: ["cycle", "biking", "spin class"],
            keywords: ["cardio"]
        ),
        ExerciseMetadata(
            name: "Elliptical",
            muscles: ["legs", "arms", "cardio"],
            equipment: ["elliptical machine"],
            alternateSpellings: ["elliptical trainer"],
            keywords: ["cardio"]
        ),
        ExerciseMetadata(
            name: "Swimming",
            muscles: ["full body", "back", "shoulders", "cardio"],
            equipment: ["pool"],
            alternateSpellings: ["swim", "swimming laps"],
            keywords: ["cardio"]
        ),
        ExerciseMetadata(
            name: "Stair Climber",
            muscles: ["legs", "glutes", "calves", "cardio"],
            equipment: ["stairmaster", "machine"],
            alternateSpellings: ["stairs", "stair climbing"],
            keywords: ["cardio"]
        ),
        ExerciseMetadata(
            name: "Rowing Machine",
            muscles: ["back", "legs", "arms", "cardio"],
            equipment: ["rower"],
            alternateSpellings: ["rowing", "row"],
            keywords: ["cardio"]
        ),
        ExerciseMetadata(
            name: "Pushups",
            muscles: ["chest", "pecs", "triceps", "shoulders", "arms"],
            equipment: ["bodyweight"],
            alternateSpellings: ["pushups", "push-ups", "push up"],
            keywords: ["push", "upper body"]
        ),
        ExerciseMetadata(
            name: "Pull-ups",
            muscles: ["back", "lats", "biceps", "arms"],
            equipment: ["pull-up bar"],
            alternateSpellings: ["pullups", "pull ups", "pull up"],
            keywords: ["pull", "upper body"]
        ),
        ExerciseMetadata(
            name: "Chin-ups",
            muscles: ["biceps", "back", "lats", "arms"],
            equipment: ["pull-up bar"],
            alternateSpellings: ["chinups", "chin ups", "chin up"],
            keywords: ["pull", "upper body"]
        ),
        ExerciseMetadata(
            name: "Dips",
            muscles: ["triceps", "chest", "shoulders", "arms"],
            equipment: ["parallel bars", "bench"],
            alternateSpellings: ["chest dips", "tricep dips"],
            keywords: ["push", "upper body"]
        ),
        ExerciseMetadata(
            name: "Kettlebell Swings",
            muscles: ["glutes", "hamstrings", "back", "hips"],
            equipment: ["kettlebell"],
            alternateSpellings: ["kb swing", "kettlebell swing"],
            keywords: ["cardio", "hiit", "posterior chain"]
        ),
        ExerciseMetadata(
            name: "Jumping Jacks",
            muscles: ["full body", "cardio"],
            equipment: ["bodyweight"],
            alternateSpellings: ["jumpingjacks", "jacks"],
            keywords: ["cardio", "hiit"]
        ),
        ExerciseMetadata(
            name: "Plank Jacks",
            muscles: ["core", "abs", "cardio"],
            equipment: ["bodyweight"],
            alternateSpellings: ["plankjacks"],
            keywords: ["cardio", "hiit", "core"]
        ),
        ExerciseMetadata(
            name: "Tricep Pushdowns",
            muscles: ["triceps", "arms"],
            equipment: ["cable"],
            alternateSpellings: ["cable pushdowns", "tricep pushdowns"],
            keywords: ["push", "upper body"]
        ),
        ExerciseMetadata(
            name: "Lat Pulldown",
            muscles: ["back", "lats", "biceps", "arms"],
            equipment: ["cable machine"],
            alternateSpellings: ["latpulldown", "pulldowns"],
            keywords: ["pull", "upper body"]
        )
    ]
    
    private func normalize(_ str: String) -> String {
        str.lowercased()
            .replacingOccurrences(of: "bb", with: "b")
            .replacingOccurrences(of: "ll", with: "l")
            .replacingOccurrences(of: "pp", with: "p")
            .replacingOccurrences(of: "ss", with: "s")
            .replacingOccurrences(of: "cc", with: "c")
            .replacingOccurrences(of: "rr", with: "r")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
    
    private var filteredSuggestions: [String] {
        let input = newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            return category.suggestions
        }
        
        let lowerInput = input.lowercased()
        let normInput = normalize(input)
        
        let scored = exerciseDatabase.compactMap { metadata -> (String, Int)? in
            let nameLower = metadata.name.lowercased()
            let nameNorm = normalize(metadata.name)
            
            // 1. Direct name substring / exact match (highest priority)
            if nameLower == lowerInput {
                return (metadata.name, 0)
            }
            if nameLower.hasPrefix(lowerInput) {
                return (metadata.name, 1)
            }
            if nameLower.contains(lowerInput) {
                return (metadata.name, 2)
            }
            
            // 2. Alternate spellings or exact phonetic match
            for alt in metadata.alternateSpellings {
                let altLower = alt.lowercased()
                if altLower == lowerInput || altLower.hasPrefix(lowerInput) || altLower.contains(lowerInput) {
                    return (metadata.name, 3)
                }
                if normalize(alt).contains(normInput) {
                    return (metadata.name, 4)
                }
            }
            
            // 3. Normalized name match
            if nameNorm.contains(normInput) {
                return (metadata.name, 4)
            }
            
            // 4. Semantic / Muscle Group match
            for muscle in metadata.muscles {
                if muscle == lowerInput || lowerInput.contains(muscle) || muscle.contains(lowerInput) {
                    return (metadata.name, 5)
                }
            }
            
            // 5. Equipment match
            for equip in metadata.equipment {
                if equip == lowerInput || lowerInput.contains(equip) || equip.contains(lowerInput) {
                    return (metadata.name, 6)
                }
            }
            
            // 6. Keywords match
            for kw in metadata.keywords {
                if kw == lowerInput || lowerInput.contains(kw) || kw.contains(lowerInput) {
                    return (metadata.name, 7)
                }
            }
            
            // 7. Typo-tolerant character overlap
            let inputChars = Set(lowerInput)
            let nameChars = Set(nameLower)
            let intersection = inputChars.intersection(nameChars)
            if lowerInput.count >= 3 && Double(intersection.count) / Double(inputChars.count) >= 0.75 {
                return (metadata.name, 8)
            }
            
            return nil
        }
        
        var seen = Set<String>()
        var uniqueScored: [(String, Int)] = []
        for item in scored {
            if !seen.contains(item.0) {
                seen.insert(item.0)
                uniqueScored.append(item)
            }
        }
        
        return uniqueScored
            .sorted { a, b in
                if a.1 == b.1 {
                    return a.0.count < b.0.count
                }
                return a.1 < b.1
            }
            .map { $0.0 }
    }
    
    init(
        defaultDate: Date,
        editingWorkout: WorkoutSession? = nil,
        draftWorkoutID: UUID = UUID()
    ) {
        self.defaultDate = defaultDate
        self.editingWorkout = editingWorkout
        self.draftWorkoutID = draftWorkoutID
        
        if let editing = editingWorkout {
            _title = State(initialValue: editing.title)
            _category = State(initialValue: editing.category)
            _date = State(initialValue: editing.date)
            _durationMinutes = State(initialValue: editing.durationMinutes)
            _notes = State(initialValue: editing.notes)
            
            var seenExerciseNames = Set<String>()
            let editableExercises = editing.exercises.compactMap { exercise -> Exercise? in
                let normalizedExercise = Self.normalizeExerciseForEntry(exercise)
                let normalizedName = Self.normalizedExerciseNameForComparison(normalizedExercise.name)
                guard !normalizedName.isEmpty,
                      seenExerciseNames.insert(normalizedName).inserted else {
                    return nil
                }
                return normalizedExercise
            }
            _exercises = State(initialValue: editableExercises)
            _expandedExerciseIDs = State(initialValue: Set(editableExercises.map(\.id)))
        } else {
            _date = State(initialValue: defaultDate)
            _exercises = State(initialValue: [])
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("WORKOUT DETAILS").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.6))) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                }
                .listRowBackground(Color.white.opacity(0.08))
                
                Section(header: Text("EXERCISES").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.6))) {
                    VStack(alignment: .leading, spacing: 14) {
                        exercisePicker

                        if exercises.isEmpty {
                            Text("No exercises yet")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        } else {
                            ForEach($exercises) { $exercise in
                                exerciseCard(exercise: $exercise)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                .listRowBackground(Color.clear)
                
                Section(header: Text("NOTES").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.6))) {
                    TextField("Any session notes, feelings, or details...", text: $notes, axis: .vertical)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(3...6)
                }
                .listRowBackground(Color.white.opacity(0.08))
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.8))
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await saveWorkoutSession()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(category.color)
                        } else {
                            Text("Save")
                        }
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(category.color)
                    .disabled(isSaving)
                }
            }
            .preferredColorScheme(.dark)
            .alert(
                "Workout Sync Error",
                isPresented: Binding(
                    get: { workoutManager.errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            DispatchQueue.main.async {
                                workoutManager.clearError()
                            }
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    workoutManager.clearError()
                }
            } message: {
                Text(workoutManager.errorMessage ?? "The workout could not be saved.")
            }
        }
    }

    private var exercisePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                TextField("Exercise name...", text: $newExerciseName)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .submitLabel(.done)
                    .onSubmit(addNewExercise)

                Button(action: addNewExercise) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(category.color)
                        .clipShape(Circle())
                }
                .disabled(newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filteredSuggestions.prefix(8), id: \.self) { suggestion in
                        Button {
                            addExercise(named: suggestion)
                        } label: {
                            Text(suggestion)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(category.color.opacity(0.14))
                                .foregroundStyle(.white)
                                .overlay(
                                    Capsule()
                                        .stroke(category.color.opacity(0.35), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func exerciseCard(exercise: Binding<Exercise>) -> some View {
        let exerciseID = exercise.wrappedValue.id
        let displayName = exerciseDisplayName(exercise.wrappedValue.name)
        let isExpanded = expandedExerciseIDs.contains(exerciseID)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    toggleExerciseExpansion(exerciseID)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(displayName)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(lastSessionText(for: displayName) ?? compactSetSummary(for: exercise.wrappedValue))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.48))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    removeExercise(exerciseID)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.42))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    toggleExerciseExpansion(exerciseID)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.12))

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(exercise.wrappedValue.sets.indices), id: \.self) { setIndex in
                        exerciseSetRow(exercise: exercise, setIndex: setIndex)

                        if setIndex != exercise.wrappedValue.sets.indices.last {
                            Divider()
                                .background(Color.white.opacity(0.08))
                        }
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.12))

                Button {
                    appendSet(to: exercise)
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Add Set")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(category.color.opacity(0.16))
                    .foregroundStyle(category.color)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isExpanded)
    }

    private func exerciseSetRow(exercise: Binding<Exercise>, setIndex: Int) -> some View {
        let set = Binding<ExerciseSet>(
            get: {
                guard exercise.wrappedValue.sets.indices.contains(setIndex) else {
                    return ExerciseSet(weight: 0, reps: 0)
                }
                return exercise.wrappedValue.sets[setIndex]
            },
            set: { newValue in
                guard exercise.wrappedValue.sets.indices.contains(setIndex) else { return }
                exercise.wrappedValue.sets[setIndex] = newValue
            }
        )

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("Set \(setIndex + 1)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    var updatedSet = set.wrappedValue
                    updatedSet.isCompleted.toggle()
                    set.wrappedValue = updatedSet
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: set.wrappedValue.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Complete")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(set.wrappedValue.isCompleted ? category.color : .white.opacity(0.55))
                }
                .buttonStyle(.plain)

                if exercise.wrappedValue.sets.count > 1 {
                    Button {
                        removeSet(from: exercise, at: setIndex)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.red.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                metricInput(title: "Weight", value: set.weight, unit: "lbs", formatter: weightFormatter)

                metricInput(title: "Reps", value: set.reps, unit: "reps", formatter: repsFormatter)
            }
        }
    }

    private func metricInput<Value>(
        title: String,
        value: Binding<Value>,
        unit: String,
        formatter: NumberFormatter
    ) -> some View where Value: Numeric {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))

            HStack(spacing: 6) {
                TextField("0", value: value, formatter: formatter)
                    .keyboardType(title == "Weight" ? .decimalPad : .numberPad)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 54)

                Text(unit)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private func addNewExercise() {
        addExercise(named: newExerciseName)
    }

    private func addExercise(named rawName: String) {
        let name = trimmedExerciseName(rawName)
        guard !name.isEmpty else { return }

        if let existingExercise = exercises.first(where: {
            normalizedExerciseName($0.name) == normalizedExerciseName(name)
        }) {
            expandedExerciseIDs.insert(existingExercise.id)
            newExerciseName = ""
            return
        }

        let newExercise = Exercise(name: name, sets: defaultSets(for: name))
        exercises.append(newExercise)
        expandedExerciseIDs.insert(newExercise.id)
        newExerciseName = ""
    }

    private func exerciseExists(named name: String, in exercises: [Exercise]? = nil) -> Bool {
        let normalizedName = normalizedExerciseName(name)
        guard !normalizedName.isEmpty else { return false }

        return (exercises ?? self.exercises).contains {
            normalizedExerciseName($0.name) == normalizedName
        }
    }

    private func trimmedExerciseName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedExerciseName(_ name: String) -> String {
        Self.normalizedExerciseNameForComparison(name)
    }

    private func appendSet(to exercise: Binding<Exercise>) {
        let templateSet = exercise.wrappedValue.sets.last ?? defaultSets(for: exercise.wrappedValue.name).first ?? ExerciseSet(weight: 25, reps: 5)
        exercise.wrappedValue.sets.append(ExerciseSet(
            weight: templateSet.weight,
            reps: templateSet.reps,
            isCompleted: false
        ))
    }

    private func removeSet(from exercise: Binding<Exercise>, at index: Int) {
        guard exercise.wrappedValue.sets.count > 1,
              exercise.wrappedValue.sets.indices.contains(index) else { return }
        exercise.wrappedValue.sets.remove(at: index)
    }

    private func removeExercise(_ exerciseID: UUID) {
        removedExerciseIDs.insert(exerciseID)
        exercises.removeAll { $0.id == exerciseID }
        expandedExerciseIDs.remove(exerciseID)
    }

    private func toggleExerciseExpansion(_ exerciseID: UUID) {
        if expandedExerciseIDs.contains(exerciseID) {
            expandedExerciseIDs.remove(exerciseID)
        } else {
            expandedExerciseIDs.insert(exerciseID)
        }
    }
    
    private func saveWorkoutSession() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? "\(category.rawValue) Session" : trimmedTitle
        let finalExercises = exercisesForSave()
        let workout = WorkoutSession(
            id: editingWorkout?.id ?? draftWorkoutID,
            title: finalTitle,
            date: date,
            category: category,
            notes: notes,
            exercises: finalExercises,
            durationMinutes: durationMinutes
        )

        let didSave = await workoutManager.saveWorkout(
            workout,
            mergeExistingExercises: editingWorkout != nil,
            removedExerciseIDs: removedExerciseIDs
        )

        if didSave {
            newExerciseName = ""
            dismiss()
        }
    }

    private func exercisesForSave() -> [Exercise] {
        var finalExercises: [Exercise] = []

        for exercise in exercises {
            var normalizedExercise = exercise
            normalizedExercise.name = trimmedExerciseName(exercise.name)
            guard !normalizedExercise.name.isEmpty else { continue }

            if normalizedExercise.sets.isEmpty {
                normalizedExercise.sets = defaultSets(for: normalizedExercise.name)
            }

            if !exerciseExists(named: normalizedExercise.name, in: finalExercises) {
                finalExercises.append(normalizedExercise)
            }
        }

        let pendingName = trimmedExerciseName(newExerciseName)
        guard !pendingName.isEmpty else { return finalExercises }

        if !exerciseExists(named: pendingName, in: finalExercises) {
            finalExercises.append(Exercise(name: pendingName, sets: defaultSets(for: pendingName)))
        }

        return finalExercises
    }

    private var weightFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }

    private var repsFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 0
        return formatter
    }

    private func defaultSets(for exerciseName: String) -> [ExerciseSet] {
        let usesBodyweight = exerciseDatabase.first { metadata in
            metadata.name.caseInsensitiveCompare(exerciseName) == .orderedSame
        }?.equipment.contains("bodyweight") == true

        let weight = usesBodyweight ? 0.0 : 25.0
        let reps = usesBodyweight ? 10 : 5
        return Self.defaultEntrySets(weight: weight, reps: reps)
    }

    private static func defaultEntrySets(weight: Double = 25.0, reps: Int = 5) -> [ExerciseSet] {
        (0..<3).map { _ in
            ExerciseSet(weight: weight, reps: reps)
        }
    }

    private static func normalizeExerciseForEntry(_ exercise: Exercise) -> Exercise {
        var normalizedExercise = exercise
        normalizedExercise.name = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedExercise.sets.isEmpty {
            normalizedExercise.sets = Self.defaultEntrySets()
        }
        return normalizedExercise
    }

    private static func normalizedExerciseNameForComparison(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func exerciseDisplayName(_ name: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Exercise" : trimmedName
    }

    private func lastSessionText(for exerciseName: String) -> String? {
        guard let previousExercise = lastExerciseSession(named: exerciseName),
              let representativeSet = previousExercise.sets.last ?? previousExercise.sets.first else { return nil }

        return "Last session: \(formattedWeight(representativeSet.weight)) lbs x \(representativeSet.reps) x \(previousExercise.sets.count)"
    }

    private func lastExerciseSession(named exerciseName: String) -> Exercise? {
        let targetName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !targetName.isEmpty else { return nil }

        return workoutManager.workouts
            .filter { workout in
                workout.id != editingWorkout?.id && workout.date < date
            }
            .sorted { $0.date > $1.date }
            .compactMap { workout in
                workout.exercises.first {
                    $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == targetName && !$0.sets.isEmpty
                }
            }
            .first
    }

    private func compactSetSummary(for exercise: Exercise) -> String {
        guard let firstSet = exercise.sets.first else { return "3 starter sets ready" }

        let allSame = exercise.sets.allSatisfy {
            $0.weight == firstSet.weight && $0.reps == firstSet.reps
        }

        if allSame {
            return "\(exercise.sets.count) sets - \(formattedWeight(firstSet.weight)) lbs x \(firstSet.reps)"
        } else {
            return "\(exercise.sets.count) sets - mixed targets"
        }
    }

    private func formattedWeight(_ weight: Double) -> String {
        let roundedWeight = weight.rounded()
        if abs(weight - roundedWeight) < 0.01 {
            return "\(Int(roundedWeight))"
        }
        return String(format: "%.1f", weight)
    }
}
