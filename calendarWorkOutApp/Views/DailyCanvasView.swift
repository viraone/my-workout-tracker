import SwiftUI
import EventKit

private struct WorkoutLogPresentation: Identifiable {
    let id = UUID()
    let defaultDate: Date
    let editingWorkout: WorkoutSession?
}

/// The main view of our application, combining a dynamic weather-responsive background canvas,
/// horizontal visual date selections, calendar event listings, and a highly detailed weather metrics drawer.
public struct DailyCanvasView: View {
    @State private var calendarManager = CalendarManager()
    @State private var weatherManager = WeatherManager()
    @State private var locationManager = LocationManager()
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var workoutLogPresentation: WorkoutLogPresentation?
    @State private var suggestedCategory: WorkoutCategory? = nil
    @State private var suggestedTitle: String = ""
    @State private var selectedExerciseItem: ExerciseEditItem? = nil
    
    @State private var selectedDate = Date()
    @State private var eventsForSelectedDate: [EKEvent] = []
    @State private var isLoading = false
    @State private var showEventEditSheet = false
    @State private var editingEvent: EKEvent? = nil
    
    // Dates for the horizontal date selector (today + next 14 days)
    private let dates: [Date] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<14).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // 1. Dynamic weather state representative background
            if let weather = weatherManager.currentForecast {
                DynamicWeatherBackground(symbolName: weather.symbolName)
                    .id("bg-\(weather.symbolName)")
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 1.0), value: weather.symbolName)
            } else {
                // Neutral state gradient before forecast loads
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.1, green: 0.15, blue: 0.25), Color(red: 0.02, green: 0.04, blue: 0.08)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            
            // 2. Main content layer (Weather-First Layout Reversal)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {
                    
                    // Header Status Info (City, Prominent Current Temperature, Condition)
                    headerSection
                        .padding(.top, 54)
                    
                    // Horizontal Day Bar Selector
                    DateSelectorBar(
                        dates: dates,
                        selectedDate: $selectedDate,
                        glowColor: weatherGlowColor(for: weatherManager.currentForecast?.symbolName ?? "")
                    )
                        .onChange(of: selectedDate) { _, newDate in
                            selectedExerciseItem = nil // Drop transient row models from view memory
                            Task {
                                await workoutManager.prepareWorkouts(for: newDate)
                                await refreshData(for: newDate)
                            }
                        }

                    // Daily Workouts List (Shows user logged workouts for today)
                    DailyWorkoutsListView(
                        date: selectedDate,
                        onLogWorkout: {
                            self.suggestedCategory = nil
                            self.suggestedTitle = ""
                            self.workoutLogPresentation = WorkoutLogPresentation(
                                defaultDate: selectedDate,
                                editingWorkout: nil
                            )
                        },
                        onDeleteWorkout: { workout in
                            Task {
                                await workoutManager.removeWorkout(workout)
                            }
                        },
                        onToggleExerciseSet: { workout, exerciseId, setId in
                            var updatedWorkout = workout
                            if let exerciseIndex = updatedWorkout.exercises.firstIndex(where: { $0.id == exerciseId }) {
                                if let setIndex = updatedWorkout.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setId }) {
                                    updatedWorkout.exercises[exerciseIndex].sets[setIndex].isCompleted.toggle()
                                    Task {
                                        await workoutManager.updateWorkout(updatedWorkout)
                                    }
                                }
                            }
                        },
                        onSelectWorkout: { workout in
                            self.workoutLogPresentation = WorkoutLogPresentation(
                                defaultDate: workout.date,
                                editingWorkout: workout
                            )
                        },
                        onToggleExerciseAllSets: { workout, exerciseId, isCompleted in
                            var updatedWorkout = workout
                            if let exerciseIndex = updatedWorkout.exercises.firstIndex(where: { $0.id == exerciseId }) {
                                for setIndex in updatedWorkout.exercises[exerciseIndex].sets.indices {
                                    updatedWorkout.exercises[exerciseIndex].sets[setIndex].isCompleted = isCompleted
                                }
                                Task {
                                    await workoutManager.updateWorkout(updatedWorkout)
                                }
                            }
                        },
                        onSelectExercise: { workout, exercise, isEditMode in
                            self.selectedExerciseItem = ExerciseEditItem(workout: workout, exercise: exercise, isEditMode: isEditMode)
                        },
                        glowColor: weatherGlowColor(for: weatherManager.currentForecast?.symbolName ?? "")
                    )
                    .id("workouts-list-\(selectedDate.timeIntervalSince1970)")
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
                    .padding(.horizontal)
                    
                    // Standalone Tomorrow's AI Preview Card
                    if let todayWorkSession = workoutManager.workouts(for: selectedDate).first(where: { $0.title == "Today Work" }) {
                        TomorrowsPreviewCard(workout: todayWorkSession)
                            .id("tomorrows-preview-\(selectedDate.timeIntervalSince1970)")
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity
                            ))
                            .padding(.horizontal)
                    }

                    if isLoading {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.3)
                                .padding(.vertical, 28)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    } else if let weather = weatherManager.currentForecast {
                        OutdoorActivityHubView(
                            weather: weather,
                            currentLocation: locationManager.lastLocation ?? WeatherManager.fallbackLocation,
                            glowColor: weatherGlowColor(for: weather.symbolName),
                            selectedDate: selectedDate
                        )
                        .id("activity-hub-\(selectedDate.timeIntervalSince1970)")
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity
                        ))
                        .padding(.horizontal)

                        WorkoutSuggestionsView(
                            weather: weather,
                            onSelectSuggestion: { category, title in
                                self.suggestedCategory = category
                                self.suggestedTitle = title
                                self.workoutLogPresentation = WorkoutLogPresentation(
                                    defaultDate: selectedDate,
                                    editingWorkout: nil
                                )
                            },
                            glowColor: weatherGlowColor(for: weather.symbolName)
                        )
                        .id("workout-suggestion-\(selectedDate.timeIntervalSince1970)")
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity
                        ))
                        .padding(.horizontal)
                    }

                    // Daily Agenda / To-Do Timelines with Embedded Creation Sheet Trigger
                    TimelineView(
                        events: eventsForSelectedDate,
                        glowColor: weatherGlowColor(for: weatherManager.currentForecast?.symbolName ?? ""),
                        onAddEvent: {
                            editingEvent = nil
                            showEventEditSheet = true
                        },
                        onSelectEvent: { event in
                            editingEvent = event
                            showEventEditSheet = true
                        }
                    )
                    .id("agenda-timeline-\(selectedDate.timeIntervalSince1970)")
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    // Real-Time Commute Tracker
                    CommuteTrackerView(
                        events: eventsForSelectedDate,
                        currentLocation: locationManager.lastLocation,
                        glowColor: weatherGlowColor(for: weatherManager.currentForecast?.symbolName ?? ""),
                        selectedDate: selectedDate
                    )
                    .id("commute-tracker-\(selectedDate.timeIntervalSince1970)")
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
                    .padding(.horizontal)
                    .padding(.bottom, 96) // Extra bottom padding to clear the FAB comfortably
                }
            }
            .safeAreaInset(edge: .top) {
                Spacer().frame(height: 0) // Allows content to scroll comfortably with custom padding
            }
            
            // 3. Premium Interactive Event Creation FAB (Overlaid at the bottom-right corner)
            if calendarManager.permissionStatus == .authorized {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            editingEvent = nil
                            showEventEditSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(colors: [.white, weatherGlowColor(for: weatherManager.currentForecast?.symbolName ?? "").opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 56, height: 56)
                                .background(.ultraThinMaterial) // Advanced translucent material
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.45), weatherGlowColor(for: weatherManager.currentForecast?.symbolName ?? "").opacity(0.4)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: weatherGlowColor(for: weatherManager.currentForecast?.symbolName ?? "").opacity(0.55), radius: 16, x: 0, y: 6) // Luminous Drop Shadow!
                        }
                        .padding(.trailing, 22)
                        .padding(.bottom, 22)
                    }
                }
            }
        }
        .sheet(item: $workoutLogPresentation) { presentation in
            WorkoutLogSheet(
                defaultDate: presentation.defaultDate,
                editingWorkout: presentation.editingWorkout,
                draftWorkoutID: presentation.id
            )
                .environmentObject(workoutManager)
        }
        .sheet(item: $selectedExerciseItem) { item in
            IndividualExerciseEditSheet(workout: item.workout, exercise: item.exercise, isEditMode: item.isEditMode) { _ in
                selectedExerciseItem = nil
            }
            .environmentObject(workoutManager)
        }
        // 3. Native Event Creation Modal Sheet Bridge
        .sheet(isPresented: $showEventEditSheet, onDismiss: {
            editingEvent = nil
        }) {
            if calendarManager.permissionStatus == .authorized {
                EventEditViewWrapper(
                    eventStore: calendarManager.eventStore,
                    defaultDate: selectedDate,
                    event: editingEvent,
                    onComplete: {
                        Task {
                            await refreshData(for: selectedDate)
                        }
                    }
                )
                .ignoresSafeArea()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Calendar Access Required")
                        .font(.headline)
                        .fontDesign(.rounded)
                    Text("Please enable Calendar permissions in system Settings to add and edit events.")
                        .font(.subheadline)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding()
                .presentationDetents([.fraction(0.3)])
            }
        }
        .task {
            // Start location updates immediately on appear
            locationManager.startUpdatingLocation()
            if await workoutManager.fetchWorkouts() {
                await workoutManager.prepareWorkouts(for: selectedDate)
            }
            await refreshData(for: selectedDate)
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
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
            Text(workoutManager.errorMessage ?? "The workout data could not be synchronized.")
        }
    }
    
    // MARK: - Header Layout View
    
    private var headerSection: some View {
        VStack(spacing: 2) {
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: locationManager.permissionStatus == .authorized ? "location.fill" : "location.slash.fill")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                        
                        Text(locationName)
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    
                    if let weather = weatherManager.currentForecast {
                        let glow = weatherGlowColor(for: weather.symbolName)
                        // Prominent Current Temperature Metric with vibrant gradient and glow
                        Text(String(format: "%.0f°", weather.temperature))
                            .font(.system(size: 96, weight: .bold, design: .rounded)) // Larger & Bolder!
                            .tracking(-4)
                            .foregroundStyle(
                                LinearGradient(colors: [.white, .white.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                            )
                            .shadow(color: glow.opacity(0.65), radius: 24, x: 0, y: 8) // Beautiful neon aura!
                        
                        Text(weather.conditionName.uppercased())
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(2.5)
                            .foregroundStyle(
                                LinearGradient(colors: [.white.opacity(0.9), glow.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                    } else {
                        Text("--°")
                            .font(.system(size: 80, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                Spacer()
            }
            
            // Mock banner showing fallback operation if permissions or API failed
            if weatherManager.isUsingMockData {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text("Simulation Weather Active (Location or API blocked)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.thinMaterial)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                )
                .foregroundStyle(.orange)
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Core Refresh Coordination
    
    private func refreshData(for date: Date) async {
        isLoading = true
        defer { isLoading = false }
        
        // 1. Fetch Location or use Cupertino fallback coordinate
        let location = locationManager.lastLocation ?? WeatherManager.fallbackLocation
        
        // 2. Concurrently fetch events & weather updates
        async let fetchedEvents = fetchCalendarEvents(for: date)
        async let _ = weatherManager.fetchWeather(for: location, date: date)
        
        let events = await fetchedEvents
        
        // Dynamic spring animations when content is populated
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            self.eventsForSelectedDate = events
        }
    }
    
    private func fetchCalendarEvents(for date: Date) async -> [EKEvent] {
        do {
            return try await calendarManager.fetchEvents(for: date)
        } catch {
            print("Failed fetching events: \(error.localizedDescription)")
            return []
        }
    }
    
    private var locationName: String {
        guard locationManager.permissionStatus == .authorized else {
            return "Cupertino"
        }
        return "Current Location"
    }
    
    private func weatherGlowColor(for symbolName: String) -> Color {
        let sym = symbolName.lowercased()
        if sym.contains("sun") && !sym.contains("cloud") {
            return Color(red: 1.0, green: 0.65, blue: 0.2) // Neon Golden Orange
        } else if sym.contains("rain") || sym.contains("drizzle") {
            return Color(red: 0.2, green: 0.75, blue: 1.0) // Neon Cyan
        } else if sym.contains("snow") || sym.contains("sleet") {
            return Color(red: 0.5, green: 0.85, blue: 1.0) // Neon Ice Blue
        } else if sym.contains("bolt") || sym.contains("thunder") {
            return Color(red: 0.75, green: 0.2, blue: 1.0) // Neon Purple
        } else {
            return Color(red: 0.6, green: 0.5, blue: 0.9) // Neon Lavender
        }
    }
}

// MARK: - Visual Horizontal Date Selector Bar Component

private struct DateSelectorBar: View {
    let dates: [Date]
    @Binding var selectedDate: Date
    let glowColor: Color
    
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(dates, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    
                    Button(action: {
                        // Tactile spring feedback animation on date switch
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedDate = date
                        }
                    }) {
                        VStack(spacing: 5) {
                            Text(weekdayFormatter.string(from: date).uppercased())
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .tracking(1.5)
                                .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.7))
                            
                            Text(dayFormatter.string(from: date))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(isSelected ? Color.black : Color.white)
                        }
                        .frame(width: 54, height: 76)
                        .background(isSelected ? Color.white : Color.clear)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .scaleEffect(isSelected ? 1.06 : 0.94)
                        .opacity(isSelected ? 1.0 : 0.55)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.white : Color.white.opacity(0.15), lineWidth: 1.2)
                        )
                        .shadow(color: isSelected ? glowColor.opacity(0.5) : Color.black.opacity(0.15), radius: isSelected ? 14 : 6, x: 0, y: 4)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
