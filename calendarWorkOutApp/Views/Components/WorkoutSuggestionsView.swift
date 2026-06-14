import SwiftUI

struct WorkoutSuggestionsView: View {
    let weather: CustomWeatherMetrics
    let onSelectSuggestion: (WorkoutCategory, String) -> Void
    let glowColor: Color
    
    private var recommendation: (category: WorkoutCategory, title: String, reason: String, description: String, icon: String) {
        let isRainy = weather.precipitationProbability > 0.3 || 
                      weather.symbolName.contains("rain") || 
                      weather.symbolName.contains("drizzle") || 
                      weather.symbolName.contains("storm")
        
        let temp = weather.temperature
        
        if isRainy {
            return (
                category: .hiit,
                title: "Indoor HIIT Core Burner",
                reason: "Rainy Day Cardio",
                description: "Wet conditions outside! 🌧️ Stay warm and dry indoors with high-intensity intervals to keep your heart pumping.",
                icon: WorkoutCategory.hiit.iconName
            )
        } else if temp > 85.0 {
            return (
                category: .pilates,
                title: "Cooling Indoor Pilates Flow",
                reason: "Hot Weather Stretch",
                description: "It is pretty hot today (\(Int(temp))°F)! 🥵 Avoid heavy heat exposure by doing a calming, indoor core and alignment session.",
                icon: WorkoutCategory.pilates.iconName
            )
        } else if temp < 45.0 {
            return (
                category: .strength,
                title: "Full Body Strength Lift",
                reason: "Cold Weather Warm-up",
                description: "Brisk outside (\(Int(temp))°F)! ❄️ Warm your body up from the inside out with a heavy muscle-building lifting session.",
                icon: WorkoutCategory.strength.iconName
            )
        } else {
            return (
                category: .cardio,
                title: "Scenic Outdoor Run",
                reason: "Perfect Weather Cardio",
                description: "Incredible weather outside! ☀️ At \(Int(temp))°F and clear conditions, it is a prime opportunity for a beautiful outdoor jog.",
                icon: WorkoutCategory.cardio.iconName
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(recommendation.category.color)
                
                Text("AI WORKOUT SUGGESTION")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .kerning(1.2)
                    .foregroundStyle(.white.opacity(0.6))
                
                Spacer()
                
                Text(recommendation.reason)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(recommendation.category.color.opacity(0.15))
                    .cornerRadius(8)
                    .foregroundStyle(recommendation.category.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(recommendation.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(recommendation.description)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Quick-log Action
            Button(action: {
                onSelectSuggestion(recommendation.category, recommendation.title)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Quick-Log: \(recommendation.title)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [recommendation.category.color, recommendation.category.color.opacity(0.75)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: recommendation.category.color.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), recommendation.category.color.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: glowColor.opacity(0.08), radius: 15, x: 0, y: 10)
    }
}
