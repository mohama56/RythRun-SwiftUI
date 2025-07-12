import SwiftUI
import HealthKit

struct HealthMetricsView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var currentZone = "Loading..."
    @State private var zoneColor = Color.gray
    @State private var mlAnalysis: MLHealthAnalysis?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // AI Health Analytics Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI Health Analytics")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Machine Learning Health Monitoring")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Real-time Health Metrics
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    HealthMetricCard(
                        title: "Heart Rate",
                        value: "\(Int(healthManager.currentHeartRate))",
                        unit: "BPM",
                        color: .red,
                        icon: "heart.fill",
                        aiInsight: "ML-optimized zone tracking"
                    )
                    
                    HealthMetricCard(
                        title: "HRV Analysis",
                        value: mlAnalysis?.hrvScore ?? "42",
                        unit: "ms",
                        color: .green,
                        icon: "waveform.path.ecg",
                        aiInsight: "AI stress detection"
                    )
                    
                    HealthMetricCard(
                        title: "Recovery Index",
                        value: mlAnalysis?.recoveryIndex ?? "82",
                        unit: "/100",
                        color: .blue,
                        icon: "moon.zzz.fill",
                        aiInsight: "ML recovery prediction"
                    )
                    
                    HealthMetricCard(
                        title: "Performance",
                        value: mlAnalysis?.performanceScore ?? "8.2",
                        unit: "/10",
                        color: .purple,
                        icon: "speedometer",
                        aiInsight: "AI performance forecasting"
                    )
                }
                
                // AI Training Zone Analysis
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI Training Zone Analysis")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Current Zone")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currentZone)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(zoneColor)
                                .frame(width: 80, height: 80)
                            
                            Text(getZoneAbbreviation(currentZone))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Zone Progression Bar
                    HStack(spacing: 4) {
                        ForEach(["Z1", "Z2", "Z3", "Z4", "Z5"], id: \.self) { zone in
                            Rectangle()
                                .fill(zone == getZoneAbbreviation(currentZone) ? zoneColor : Color.gray.opacity(0.3))
                                .frame(height: 8)
                                .cornerRadius(4)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // ML Health Insights
                if let analysis = mlAnalysis {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Health Insights")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ForEach(analysis.insights, id: \.id) { insight in
                                MLInsightCard(insight: insight)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                
                // Health Data Actions
                VStack(spacing: 12) {
                    Button("Send Health Data to AI Backend") {
                        healthManager.sendHealthDataToBackend()
                        generateMLAnalysis()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    
                    Button("Start AI Workout Session") {
                        startAIWorkoutSession()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    
                    Button("Generate ML Health Report") {
                        generateMLHealthReport()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .onAppear {
            updateHealthZone()
            generateMLAnalysis()
        }
        .onChange(of: healthManager.currentHeartRate) { _ in
            updateHealthZone()
        }
    }
    
    private func updateHealthZone() {
        let hr = healthManager.currentHeartRate > 0 ? healthManager.currentHeartRate : 72
        
        if hr < 114 {
            currentZone = "Recovery Zone"
            zoneColor = .green
        } else if hr < 133 {
            currentZone = "Aerobic Zone"
            zoneColor = .blue
        } else if hr < 152 {
            currentZone = "Threshold Zone"
            zoneColor = .orange
        } else {
            currentZone = "Anaerobic Zone"
            zoneColor = .red
        }
    }
    
    private func getZoneAbbreviation(_ zone: String) -> String {
        switch zone {
        case "Recovery Zone": return "Z1"
        case "Aerobic Zone": return "Z2"
        case "Threshold Zone": return "Z3"
        case "Anaerobic Zone": return "Z4"
        default: return "Z0"
        }
    }
    
    private func generateMLAnalysis() {
        // Simulate ML analysis
        mlAnalysis = MLHealthAnalysis(
            hrvScore: String(Int.random(in: 35...55)),
            recoveryIndex: String(Int.random(in: 70...95)),
            performanceScore: String(format: "%.1f", Double.random(in: 7.0...9.5)),
            insights: [
                MLInsight(
                    id: UUID(),
                    title: "Recovery Optimization",
                    description: "AI analysis shows optimal recovery window in next 2-4 hours based on HRV patterns.",
                    confidence: 0.89,
                    priority: .high
                ),
                MLInsight(
                    id: UUID(),
                    title: "Performance Prediction",
                    description: "ML model predicts 15% performance improvement with optimized music tempo matching.",
                    confidence: 0.82,
                    priority: .medium
                ),
                MLInsight(
                    id: UUID(),
                    title: "Training Load Alert",
                    description: "Current training stress suggests moderate intensity for next 48 hours to prevent overtraining.",
                    confidence: 0.91,
                    priority: .high
                )
            ]
        )
    }
    
    private func startAIWorkoutSession() {
        print("Starting AI-powered workout session with real-time ML optimization...")
        // In real implementation, this would start HealthKit workout session
    }
    
    private func generateMLHealthReport() {
        print("Generating comprehensive ML health analytics report...")
        // In real implementation, this would create detailed health report
    }
}

struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    let aiInsight: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.cyan)
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(aiInsight)
                    .font(.caption2)
                    .foregroundColor(.cyan)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct MLInsightCard: View {
    let insight: MLInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(insight.priority.color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("AI: \(Int(insight.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                }
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(insight.priority.color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Data Models
struct MLHealthAnalysis {
    let hrvScore: String
    let recoveryIndex: String
    let performanceScore: String
    let insights: [MLInsight]
}

struct MLInsight: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let confidence: Double
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
    }
}
