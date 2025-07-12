import SwiftUI
import HealthKit

struct WorkoutView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @EnvironmentObject var musicEngine: MLMusicEngine
    @EnvironmentObject var workoutSession: WorkoutSessionManager
    
    @State private var selectedWorkoutType: WorkoutType = .running
    @State private var isWorkoutActive = false
    @State private var workoutDuration: TimeInterval = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI-Powered Workout")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("ML-optimized music recommendations based on real-time health data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !isWorkoutActive {
                        // Pre-Workout Setup
                        preWorkoutSection
                    } else {
                        // Active Workout
                        activeWorkoutSection
                    }
                    
                    // Health Stats
                    healthStatsSection
                }
                .padding()
            }
            .navigationTitle("Workout")
        }
    }
    
    // MARK: - Pre-Workout Section
    private var preWorkoutSection: some View {
        VStack(spacing: 20) {
            
            // Workout Type Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Workout Type")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(WorkoutType.allCases, id: \.self) { workoutType in
                        WorkoutTypeCard(
                            workoutType: workoutType,
                            isSelected: selectedWorkoutType == workoutType
                        ) {
                            selectedWorkoutType = workoutType
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            
            // Start Workout Button
            Button(action: startWorkout) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    
                    Text("Start \(selectedWorkoutType.rawValue.capitalized) Workout")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "waveform.path.ecg")
                        .font(.title2)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.4), radius: 20, x: 0, y: 10)
            }
        }
    }
    
    // MARK: - Active Workout Section
    private var activeWorkoutSection: some View {
        VStack(spacing: 20) {
            
            // Workout Controls
            HStack(spacing: 16) {
                Button("Pause") {
                    // Pause workout logic
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
                
                Button("End Workout") {
                    endWorkout()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // Duration Display
            VStack {
                Text("Duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatDuration(workoutDuration))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Health Stats Section
    private var healthStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Live Health Data")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                HealthStatCard(
                    title: "Heart Rate",
                    value: "\(Int(healthManager.currentHeartRate))",
                    unit: "BPM",
                    color: .red,
                    icon: "heart.fill"
                )
                
                HealthStatCard(
                    title: "Cadence",
                    value: "\(Int(healthManager.cadence))",
                    unit: "SPM",
                    color: .blue,
                    icon: "figure.run"
                )
                
                HealthStatCard(
                    title: "Zone",
                    value: "Zone \(healthManager.performanceZone)",
                    unit: "",
                    color: .orange,
                    icon: "target"
                )
                
                HealthStatCard(
                    title: "Recovery",
                    value: "\(Int(healthManager.recoveryIndex))",
                    unit: "%",
                    color: .green,
                    icon: "moon.zzz.fill"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Actions
    private func startWorkout() {
        isWorkoutActive = true
        workoutDuration = 0
        
        // Start timer
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if isWorkoutActive {
                workoutDuration += 1
            } else {
                timer.invalidate()
            }
        }
        
        print("Started \(selectedWorkoutType.rawValue) workout")
    }
    
    private func endWorkout() {
        isWorkoutActive = false
        print("Ended workout after \(formatDuration(workoutDuration))")
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

struct WorkoutTypeCard: View {
    let workoutType: WorkoutType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconForWorkoutType(workoutType))
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(workoutType.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ?
                AnyView(LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)) :
                AnyView(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }
    
    private func iconForWorkoutType(_ type: WorkoutType) -> String {
        switch type {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .strength: return "dumbbell"
        case .yoga: return "figure.yoga"
        case .hiit: return "flame"
        }
    }
}

struct HealthStatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
