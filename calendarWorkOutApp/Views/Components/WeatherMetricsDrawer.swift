import SwiftUI

/// A component that renders granular meteorological cards and an hourly trend line.
public struct WeatherMetricsDrawer: View {
    let weather: CustomWeatherMetrics
    
    // Premium glowing gradients for icons
    private let mintToTeal = LinearGradient(colors: [Color(red: 0.4, green: 0.85, blue: 0.6), Color(red: 0.1, green: 0.65, blue: 0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
    private let pinkToPurple = LinearGradient(colors: [Color(red: 0.95, green: 0.4, blue: 0.7), Color(red: 0.6, green: 0.2, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
    private let orangeToCoral = LinearGradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.95, green: 0.3, blue: 0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
    private let skyToDeepBlue = LinearGradient(colors: [Color(red: 0.45, green: 0.75, blue: 0.95), Color(red: 0.1, green: 0.45, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    public init(weather: CustomWeatherMetrics) {
        self.weather = weather
    }
    
    private var glowColor: Color {
        let sym = weather.symbolName.lowercased()
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
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Hourly Forecast horizontal scroll section
            VStack(alignment: .leading, spacing: 14) {
                Text("HOURLY FORECAST")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.8)
                    .foregroundStyle(
                        LinearGradient(colors: [.white.opacity(0.9), glowColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                    )
                    .padding(.horizontal, 4)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(weather.hourlyForecast) { item in
                            HourlyCard(item: item, glowColor: glowColor)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Grid of Detailed Metrics
            VStack(alignment: .leading, spacing: 14) {
                Text("METEOROLOGICAL METRICS")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.8)
                    .foregroundStyle(
                        LinearGradient(colors: [.white.opacity(0.9), glowColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                    )
                    .padding(.horizontal, 4)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricCard(
                        title: "Wind Speed",
                        value: String(format: "%.1f mph", weather.windSpeed),
                        subtext: "Direction: \(weather.windDirection)",
                        icon: "wind",
                        iconGradient: mintToTeal,
                        glowColor: glowColor
                    )
                    
                    MetricCard(
                        title: "Humidity",
                        value: String(format: "%.0f%%", weather.humidity * 100),
                        subtext: weather.humidity > 0.6 ? "Sticky air" : "Comfortable",
                        icon: "humidity.fill",
                        iconGradient: mintToTeal,
                        glowColor: glowColor
                    )
                    
                    MetricCard(
                        title: "UV Index",
                        value: "\(weather.uvIndex)",
                        subtext: uvRiskText(for: weather.uvIndex),
                        icon: "sun.max.fill",
                        iconGradient: orangeToCoral,
                        glowColor: glowColor
                    )
                    
                    MetricCard(
                        title: "Precipitation",
                        value: String(format: "%.0f%%", weather.precipitationProbability * 100),
                        subtext: weather.precipitationProbability > 0.4 ? "High chance" : "Low chance",
                        icon: "cloud.rain.fill",
                        iconGradient: skyToDeepBlue,
                        glowColor: glowColor
                    )
                    
                    MetricCard(
                        title: "Pressure",
                        value: String(format: "%.1f hPa", weather.barometricPressure),
                        subtext: "Stable",
                        icon: "gauge.with.needle",
                        iconGradient: pinkToPurple,
                        glowColor: glowColor
                    )
                    
                    MetricCard(
                        title: "Temp Range",
                        value: String(format: "%.0f° / %.0f°", weather.highTemperature, weather.lowTemperature),
                        subtext: "Today's boundaries",
                        icon: "thermometer.medium",
                        iconGradient: orangeToCoral,
                        glowColor: glowColor
                    )
                }
            }
        }
        .padding(22)
        .background(.ultraThinMaterial) // Translucent high-end background
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.05), glowColor.opacity(0.35), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 8) // Soft shadow depth
    }
    
    private func uvRiskText(for index: Int) -> String {
        switch index {
        case 0...2: return "Low risk"
        case 3...5: return "Moderate risk"
        case 6...7: return "High risk"
        case 8...10: return "Very high risk"
        default: return "Extreme risk"
        }
    }
}

private struct HourlyCard: View {
    let item: CustomWeatherMetrics.HourlyForecastItem
    let glowColor: Color
    
    private let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 8) {
            Text(hourFormatter.string(from: item.time))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            
            Image(systemName: item.symbolName)
                .font(.system(size: 22))
                .symbolRenderingMode(.multicolor)
                .frame(height: 28)
            
            Text(String(format: "%.0f°", item.temperature))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            if item.precipitationProbability > 0.1 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 7))
                    Text(String(format: "%.0f%%", item.precipitationProbability * 100))
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.cyan)
            } else {
                Spacer()
                    .frame(height: 8)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(colors: [.white.opacity(0.2), glowColor.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let subtext: String
    let icon: String
    let iconGradient: LinearGradient
    let glowColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconGradient) // Soft glowing linear gradient icon
            }
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(LinearGradient(colors: [.white.opacity(0.25), glowColor.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    
                Text(subtext)
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(LinearGradient(colors: [.white.opacity(0.2), glowColor.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
}
