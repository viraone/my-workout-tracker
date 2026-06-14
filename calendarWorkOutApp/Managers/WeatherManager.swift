import Foundation
import CoreLocation
import Observation

/// A structure to hold standard, granular weather metrics used in the UI.
public struct CustomWeatherMetrics: Codable, Sendable, Equatable {
    public var temperature: Double // in Fahrenheit or Celsius depending on system locale, we will use Fahrenheit as base
    public var highTemperature: Double
    public var lowTemperature: Double
    public var conditionName: String // e.g. "Sunny", "Cloudy"
    public var symbolName: String // SF Symbol name e.g. "sun.max.fill"
    public var windSpeed: Double // mph
    public var windDirection: String // e.g. "NNE"
    public var humidity: Double // percentage 0.0 - 1.0
    public var uvIndex: Int
    public var precipitationProbability: Double // 0.0 - 1.0
    public var barometricPressure: Double // hPa / inHg
    public var hourlyForecast: [HourlyForecastItem]
    
    public struct HourlyForecastItem: Codable, Sendable, Equatable, Identifiable {
        public var id: UUID = UUID()
        public var time: Date
        public var temperature: Double
        public var symbolName: String
        public var precipitationProbability: Double
    }
}

/// WeatherManager manages weather forecasting using the free Open-Meteo public API,
/// bypassing WeatherKit subscription and capability signature requirements.
@MainActor
@Observable
public final class WeatherManager: Sendable {
    public enum WeatherError: LocalizedError {
        case fetchFailed(String)
        
        public var errorDescription: String? {
            switch self {
            case .fetchFailed(let detail):
                return "Weather fetch failed: \(detail)"
            }
        }
    }
    
    // Apple Park Cupertino fallback location
    public static let fallbackLocation = CLLocation(latitude: 37.332331, longitude: -122.031219)
    
    public var isUsingMockData: Bool = false
    public var currentForecast: CustomWeatherMetrics? = nil
    
    private let openMeteoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        return formatter
    }()
    
    private let openMeteoDailyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        return formatter
    }()
    
    public init() {}
    
    /// Fetches granular weather for a specified location and date using the free Open-Meteo API.
    /// If network requests fail, falls back gracefully to beautiful generated mock data.
    /// - Parameters:
    ///   - location: The CLLocation for the weather coordinate.
    ///   - date: The date for which the weather should represent.
    public func fetchWeather(for location: CLLocation, date: Date) async {
        do {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            
            // Build the URL to fetch current, hourly, and daily metrics in Fahrenheit/mph
            let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code,pressure_msl&hourly=temperature_2m,precipitation_probability,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,uv_index_max,precipitation_probability_max&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch&timezone=auto"
            
            guard let url = URL(string: urlString) else {
                throw WeatherError.fetchFailed("Invalid URL: \(urlString)")
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw WeatherError.fetchFailed("API Server returned unhealthy status.")
            }
            
            let openMeteoResponse = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            
            // Map the parsed JSON structure into our standard CustomWeatherMetrics
            self.currentForecast = self.mapOpenMeteoResponse(openMeteoResponse, date: date)
            self.isUsingMockData = false
        } catch {
            print("Open-Meteo request failed with error: \(error.localizedDescription). Falling back to mock data.")
            self.currentForecast = self.generateMockForecast(for: date)
            self.isUsingMockData = true
        }
    }
    
    private func mapOpenMeteoResponse(_ response: OpenMeteoResponse, date: Date) -> CustomWeatherMetrics {
        let calendar = Calendar.current
        
        // 1. Map Current weather info
        let curTemp = response.current?.temperature_2m ?? 65.0
        let curCode = response.current?.weather_code ?? 0
        let currentConditions = mapWMOCode(curCode)
        let humidityVal = (response.current?.relative_humidity_2m ?? 50.0) / 100.0
        let speedVal = response.current?.wind_speed_10m ?? 8.0
        let angleVal = response.current?.wind_direction_10m ?? 0.0
        let directionStr = compassDirection(from: angleVal)
        let pressureVal = response.current?.pressure_msl ?? 1013.25
        
        // 2. Map Hourly forecast list
        var hourlyForecastItems: [CustomWeatherMetrics.HourlyForecastItem] = []
        if let hourly = response.hourly {
            for index in 0..<hourly.time.count {
                guard let timeStr = hourly.time[safe: index],
                      let itemDate = openMeteoDateFormatter.date(from: timeStr) else {
                    continue
                }
                
                // Keep only the hourly points matching the requested day
                if calendar.isDate(itemDate, inSameDayAs: date) {
                    let temp = hourly.temperature_2m[safe: index] ?? curTemp
                    let wCode = hourly.weather_code?[safe: index] ?? curCode
                    let probVal = Double(hourly.precipitation_probability?[safe: index] ?? 0) / 100.0
                    let hourCondition = mapWMOCode(wCode)
                    
                    hourlyForecastItems.append(
                        CustomWeatherMetrics.HourlyForecastItem(
                            time: itemDate,
                            temperature: temp,
                            symbolName: hourCondition.symbol,
                            precipitationProbability: probVal
                        )
                    )
                }
            }
        }
        
        // 3. Map Daily high/low boundary & metrics
        var highTemp = curTemp + 5.0
        var lowTemp = curTemp - 10.0
        var uvIdx = 4
        var maxPrecipChance = 0.1
        
        if let daily = response.daily {
            for index in 0..<daily.time.count {
                guard let dayStr = daily.time[safe: index],
                      let dayDate = openMeteoDailyDateFormatter.date(from: dayStr) else {
                    continue
                }
                
                if calendar.isDate(dayDate, inSameDayAs: date) {
                    highTemp = daily.temperature_2m_max[safe: index] ?? highTemp
                    lowTemp = daily.temperature_2m_min[safe: index] ?? lowTemp
                    uvIdx = Int(daily.uv_index_max?[safe: index] ?? Double(uvIdx))
                    maxPrecipChance = Double(daily.precipitation_probability_max?[safe: index] ?? 10) / 100.0
                    break
                }
            }
        }
        
        return CustomWeatherMetrics(
            temperature: curTemp,
            highTemperature: highTemp,
            lowTemperature: lowTemp,
            conditionName: currentConditions.condition,
            symbolName: currentConditions.symbol,
            windSpeed: speedVal,
            windDirection: directionStr,
            humidity: humidityVal,
            uvIndex: uvIdx,
            precipitationProbability: maxPrecipChance,
            barometricPressure: pressureVal,
            hourlyForecast: hourlyForecastItems
        )
    }
    
    // MARK: - Decodable Helpers
    
    private struct OpenMeteoResponse: Codable {
        let latitude: Double
        let longitude: Double
        let current: CurrentWeather?
        let hourly: HourlyWeather?
        let daily: DailyWeather?
        
        struct CurrentWeather: Codable {
            let temperature_2m: Double
            let relative_humidity_2m: Double
            let wind_speed_10m: Double
            let wind_direction_10m: Double?
            let weather_code: Int?
            let pressure_msl: Double?
        }
        
        struct HourlyWeather: Codable {
            let time: [String]
            let temperature_2m: [Double]
            let weather_code: [Int]?
            let precipitation_probability: [Int]?
        }
        
        struct DailyWeather: Codable {
            let time: [String]
            let weather_code: [Int]?
            let temperature_2m_max: [Double]
            let temperature_2m_min: [Double]
            let uv_index_max: [Double]?
            let precipitation_probability_max: [Int]?
        }
    }
    
    // MARK: - Meteorological Conversions
    
    private func compassDirection(from degrees: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((degrees + 11.25) / 22.5) % 16
        return directions[index]
    }
    
    private func mapWMOCode(_ code: Int) -> (condition: String, symbol: String) {
        switch code {
        case 0:
            return ("Clear Sky", "sun.max.fill")
        case 1:
            return ("Mainly Clear", "sun.max.fill")
        case 2:
            return ("Partly Cloudy", "cloud.sun.fill")
        case 3:
            return ("Overcast", "cloud.fill")
        case 45, 48:
            return ("Foggy", "cloud.fog.fill")
        case 51, 53, 55:
            return ("Drizzle", "cloud.drizzle.fill")
        case 56, 57:
            return ("Freezing Drizzle", "cloud.sleet.fill")
        case 61:
            return ("Light Rain", "cloud.rain.fill")
        case 63:
            return ("Moderate Rain", "cloud.rain.fill")
        case 65:
            return ("Heavy Rain", "cloud.heavyrain.fill")
        case 66, 67:
            return ("Freezing Rain", "cloud.sleet.fill")
        case 71, 73, 75:
            return ("Snowfall", "snowflake")
        case 77:
            return ("Snow Grains", "snowflake")
        case 80, 81, 82:
            return ("Rain Showers", "cloud.heavyrain.fill")
        case 85, 86:
            return ("Snow Showers", "cloud.snow.fill")
        case 95:
            return ("Thunderstorm", "cloud.bolt.rain.fill")
        case 96, 99:
            return ("Severe Thunderstorm", "cloud.bolt.rain.fill")
        default:
            return ("Partly Cloudy", "cloud.sun.fill")
        }
    }
    
    /// Generates high-fidelity mock weather coordinates for seamless UI operation.
    public func generateMockForecast(for date: Date) -> CustomWeatherMetrics {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Create 24 hours of forecast
        var hourlyForecast: [CustomWeatherMetrics.HourlyForecastItem] = []
        let symbols = ["sun.max.fill", "cloud.sun.fill", "cloud.fill", "cloud.rain.fill", "cloud.heavyrain.fill"]
        
        for hourOffset in 0..<24 {
            if let hourDate = calendar.date(byAdding: .hour, value: hourOffset, to: startOfDay) {
                // Modulate temp across the day (warmer in the afternoon, cooler at night)
                let hourComponent = calendar.component(.hour, from: hourDate)
                let temperatureOffset = -pow(Double(hourComponent - 14), 2.0) / 4.0 + 15.0 // peak at 2 PM
                let currentTemp = 65.0 + temperatureOffset
                
                // Select symbol based on hour to look interesting
                let symbolIndex = abs(hourComponent - 12) % symbols.count
                let precipitationChance = symbolIndex >= 3 ? Double(symbolIndex - 2) * 0.35 : 0.05
                
                hourlyForecast.append(
                    CustomWeatherMetrics.HourlyForecastItem(
                        time: hourDate,
                        temperature: currentTemp,
                        symbolName: symbols[symbolIndex],
                        precipitationProbability: precipitationChance
                    )
                )
            }
        }
        
        return CustomWeatherMetrics(
            temperature: 68.5,
            highTemperature: 78.0,
            lowTemperature: 54.0,
            conditionName: "Partly Cloudy",
            symbolName: "cloud.sun.fill",
            windSpeed: 12.4,
            windDirection: "WNW",
            humidity: 0.62,
            uvIndex: 5,
            precipitationProbability: 0.15,
            barometricPressure: 1013.25,
            hourlyForecast: hourlyForecast
        )
    }
}

// MARK: - Safe Collection Access Helper
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
