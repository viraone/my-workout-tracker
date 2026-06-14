import SwiftUI
import CoreLocation

/// An interactive, premium glassmorphic drawer displaying tailored weather insights
/// and gear recommendations for various outdoor hobbies, synchronized with our location engine.
public struct OutdoorActivityHubView: View {
    let weather: CustomWeatherMetrics
    let currentLocation: CLLocation
    let glowColor: Color
    let selectedDate: Date
    
    public enum ActivityType: String, CaseIterable, Identifiable, Sendable {
        case surfing = "Surfing"
        case fishing = "Fishing"
        case running = "Running"
        case biking = "Biking"
        case golf = "Golf"
        case hiking = "Hiking"
        
        public var id: String { self.rawValue }
        
        public var icon: String {
            switch self {
            case .surfing: return "water.waves"
            case .fishing: return "fish.circle"
            case .running: return "figure.run"
            case .biking: return "figure.outdoor.cycle"
            case .golf: return "figure.golf"
            case .hiking: return "figure.hiking"
            }
        }
    }
    
    public enum ConditionsRating: String, Sendable {
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        
        public var color: Color {
            switch self {
            case .good: return .green
            case .fair: return .yellow
            case .poor: return .red
            }
        }
        
        public var icon: String {
            switch self {
            case .good: return "checkmark.seal.fill"
            case .fair: return "exclamationmark.triangle.fill"
            case .poor: return "xmark.octagon.fill"
            }
        }
    }
    
    @State private var selectedActivity: ActivityType = .surfing
    
    // Wave data state (Surf & Ocean Dynamics)
    @State private var waveHeight: Double? = nil
    @State private var wavePeriod: Double? = nil
    @State private var waveDirection: Double? = nil
    @State private var isFetchingMarine: Bool = false
    
    public init(weather: CustomWeatherMetrics, currentLocation: CLLocation, glowColor: Color, selectedDate: Date) {
        self.weather = weather
        self.currentLocation = currentLocation
        self.glowColor = glowColor
        self.selectedDate = selectedDate
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header Row
            HStack(spacing: 12) {
                Image(systemName: "figure.outdoor.sport")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, glowColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Outdoor Activity Hub")
                    .font(.headline)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Glowing Overall Condition Indicator
                let rating = currentRating()
                HStack(spacing: 5) {
                    Image(systemName: rating.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text("\(rating.rawValue) Conditions")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(rating.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(rating.color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: rating.color.opacity(0.15), radius: 6)
            }
            .padding(.horizontal, 4)
            
            // Premium Horizontal Activity Pill Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ActivityType.allCases) { activity in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedActivity = activity
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: activity.icon)
                                    .font(.subheadline)
                                Text(activity.rawValue)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedActivity == activity ? glowColor.opacity(0.15) : Color.white.opacity(0.04))
                            .foregroundStyle(selectedActivity == activity ? .white : .white.opacity(0.6))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(selectedActivity == activity ? glowColor.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Dynamic Information & Metrics Drawer Display
            VStack(alignment: .leading, spacing: 14) {
                // Activity Cards Row
                activityMetricsView()
                
                // Gear & Meteorological Recommendations Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(glowColor)
                        
                        Text("METEOROLOGICAL RECOMMENDATIONS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                            .tracking(1.0)
                    }
                    
                    Text(activityRecommendation())
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(4)
                }
                .padding(.all, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
        }
        .padding(.all, 20)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        .onAppear {
            triggerMarineFetch()
        }
        .onChange(of: currentLocation) { _, _ in
            triggerMarineFetch()
        }
    }
    
    // MARK: - Activity-Specific Renderers
    
    @ViewBuilder
    private func activityMetricsView() -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            switch selectedActivity {
            case .surfing:
                if isFetchingMarine {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    .frame(height: 70)
                    .gridCellColumns(2)
                } else {
                    // AM / PM / Night Day-Segment split columns + Tide Inset Chart
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            SurfSegmentColumn(title: "AM", data: getSurfSegmentData(for: "AM"), glowColor: glowColor)
                            SurfSegmentColumn(title: "PM", data: getSurfSegmentData(for: "PM"), glowColor: glowColor)
                            SurfSegmentColumn(title: "NIGHT", data: getSurfSegmentData(for: "Night"), glowColor: glowColor)
                        }
                        
                        // Tide Info Inset Card
                        let tides = generateTides(for: selectedDate)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "water.waves")
                                    .font(.caption2)
                                    .foregroundStyle(glowColor)
                                Text("DAILY TIDE CHART")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.45))
                                    .tracking(1.0)
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(tides) { tide in
                                    HStack(spacing: 4) {
                                        Image(systemName: tide.isHigh ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                            .font(.system(size: 8))
                                            .foregroundStyle(tide.isHigh ? .green : .cyan)
                                        Text(tide.time)
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                        Text(tide.height)
                                            .font(.system(size: 8, weight: .regular, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                    if tide.id != tides.last?.id {
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.all, 10)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .gridCellColumns(2)
                }
                
            case .fishing:
                let tideState = simulatedTideState()
                MiniDataCard(
                    title: "TIDE PROGRESS",
                    value: tideState.0,
                    icon: tideState.1,
                    color: .teal
                )
                
                MiniDataCard(
                    title: "BAROMETRIC PRESSURE",
                    value: String(format: "%.1f hPa", weather.barometricPressure),
                    icon: "gauge.with.needle",
                    color: .purple
                )
                
            case .running:
                MiniDataCard(
                    title: "WIND IMPACT",
                    value: String(format: "%.1f mph", weather.windSpeed),
                    icon: "wind",
                    color: .mint
                )
                
                MiniDataCard(
                    title: "PRECIP. PROB",
                    value: String(format: "%.0f%%", weather.precipitationProbability * 100),
                    icon: "cloud.rain",
                    color: .blue
                )
                
            case .biking:
                MiniDataCard(
                    title: "CROSSWINDS",
                    value: String(format: "%.1f mph", weather.windSpeed),
                    icon: "wind",
                    color: .orange
                )
                
                MiniDataCard(
                    title: "AIR TEMP",
                    value: String(format: "%.0f°F", weather.temperature),
                    icon: "thermometer.medium",
                    color: .red
                )
                
            case .golf:
                MiniDataCard(
                    title: "WIND SPEED",
                    value: String(format: "%.1f mph", weather.windSpeed),
                    icon: "wind",
                    color: .green
                )
                
                MiniDataCard(
                    title: "RAIN CHANCE",
                    value: String(format: "%.0f%%", weather.precipitationProbability * 100),
                    icon: "cloud.rain.fill",
                    color: .cyan
                )
                
            case .hiking:
                MiniDataCard(
                    title: "SUN EXPOSURE",
                    value: "UV Index \(weather.uvIndex)",
                    icon: "sun.max",
                    color: .yellow
                )
                
                MiniDataCard(
                    title: "RAIN RISK",
                    value: String(format: "%.0f%%", weather.precipitationProbability * 100),
                    icon: "cloud.rain",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - Mathematical Conditions Engine & Logics
    
    private func currentRating() -> ConditionsRating {
        switch selectedActivity {
        case .surfing:
            let height = waveHeight ?? simulatedSwellHeight()
            let period = wavePeriod ?? simulatedSwellPeriod()
            
            // Good waves are above 3 feet with organized period >= 9 seconds
            if height >= 3.0 && period >= 9 {
                return .good
            } else if height >= 1.5 {
                return .fair
            } else {
                return .poor
            }
            
        case .fishing:
            let pressure = weather.barometricPressure
            let tide = simulatedTideState().0
            
            // Fishing is optimal during rising/falling tides with low stable pressure
            let isMovingTide = tide.contains("Rising") || tide.contains("Falling")
            let isGoodPressure = pressure < 1018.0 && pressure > 1008.0
            
            if isMovingTide && isGoodPressure {
                return .good
            } else if isMovingTide || isGoodPressure {
                return .fair
            } else {
                return .poor
            }
            
        case .running:
            let temp = weather.temperature
            let wind = weather.windSpeed
            let rain = weather.precipitationProbability
            
            if temp >= 45 && temp <= 75 && wind < 12 && rain < 0.2 {
                return .good
            } else if (temp >= 38 && temp <= 85) && wind < 20 && rain < 0.5 {
                return .fair
            } else {
                return .poor
            }
            
        case .biking:
            let temp = weather.temperature
            let wind = weather.windSpeed
            let rain = weather.precipitationProbability
            
            if temp >= 50 && temp <= 78 && wind < 8 && rain < 0.15 {
                return .good
            } else if (temp >= 42 && temp <= 85) && wind < 16 && rain < 0.4 {
                return .fair
            } else {
                return .poor
            }
            
        case .golf:
            let wind = weather.windSpeed
            let rain = weather.precipitationProbability
            
            if rain < 0.15 && wind < 12 {
                return .good
            } else if rain < 0.35 && wind < 22 {
                return .fair
            } else {
                return .poor
            }
            
        case .hiking:
            let temp = weather.temperature
            let rain = weather.precipitationProbability
            
            if temp >= 50 && temp <= 80 && rain < 0.20 {
                return .good
            } else if temp >= 40 && temp <= 88 && rain < 0.45 {
                return .fair
            } else {
                return .poor
            }
        }
    }
    
    private func activityRecommendation() -> String {
        switch selectedActivity {
        case .surfing:
            let amData = getSurfSegmentData(for: "AM")
            let pmData = getSurfSegmentData(for: "PM")
            
            let optimalPeriod = max(amData.period, pmData.period)
            let maxEnergy = max(amData.energy, pmData.energy)
            
            if optimalPeriod >= 11 {
                return "A very clean, high-energy (\(Int(maxEnergy)) kJ) groundswell is peaking today! Wind conditions of '\(amData.windType)' in the morning make AM the optimal session. Perfect glassy face groomers expected on the tide shifts."
            } else if maxEnergy > 600 {
                return "Solid waves on offer (\(Int(maxEnergy)) kJ). Afternoon wind looks like '\(pmData.windType)', which might chop up the peak. Surf early to beat the onshore breeze!"
            } else {
                return "Small windswell waves peaking around \(String(format: "%.1f", amData.height)) ft. Best suited for high-volume boards or longboards. Look for incoming tides to maximize visual peel."
            }
            
        case .fishing:
            let pressure = weather.barometricPressure
            let tide = simulatedTideState().0
            var advice = "Moving water (\(tide)) triggers baitfish activity. "
            if pressure < 1013 {
                advice += "Low barometric pressure is activating predatory fish. Feed bags are on! Focus on shallow shorelines and weed beds."
            } else {
                advice += "High barometric pressure means slower bite. Fish have retreated to deeper holding cover. Fish slow, deep, and use down-sized lures."
            }
            return advice
            
        case .running:
            let temp = weather.temperature
            let wind = weather.windSpeed
            let rain = weather.precipitationProbability
            
            if rain > 0.4 {
                return "Rain probability is high (\(Int(rain * 100))%). We recommend throwing on a waterproof running jacket, cap, and technical fabrics to avoid chaffing."
            } else if temp > 80 {
                return "Heat risk warning! UV Index is high. Run early or late, wear breathable mesh, apply SPF, and pack hydration flasks."
            } else if wind > 15 {
                return "High wind resistance (\(Int(wind)) mph). Plan your route so you tackle headwind during the first half and enjoy a tailwind home."
            } else {
                return "Superb running weather! Ideal temperature and clear skies. Slip on standard lightweight trainers and enjoy a comfortable cardio session."
            }
            
        case .biking:
            let temp = weather.temperature
            let wind = weather.windSpeed
            if wind > 15 {
                return "Strong winds (\(Int(wind)) mph) will cause significant crosswind drag. Gear down, hold your drops tightly, and pack a windproof technical vest."
            } else if temp < 48 {
                return "Brrisk air temperatures. Slip on wind-front thermal bibs, insulated gloves, and toe covers to block freezing cleat draft."
            } else {
                return "Pristine cycling weather. Wind drag is minimal. Bring two bottles of electrolytes, wear a standard short-sleeve jersey, and enjoy the smooth tarmac."
            }
            
        case .golf:
            let wind = weather.windSpeed
            let rain = weather.precipitationProbability
            if rain > 0.3 {
                return "Intermittent drizzle will affect the greens. Keep a dry towel clipped to your umbrella, pack wet-weather gloves, and expect slower green speeds."
            } else if wind > 15 {
                return "Challenging wind gusts of \(Int(wind)) mph. Club up 1-2 sizes when hitting into the headwind and keep ball flights low (stinger shots)."
            } else {
                return "Beautiful golfing weather! Stable wind speeds and dry fairways. Ideal for holding lines and attacking pins directly."
            }
            
        case .hiking:
            let temp = weather.temperature
            let uv = weather.uvIndex
            let rain = weather.precipitationProbability
            
            if rain > 0.35 {
                return "Slippery trail advisory! High probability of rain on route. Pack a gore-tex hard shell, high-traction boots, and verify emergency storm shelters."
            } else if uv > 6 {
                return "High UV risk on altitude trails. Wear a broad-brimmed sun hat, sunglasses, apply high-SPF block, and carry a minimum of 2.5L of fresh water."
            } else if temp < 45 {
                return "Chilly conditions in the wilderness. Wear insulated fleece mid-layers, pack a thermal blanket, and stay active to maintain optimal core temperature."
            } else {
                return "Superb hiking window! Trails are stable and temperatures are highly comfortable. Pack a basic first-aid pouch and head out to the mountains!"
            }
        }
    }
    
    // MARK: - API / Dynamic Simulation Engines
    
    private func triggerMarineFetch() {
        isFetchingMarine = true
        let lat = currentLocation.coordinate.latitude
        let lon = currentLocation.coordinate.longitude
        
        let urlString = "https://marine-api.open-meteo.com/v1/marine?latitude=\(lat)&longitude=\(lon)&current=wave_height,wave_period,wave_direction"
        
        guard let url = URL(string: urlString) else {
            isFetchingMarine = false
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(MarineResponse.self, from: data)
                
                await MainActor.run {
                    if let current = response.current, let height = current.wave_height, height > 0 {
                        // Open-Meteo marine returns waves in meters, let's convert to feet comfortably
                        self.waveHeight = height * 3.28084
                        self.wavePeriod = current.wave_period
                        self.waveDirection = current.wave_direction
                    } else {
                        // If landlocked, clear out to trigger simulation gracefully
                        self.waveHeight = nil
                        self.wavePeriod = nil
                        self.waveDirection = nil
                    }
                    self.isFetchingMarine = false
                }
            } catch {
                print("Marine wave fetch failed (probably inland/offline). Standard fallbacks applied. Error: \(error)")
                await MainActor.run {
                    self.waveHeight = nil
                    self.wavePeriod = nil
                    self.waveDirection = nil
                    self.isFetchingMarine = false
                }
            }
        }
    }
    
    // MARK: - Algorithmic Calculations & Models
    
    private struct TideEvent: Identifiable, Sendable {
        let id = UUID()
        let isHigh: Bool
        let time: String
        let height: String
    }
    
    private func generateTides(for date: Date) -> [TideEvent] {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        
        // Shift tides forward by 50 mins per calendar day
        let shiftMinutes = (day * 50) % 720
        
        // Low and high base patterns
        let t1 = (120 + shiftMinutes) % 1440
        let t2 = (480 + shiftMinutes) % 1440
        let t3 = (840 + shiftMinutes) % 1440
        let t4 = (1200 + shiftMinutes) % 1440
        
        let rawTides = [
            (isHigh: false, minutes: t1, height: 1.1 + Double(day % 5) * 0.1),
            (isHigh: true, minutes: t2, height: 5.2 + Double(day % 7) * 0.15),
            (isHigh: false, minutes: t3, height: 0.8 + Double(day % 4) * 0.12),
            (isHigh: true, minutes: t4, height: 5.6 + Double(day % 6) * 0.18)
        ].sorted { $0.minutes < $1.minutes }
        
        return rawTides.map { item in
            let h = item.minutes / 60
            let m = item.minutes % 60
            let ampm = h >= 12 ? "PM" : "AM"
            let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
            let timeStr = String(format: "%d:%02d %@", h12, m, ampm)
            let heightStr = String(format: "%.2f ft", item.height)
            return TideEvent(isHigh: item.isHigh, time: timeStr, height: heightStr)
        }
    }
    
    private func getSurfSegmentData(for segment: String) -> (height: Double, period: Double, energy: Double, windSpeed: Double, windDir: Double, windType: String) {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: selectedDate)
        
        let segmentMultiplier: Double
        let timeHour: Int
        switch segment {
        case "AM":
            segmentMultiplier = 1.0
            timeHour = 9
        case "PM":
            segmentMultiplier = 1.15
            timeHour = 15
        default:
            segmentMultiplier = 0.9
            timeHour = 21
        }
        
        let baseHeight = waveHeight ?? simulatedSwellHeight()
        let basePeriod = wavePeriod ?? simulatedSwellPeriod()
        
        // Deterministic daily and diurnal variance
        let dailyVariance = sin(Double(day) * 0.5) * 1.2
        let segHeight = max(1.2, baseHeight * segmentMultiplier + dailyVariance * 0.3)
        let segPeriod = max(6.0, basePeriod + sin(Double(day) * 0.8) * 1.5)
        let segEnergy = segHeight * segHeight * segPeriod * 5.0
        
        // Wind: Dynamic based on hours and date
        let dayFactor = Double((day + timeHour) % 360)
        let segWindSpeed = max(3.0, weather.windSpeed + sin(dayFactor * 0.15) * 5.0)
        let segWindDir = Double((180 + Int(dayFactor * 45)) % 360)
        let segWindType = categorizeWind(speed: segWindSpeed, direction: segWindDir)
        
        return (segHeight, segPeriod, segEnergy, segWindSpeed, segWindDir, segWindType)
    }
    
    private func categorizeWind(speed: Double, direction: Double) -> String {
        if speed < 4.0 {
            return "Glassy"
        }
        switch direction {
        case 45.0..<135.0:
            return "Offshore"
        case 15.0..<45.0, 135.0..<165.0:
            return "Cross-Off"
        case 225.0..<315.0:
            return "Onshore"
        case 195.0..<225.0, 315.0..<345.0:
            return "Cross-On"
        default:
            return "Cross"
        }
    }
    
    // Fallbacks
    
    private func simulatedSwellHeight() -> Double {
        let wind = weather.windSpeed
        let base = wind > 15 ? 3.4 : (wind > 8 ? 2.1 : 1.2)
        let isWestCoast = currentLocation.coordinate.longitude < -120.0
        return isWestCoast ? base + 1.8 : base
    }
    
    private func simulatedSwellPeriod() -> Double {
        let isWestCoast = currentLocation.coordinate.longitude < -120.0
        return isWestCoast ? 11 : 6
    }
    
    private func simulatedTideState() -> (String, String) {
        let hour = Calendar.current.component(.hour, from: Date())
        let tideProgress = hour % 12
        switch tideProgress {
        case 0...2:
            return ("Rising Tide (Low)", "chart.bar.xaxis")
        case 3...5:
            return ("High Tide (Slack)", "water.waves.and.arrow.up")
        case 6...8:
            return ("Falling Tide (Ebb)", "chart.bar.xaxis.ascending")
        default:
            return ("Low Tide (Slack)", "water.waves.and.arrow.down")
        }
    }
}

// MARK: - SurfSegmentColumn Helper Component

struct SurfSegmentColumn: View {
    let title: String
    let data: (height: Double, period: Double, energy: Double, windSpeed: Double, windDir: Double, windType: String)
    let glowColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(0.8)
            
            VStack(spacing: 2) {
                Text(String(format: "%.1f ft", data.height))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(Int(data.period))s")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Text("\(Int(data.energy)) kJ")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(energyGradient(for: data.energy))
                .shadow(color: energyColor(for: data.energy).opacity(0.2), radius: 4)
            
            HStack(spacing: 3) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 8, weight: .bold))
                    .rotationEffect(.degrees(data.windDir))
                    .foregroundStyle(.white)
                Text(String(format: "%.0f mph", data.windSpeed))
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            // Wind type pill badge
            Text(data.windType)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(windTypeBgColor(for: data.windType))
                .foregroundStyle(windTypeFgColor(for: data.windType))
                .clipShape(Capsule())
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func energyColor(for energy: Double) -> Color {
        if energy > 1000 {
            return .red
        } else if energy > 500 {
            return .orange
        } else if energy > 200 {
            return .green
        } else {
            return .blue
        }
    }
    
    private func energyGradient(for energy: Double) -> LinearGradient {
        if energy > 1000 {
            return LinearGradient(colors: [Color.red, Color.orange], startPoint: .top, endPoint: .bottom)
        } else if energy > 500 {
            return LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .top, endPoint: .bottom)
        } else if energy > 200 {
            return LinearGradient(colors: [Color.green, Color(red: 0.4, green: 0.8, blue: 0.6)], startPoint: .top, endPoint: .bottom)
        } else {
            return LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .top, endPoint: .bottom)
        }
    }
    
    private func windTypeBgColor(for type: String) -> Color {
        let t = type.lowercased()
        if t.contains("offshore") || t.contains("glassy") {
            return Color.green.opacity(0.12)
        } else if t.contains("onshore") {
            return Color.red.opacity(0.08)
        } else {
            return Color.white.opacity(0.06)
        }
    }
    
    private func windTypeFgColor(for type: String) -> Color {
        let t = type.lowercased()
        if t.contains("offshore") || t.contains("glassy") {
            return .green
        } else if t.contains("onshore") {
            return .red.opacity(0.8)
        } else {
            return .white.opacity(0.7)
        }
    }
}

// MARK: - Mini Data Card Helper

struct MiniDataCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 18)
                
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                    .tracking(0.8)
            }
            
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.all, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Decodables for Marine

struct MarineResponse: Codable {
    struct Current: Codable {
        let wave_height: Double?
        let wave_period: Double?
        let wave_direction: Double?
    }
    let current: Current?
}
