import SwiftUI

/// A beautiful, animated weather background that dynamically adjusts gradients and shapes
/// depending on the current weather condition symbol.
public struct DynamicWeatherBackground: View {
    let symbolName: String
    
    @State private var animateClouds = false
    @State private var animateSun = false
    @State private var animateRain = false
    @State private var animateSnow = false
    @State private var animateLightning = false
    
    public init(symbolName: String) {
        self.symbolName = symbolName.lowercased()
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base background gradient matching the weather state
                LinearGradient(
                    gradient: weatherGradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Overlay active animations based on condition symbol
                if isSunny {
                    sunnyAnimation(in: geo.size)
                } else if isRainy {
                    rainyAnimation(in: geo.size)
                } else if isSnowy {
                    snowyAnimation(in: geo.size)
                } else if isCloudy {
                    cloudyAnimation(in: geo.size)
                } else if isStormy {
                    stormyAnimation(in: geo.size)
                }
            }
        }
        .onAppear {
            triggerAnimations()
        }
    }
    
    // MARK: - Condition Classifiers
    
    private var isSunny: Bool {
        symbolName.contains("sun") && !symbolName.contains("cloud") && !symbolName.contains("rain")
    }
    
    private var isRainy: Bool {
        symbolName.contains("rain") || symbolName.contains("drizzle") || symbolName.contains("shower")
    }
    
    private var isSnowy: Bool {
        symbolName.contains("snow") || symbolName.contains("sleet") || symbolName.contains("flurries")
    }
    
    private var isStormy: Bool {
        symbolName.contains("bolt") || symbolName.contains("thunderstorm") || symbolName.contains("hurricane")
    }
    
    private var isCloudy: Bool {
        symbolName.contains("cloud") || symbolName.contains("fog") || symbolName.contains("wind") || symbolName.contains("haze")
    }
    
    // MARK: - Gradient Selection
    
    private var weatherGradient: Gradient {
        if isSunny {
            // Sunny radiant golden-hour gradient
            return Gradient(colors: [
                Color(red: 0.1, green: 0.45, blue: 0.95),   // Vibrant Royal Blue
                Color(red: 0.95, green: 0.5, blue: 0.25),   // Glowing Orange
                Color(red: 1.0, green: 0.85, blue: 0.3)     // Warm Golden Yellow
            ])
        } else if isRainy {
            // Moody electric rainy-day gradient
            return Gradient(colors: [
                Color(red: 0.05, green: 0.15, blue: 0.35),  // Deep Indigo
                Color(red: 0.15, green: 0.35, blue: 0.65),  // Vibrant Slate Blue
                Color(red: 0.3, green: 0.7, blue: 0.85)     // Luminous Cyan
            ])
        } else if isSnowy {
            // Frosted winter-wonderland gradient
            return Gradient(colors: [
                Color(red: 0.2, green: 0.45, blue: 0.75),   // Electric Blue
                Color(red: 0.65, green: 0.85, blue: 1.0),   // Frosted Ice Blue
                Color(red: 0.95, green: 0.95, blue: 1.0)    // Glowing Pearl White
            ])
        } else if isStormy {
            // Electric lightning storm gradient
            return Gradient(colors: [
                Color(red: 0.05, green: 0.05, blue: 0.2),   // Deep Midnight Violet
                Color(red: 0.3, green: 0.1, blue: 0.5),     // Vibrant Electric Purple
                Color(red: 0.5, green: 0.15, blue: 0.45)    // Luminous Violet-Red
            ])
        } else {
            // Rich cloudy sky gradient
            return Gradient(colors: [
                Color(red: 0.25, green: 0.35, blue: 0.55),  // Steel Blue
                Color(red: 0.45, green: 0.45, blue: 0.75),  // Rich Lavender
                Color(red: 0.65, green: 0.75, blue: 0.9)    // Luminous Sky Blue
            ])
        }
    }
    
    // MARK: - Animations
    
    private func triggerAnimations() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: true)) {
            animateClouds.toggle()
        }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            animateSun.toggle()
        }
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            animateRain.toggle()
        }
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            animateSnow.toggle()
        }
        // Lightning flashes periodically
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                animateLightning = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    animateLightning = false
                }
            }
        }
    }
    
    // MARK: - Animation Overlay Views
    
    @ViewBuilder
    private func sunnyAnimation(in size: CGSize) -> some View {
        ZStack {
            // Pulsing, rotating sun flare elements
            Circle()
                .fill(Color.yellow.opacity(0.12))
                .frame(width: size.width * 0.9, height: size.width * 0.9)
                .scaleEffect(animateSun ? 1.05 : 0.95)
                .position(x: size.width * 0.85, y: size.height * 0.15)
            
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: size.width * 0.5, height: size.width * 0.5)
                .scaleEffect(animateSun ? 0.92 : 1.08)
                .position(x: size.width * 0.85, y: size.height * 0.15)
        }
    }
    
    @ViewBuilder
    private func cloudyAnimation(in size: CGSize) -> some View {
        ZStack {
            // Floating background clouds moving slowly
            Image(systemName: "cloud.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color.white.opacity(0.15))
                .frame(width: 320)
                .offset(x: animateClouds ? size.width * 0.4 : -size.width * 0.4, y: size.height * 0.12)
            
            Image(systemName: "cloud.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color.white.opacity(0.10))
                .frame(width: 200)
                .offset(x: animateClouds ? -size.width * 0.3 : size.width * 0.3, y: size.height * 0.25)
        }
    }
    
    @ViewBuilder
    private func rainyAnimation(in size: CGSize) -> some View {
        ZStack {
            // Draw floating background clouds
            cloudyAnimation(in: size)
            
            // Fast downward-moving rain lines
            Canvas { context, drawSize in
                context.opacity = 0.4
                for item in 0..<45 {
                    let seed = Double(item)
                    let xPos = fmod(seed * 37.0, drawSize.width)
                    let fallOffset = animateRain ? drawSize.height : 0
                    let yPos = fmod(seed * 73.0 + fallOffset, drawSize.height)
                    
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: xPos, y: yPos))
                            path.addLine(to: CGPoint(x: xPos - 3, y: yPos + 18))
                        },
                        with: .color(.white),
                        lineWidth: 1.5
                    )
                }
            }
            .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private func snowyAnimation(in size: CGSize) -> some View {
        ZStack {
            cloudyAnimation(in: size)
            
            // Slow falling white snowflakes
            Canvas { context, drawSize in
                context.opacity = 0.7
                for item in 0..<35 {
                    let seed = Double(item)
                    let xPos = fmod(seed * 41.0 + (animateSnow ? sin(seed) * 15.0 : 0.0), drawSize.width)
                    let fallOffset = animateSnow ? drawSize.height : 0
                    let yPos = fmod(seed * 59.0 + fallOffset, drawSize.height)
                    
                    let flakeSize = CGFloat(fmod(seed * 3.0, 5.0) + 3.0)
                    let rect = CGRect(x: xPos, y: yPos, width: flakeSize, height: flakeSize)
                    context.fill(Path(ellipseIn: rect), with: .color(.white))
                }
            }
            .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private func stormyAnimation(in size: CGSize) -> some View {
        ZStack {
            cloudyAnimation(in: size)
            
            // White lightning flash
            if animateLightning {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.35)
            }
            
            // Fast raindrops
            rainyAnimation(in: size)
        }
    }
}
