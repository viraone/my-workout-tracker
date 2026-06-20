import SwiftUI

struct SetInput: Identifiable {
    let id = UUID()
    var weight: String = ""
    var reps: String = ""
    var isCompleted: Bool = false
}

struct IndividualExerciseEditSheet: View {
    let workout: WorkoutSession
    let exercise: Exercise
    let isEditMode: Bool
    var onSave: (Exercise) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var workoutManager: WorkoutManager
    @State private var name: String
    @State private var setsList: [SetInput]
    @State private var notes: String
    @State private var isSaving = false
    
    // Active Rest Timer State
    @State private var activeTimerSetId: UUID? = nil
    @State private var restTimeRemaining: Int = 90
    @State private var timerSubscription: Timer? = nil
    @State private var isHighIntensityTimerActive: Bool = false
    @State private var timerTotalDuration: Int = 90
    
    private func getNextSetPreviewText(currentIndex: Int) -> String {
        let nextIndex = currentIndex + 1
        if nextIndex < setsList.count {
            let nextSet = setsList[nextIndex]
            let weightVal = nextSet.weight.trimmingCharacters(in: .whitespacesAndNewlines)
            let repsVal = nextSet.reps.trimmingCharacters(in: .whitespacesAndNewlines)
            let weightText = !weightVal.isEmpty ? "\(weightVal)lbs " : ""
            let repsText = !repsVal.isEmpty ? "\(repsVal) reps" : "reps"
            let motivationalQuote = nextIndex == setsList.count - 1 ? "Finish strong!" : "Focus on explosive tempo."
            return "Up Next: Set \(nextIndex + 1) — Target \(weightText)x \(repsText). \(motivationalQuote)"
        } else {
            return "Exercise Complete! Great job."
        }
    }
    
    private func startRestTimer(for setId: UUID, duration: Int, highIntensity: Bool) {
        stopRestTimer()
        activeTimerSetId = setId
        timerTotalDuration = duration
        restTimeRemaining = duration
        isHighIntensityTimerActive = highIntensity
        
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
        activeTimerSetId = nil
    }
    
    init(workout: WorkoutSession, exercise: Exercise, isEditMode: Bool = true, onSave: @escaping (Exercise) -> Void) {
        self.workout = workout
        self.exercise = exercise
        self.isEditMode = isEditMode
        self.onSave = onSave
        
        _name = State(initialValue: exercise.name)
        _notes = State(initialValue: exercise.notes)
        
        if isEditMode {
            let mapped = exercise.sets.map { set in
                SetInput(
                    weight: set.weight > 0 ? "\(Int(set.weight))" : "",
                    reps: set.reps > 0 ? "\(set.reps)" : "",
                    isCompleted: false // Requirement 1: Remove pre-checked or completed states when sheet opens
                )
            }
            _setsList = State(initialValue: mapped.isEmpty ? [SetInput(weight: "", reps: "", isCompleted: false)] : mapped)
        } else {
            _setsList = State(initialValue: [SetInput(weight: "", reps: "", isCompleted: false)])
        }
    }
    
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
                // Header with cancel and save
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .disabled(isSaving)
                    
                    Spacer()
                    
                    Text(isEditMode ? "Edit Exercise" : "Add Custom Exercise")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        Task {
                            guard !isSaving else { return }
                            isSaving = true
                            defer { isSaving = false }

                            let validatedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !validatedName.isEmpty else { return }

                            let finalSets = setsList.map { input in
                                let parsedWeight = Double(input.weight.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
                                let parsedReps = Int(input.reps.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 10
                                return ExerciseSet(weight: parsedWeight, reps: parsedReps, isCompleted: input.isCompleted)
                            }

                            var updatedExercise = exercise
                            updatedExercise.name = validatedName
                            updatedExercise.sets = finalSets
                            updatedExercise.notes = notes

                            if await workoutManager.saveExercise(updatedExercise, in: workout) {
                                onSave(updatedExercise)
                                dismiss()
                            }
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(workout.category.color)
                        } else {
                            Text("Save")
                        }
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(workout.category.color)
                    .disabled(isSaving)
                }
                .padding(.top, 20)
                
                // Exercise Name Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("EXERCISE NAME")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .kerning(1.1)
                    
                    HStack {
                        TextField("Exercise name...", text: $name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(isEditMode ? .white.opacity(0.6) : .white)
                            .disabled(isEditMode) // Prevent edit of existing exercise names to maintain data integrity
                        
                        if isEditMode {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .padding(12)
                    .background(isEditMode ? Color.white.opacity(0.04) : Color.white.opacity(0.08))
                    .cornerRadius(12)
                }
                
                // Sets Section
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("SETS")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                                .kerning(1.1)
                            Spacer()
                        }
                        
                        // Column Sub-Header
                        HStack(spacing: 12) {
                            // Align with the "Set X" labels below
                            Spacer()
                                .frame(width: 45)
                            
                            Text("LBS")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(width: 80, alignment: .center)
                            
                            Spacer()
                            
                            Text("REPS")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(width: 75, alignment: .center)
                            
                            Spacer()
                            
                            // Align with the action buttons tray below
                            Spacer()
                                .frame(width: 85)
                        }
                        .padding(.bottom, -4)
                        
                        ForEach(Array(setsList.enumerated()), id: \.element.id) { index, _ in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 12) {
                                    Text("Set \(index + 1)")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.6))
                                        .frame(width: 45, alignment: .leading)
                                    
                                    // Weight textfield with embedded steppers
                                    HStack(spacing: 0) {
                                        // Minus Button
                                        Image(systemName: "minus")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.black.opacity(0.6))
                                            .frame(width: 22, height: 32)
                                            .contentShape(Rectangle())
                                            .modifier(RepeatingHoldGesture(action: {
                                                adjustWeight(at: index, by: -5.0)
                                            }))
                                        
                                        TextField("lbs", text: $setsList[index].weight)
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.center)
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(.black)
                                            .frame(width: 36, height: 32)
                                        
                                        // Plus Button
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.black.opacity(0.6))
                                            .frame(width: 22, height: 32)
                                            .contentShape(Rectangle())
                                            .modifier(RepeatingHoldGesture(action: {
                                                adjustWeight(at: index, by: 5.0)
                                            }))
                                    }
                                    .background(Color.white)
                                    .cornerRadius(6)
                                    .frame(width: 80, height: 32)
                                    
                                    Spacer()
                                    
                                    // Reps textfield with embedded steppers
                                    HStack(spacing: 0) {
                                        // Minus Button
                                        Image(systemName: "minus")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.black.opacity(0.6))
                                            .frame(width: 20, height: 32)
                                            .contentShape(Rectangle())
                                            .modifier(RepeatingHoldGesture(action: {
                                                adjustReps(at: index, by: -1)
                                            }))
                                        
                                        TextField("reps", text: $setsList[index].reps)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.center)
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(.black)
                                            .frame(width: 35, height: 32)
                                        
                                        // Plus Button
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.black.opacity(0.6))
                                            .frame(width: 20, height: 32)
                                            .contentShape(Rectangle())
                                            .modifier(RepeatingHoldGesture(action: {
                                                adjustReps(at: index, by: 1)
                                            }))
                                    }
                                    .background(Color.white)
                                    .cornerRadius(6)
                                    .frame(width: 75, height: 32)
                                    
                                    Spacer()
                                    
                                    // 3-Button Interaction Container (Checkmark, Undo/Reset, Trash)
                                    HStack(spacing: 8) {
                                        // 1. Green Checkmark Button (checkmark.circle.fill): Toggles status to completed
                                        Button(action: {
                                            if !setsList[index].isCompleted {
                                                setsList[index].isCompleted = true
                                                let parsedWeight = Double(setsList[index].weight.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
                                                let isHighIntensity = parsedWeight >= 45.0 || index == setsList.count - 1
                                                let duration = isHighIntensity ? 120 : 90
                                                startRestTimer(for: setsList[index].id, duration: duration, highIntensity: isHighIntensity)
                                            }
                                        }) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(setsList[index].isCompleted ? .green : .white.opacity(0.25))
                                                .padding(5)
                                                .background(setsList[index].isCompleted ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        
                                        // 2. Undo Button (arrow.counterclockwise.circle.fill): Toggles completed back to uncompleted
                                        Button(action: {
                                            if setsList[index].isCompleted {
                                                setsList[index].isCompleted = false
                                                if activeTimerSetId == setsList[index].id {
                                                    stopRestTimer()
                                                }
                                            }
                                        }) {
                                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(setsList[index].isCompleted ? .red : .white.opacity(0.15))
                                                .padding(5)
                                                .background(setsList[index].isCompleted ? Color.red.opacity(0.15) : Color.white.opacity(0.02))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(!setsList[index].isCompleted)
                                        
                                        // 3. Trash Can Button (trash.circle.fill): Immediately removes that specific set row
                                        Button(action: {
                                            if activeTimerSetId == setsList[index].id {
                                                stopRestTimer()
                                            }
                                            setsList.remove(at: index)
                                        }) {
                                            Image(systemName: "trash.circle.fill")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(.red.opacity(0.8))
                                                .padding(5)
                                                .background(Color.red.opacity(0.12))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(12)
                                
                                // Rest Timer View inline beneath the active row
                                if activeTimerSetId == setsList[index].id && restTimeRemaining > 0 {
                                    RestTimerView(
                                        timeRemaining: restTimeRemaining,
                                        totalDuration: timerTotalDuration,
                                        tintColor: workout.category.color,
                                        isHighIntensity: isHighIntensityTimerActive,
                                        nextSetPreview: getNextSetPreviewText(currentIndex: index),
                                        onSkip: {
                                            stopRestTimer()
                                        },
                                        onAddSeconds: {
                                            restTimeRemaining += 30
                                        }
                                    )
                                    .padding(.top, 4)
                                    .transition(.opacity.combined(with: .scale))
                                }
                            }
                        }
                        
                        // Add / Remove Set buttons
                        HStack {
                            Button(action: {
                                let lastWeight = setsList.last?.weight ?? ""
                                let lastReps = setsList.last?.reps ?? ""
                                setsList.append(SetInput(weight: lastWeight, reps: lastReps, isCompleted: false))
                            }) {
                                Label("Add Set", systemImage: "plus")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(workout.category.color)
                            }
                            .buttonStyle(.borderless)
                            
                            Spacer()
                            
                            if setsList.count > 1 {
                                Button(action: {
                                    _ = setsList.popLast()
                                }) {
                                    Label("Remove Set", systemImage: "minus")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.red.opacity(0.8))
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.top, 4)
                        
                        // Notes Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EXERCISE NOTES")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                                .kerning(1.1)
                                .padding(.top, 12)
                            
                            TextField("Any exercise notes...", text: $notes)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .onChange(of: exercise.id) { _, _ in
                // Cleanly wipe and re-initialize view states on exercise ID changes
                name = exercise.name
                notes = exercise.notes
                let mapped = exercise.sets.map { set in
                    SetInput(
                        weight: set.weight > 0 ? "\(Int(set.weight))" : "",
                        reps: set.reps > 0 ? "\(set.reps)" : "",
                        isCompleted: false
                    )
                }
                setsList = mapped.isEmpty ? [SetInput(weight: "", reps: "", isCompleted: false)] : mapped
                stopRestTimer()
            }
        }
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
            Text(workoutManager.errorMessage ?? "The exercise could not be saved.")
        }
    }
    
    private func adjustWeight(at index: Int, by delta: Double) {
        guard index < setsList.count else { return }
        let currentString = setsList[index].weight.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentWeight = Double(currentString) ?? 0.0
        let newWeight = max(0.0, currentWeight + delta)
        setsList[index].weight = newWeight > 0 ? "\(Int(newWeight))" : ""
        triggerHaptic()
    }
    
    private func adjustReps(at index: Int, by delta: Int) {
        guard index < setsList.count else { return }
        let currentString = setsList[index].reps.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentReps = Int(currentString) ?? 0
        let newReps = max(0, currentReps + delta)
        setsList[index].reps = newReps > 0 ? "\(newReps)" : ""
        triggerHaptic()
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}

struct RepeatingHoldGesture: ViewModifier {
    let action: () -> Void
    
    @State private var timer: Timer? = nil
    @State private var isPressing = false
    @State private var delayTimer: Timer? = nil
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressing {
                            isPressing = true
                            action()
                            
                            delayTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                                    action()
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        isPressing = false
                        delayTimer?.invalidate()
                        delayTimer = nil
                        timer?.invalidate()
                        timer = nil
                    }
            )
    }
}

struct ExerciseEditItem: Identifiable {
    var id: UUID { exercise.id }
    let workout: WorkoutSession
    let exercise: Exercise
    let isEditMode: Bool
}
