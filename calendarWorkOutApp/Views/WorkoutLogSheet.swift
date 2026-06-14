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
    @State private var title: String = ""
    @State private var category: WorkoutCategory = .strength
    @State private var date: Date
    @State private var durationMinutes: Int = 45
    @State private var notes: String = ""
    @State private var exercises: [Exercise] = []
    
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
    
    init(defaultDate: Date, editingWorkout: WorkoutSession? = nil) {
        self.defaultDate = defaultDate
        self.editingWorkout = editingWorkout
        
        if let editing = editingWorkout {
            _title = State(initialValue: editing.title)
            _category = State(initialValue: editing.category)
            _date = State(initialValue: editing.date)
            _durationMinutes = State(initialValue: editing.durationMinutes)
            _notes = State(initialValue: editing.notes)
            
            var filteredExercises = editing.exercises.filter { $0.name != "Calf Raises" && $0.name != "Leg raises" }
            for i in 0..<filteredExercises.count {
                if filteredExercises[i].name == "Dumbbell Lunges" || filteredExercises[i].name == "Squats" {
                    filteredExercises[i].name = ""
                }
            }
            _exercises = State(initialValue: filteredExercises)
        } else {
            _date = State(initialValue: defaultDate)
            _exercises = State(initialValue: [
                Exercise(name: "", sets: [ExerciseSet(weight: 0, reps: 10)])
            ])
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("WORKOUT DETAILS").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.6))) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                    
                    Stepper(value: $durationMinutes, in: 5...300, step: 5) {
                        HStack {
                            Text("Duration:")
                            Text("\(durationMinutes) mins")
                                .fontWeight(.bold)
                                .foregroundColor(category.color)
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.08))
                
                Section(header: Text("EXERCISES").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.6))) {
                    // Quick-add Exercise interface (Search & Suggestions section sits right ABOVE active logged exercises)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Exercise name...", text: $newExerciseName)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .textFieldStyle(.plain)
                                .foregroundStyle(.white)
                                .padding(.vertical, 6)
                            
                            Button(action: addNewExercise) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(category.color)
                            }
                            .disabled(newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        
                        // Intelligent fuzzy suggestions list
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filteredSuggestions, id: \.self) { sug in
                                    Button(action: {
                                        newExerciseName = sug
                                    }) {
                                        Text(sug)
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(category.color.opacity(0.15))
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(category.color.opacity(0.3), lineWidth: 1)
                                            )
                                            .foregroundStyle(.white)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.vertical, 8)

                    // Active logged exercise sets section (at the bottom)
                    if exercises.isEmpty {
                        Text("No exercises added yet.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.vertical, 8)
                    } else {
                        ForEach($exercises) { $exercise in
                            VStack(alignment: .leading, spacing: 8) {
                                // Sets list
                                ForEach($exercise.sets) { $set in
                                    HStack(spacing: 12) {
                                        Text("Set")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.5))
                                        
                                        TextField("Lbs", value: $set.weight, formatter: NumberFormatter())
                                            .keyboardType(.decimalPad)
                                            .frame(width: 60)
                                            .textFieldStyle(.plain)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Color.white.opacity(0.12))
                                            .cornerRadius(6)
                                        
                                        Text("lbs")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.5))
                                        
                                        TextField("Reps", value: $set.reps, formatter: NumberFormatter())
                                            .keyboardType(.numberPad)
                                            .frame(width: 50)
                                            .textFieldStyle(.plain)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Color.white.opacity(0.12))
                                            .cornerRadius(6)
                                        
                                        Text("reps")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.5))
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            set.isCompleted.toggle()
                                        }) {
                                            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 20))
                                                .foregroundStyle(set.isCompleted ? category.color : .white.opacity(0.4))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.leading, 8)
                                }
                                
                                HStack {
                                    Button(action: {
                                        let lastWeight = exercise.sets.last?.weight ?? 0
                                        let lastReps = exercise.sets.last?.reps ?? 10
                                        exercise.sets.append(ExerciseSet(weight: lastWeight, reps: lastReps))
                                    }) {
                                        Label("Add Set", systemImage: "plus")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(category.color)
                                    }
                                    .buttonStyle(.borderless)
                                    
                                    Spacer()
                                    
                                    if exercise.sets.count > 1 {
                                        Button(action: {
                                            if !exercise.sets.isEmpty {
                                                _ = exercise.sets.popLast()
                                            }
                                        }) {
                                            Text("Remove Set")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(.red.opacity(0.8))
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.08))
                
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
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWorkoutSession()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(category.color)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func addNewExercise() {
        let name = newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        let newExercise = Exercise(name: name, sets: [
            ExerciseSet(weight: 0, reps: 10)
        ])
        exercises.append(newExercise)
        newExerciseName = ""
    }
    
    private func saveWorkoutSession() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? "\(category.rawValue) Session" : trimmedTitle
        
        if let editing = editingWorkout {
            let updated = WorkoutSession(
                id: editing.id,
                title: finalTitle,
                date: date,
                category: category,
                notes: notes,
                exercises: exercises,
                durationMinutes: durationMinutes
            )
            workoutManager.updateWorkout(updated)
        } else {
            let workout = WorkoutSession(
                title: finalTitle,
                date: date,
                category: category,
                notes: notes,
                exercises: exercises,
                durationMinutes: durationMinutes
            )
            workoutManager.addWorkout(workout)
        }
        dismiss()
    }
}
