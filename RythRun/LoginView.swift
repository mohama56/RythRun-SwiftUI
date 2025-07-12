import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var isAnimating = false
    @State private var showFeatures = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.blue.opacity(0.8),
                        Color.purple.opacity(0.6),
                        Color.cyan.opacity(0.4)
                    ]),
                    startPoint: isAnimating ? .topLeading : .bottomTrailing,
                    endPoint: isAnimating ? .bottomTrailing : .topLeading
                )
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: isAnimating)
                .ignoresSafeArea()
                
                // Floating particles
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(Color.cyan.opacity(0.3))
                        .frame(width: CGFloat.random(in: 10...30))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 4...8))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: isAnimating
                        )
                }
                
                VStack(spacing: 50) {
                    Spacer()
                    
                    // Logo and branding section
                    VStack(spacing: 30) {
                        // Animated logo
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.cyan.opacity(0.8), .blue.opacity(0.6), .clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(isAnimating ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                            
                            Image(systemName: "waveform.path.ecg.rectangle.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                        }
                        
                        VStack(spacing: 16) {
                            Text("RythRun")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cyan, .blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .cyan.opacity(0.5), radius: 10, x: 0, y: 5)
                            
                            Text("AI-Powered Health & Music Intelligence")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Features showcase
                    if showFeatures {
                        VStack(spacing: 16) {
                            Text("Advanced Features")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            VStack(spacing: 12) {
                                FeatureRow(icon: "brain.head.profile", text: "AI Music Optimization", color: .cyan)
                                FeatureRow(icon: "waveform.path.ecg", text: "Real-Time Health Analytics", color: .green)
                                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Performance Prediction", color: .orange)
                                FeatureRow(icon: "figure.run", text: "Advanced Biometrics", color: .purple)
                            }
                        }
                        .padding(.horizontal, 32)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Main Spotify connect button
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isLoggedIn = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "music.note.list")
                                    .font(.title2)
                                
                                Text("Connect with Spotify")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Image(systemName: "arrow.right")
                                    .font(.title3)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .green.opacity(0.4), radius: 20, x: 0, y: 10)
                        }
                        .scaleEffect(isAnimating ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                        
                        // Demo mode button
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isLoggedIn = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                
                                Text("Try Demo Mode")
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.cyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.cyan, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    showFeatures = true
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    @State private var isVisible = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 16))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                isVisible = true
            }
        }
    }
}
