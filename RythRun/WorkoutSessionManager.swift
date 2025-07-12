import SwiftUI
import HealthKit
import Combine

class WorkoutSessionManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isActive = false
    @Published var isPaused = false
    @Published var workoutType: WorkoutType?
    @Published var startTime: Date?
    @Published var endTime: Date?
    @Published var duration: TimeInterval = 0
    @Published var currentPhase: WorkoutPhase = .warmup
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Workout Management
    func startWorkout(type: WorkoutType) {
        guard !isActive else { return }
        
        self.workoutType = type
        self.startTime = Date()
        self.isActive = true
        self.isPaused = false
        self.duration = 0
        self.currentPhase = .warmup
        
        startHealthKitWorkout()
        startTimer()
        schedulePhaseTransitions()
        
        print("Started \(type.rawValue) workout")
    }
    
    func pauseWorkout() {
        guard isActive && !isPaused else { return }
        
        self.isPaused = true
        stopTimer()
        workoutSession?.pause()
        
        print("Workout paused")
    }
    
    func resumeWorkout() {
        guard isActive && isPaused else { return }
        
        self.isPaused = false
        startTimer()
        workoutSession?.resume()
        
        print("Workout resumed")
    }
    
    func endWorkout() {
        guard isActive else { return }
        
        self.endTime = Date()
        self.isActive = false
        self.isPaused = false
        self.currentPhase = .cooldown
        
        stopTimer()
        endHealthKitWorkout()
        
        print("Workout ended - Duration: \(formattedDuration)")
    }
    
    // MARK: - HealthKit Integration
    private func startHealthKitWorkout() {
        guard let workoutType = workoutType else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = healthKitActivityType(for: workoutType)
        configuration.locationType = .outdoor
        
        #if os(iOS) || os(watchOS)
        do {
            self.workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            self.workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("Failed to begin workout collection: \(error)")
                }
            }
            
        } catch {
            print("Failed to start workout session: \(error)")
        }
        #else
        print("HealthKit workout sessions not available on this platform")
        #endif
    }
    
    private func endHealthKitWorkout() {
        guard let workoutSession = workoutSession,
              let workoutBuilder = workoutBuilder else { return }
        
        workoutSession.end()
        
        workoutBuilder.endCollection(withEnd: Date()) { success, error in
            if let error = error {
                print("Failed to end workout collection: \(error)")
                return
            }
            
            workoutBuilder.finishWorkout { workout, error in
                if let error = error {
                    print("Failed to finish workout: \(error)")
                } else if let workout = workout {
                    print("Workout saved to HealthKit: \(workout)")
                }
            }
        }
    }
    
    private func healthKitActivityType(for workoutType: WorkoutType) -> HKWorkoutActivityType {
        switch workoutType {
        case .running:
            return .running
        case .cycling:
            return .cycling
        case .strength:
            return .functionalStrengthTraining
        case .yoga:
            return .yoga
        case .hiit:
            return .highIntensityIntervalTraining
        }
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.duration += 1.0
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        self.timer = nil
    }
    
    // MARK: - Workout Phase Management
    private func schedulePhaseTransitions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
            if self.isActive && !self.isPaused {
                self.currentPhase = .main
                print("Transitioning to main workout phase")
            }
        }
    }
    
    func transitionToCooldown() {
        self.currentPhase = .cooldown
        print("Transitioning to cooldown phase")
    }
}

// MARK: - Spotify Authentication View
struct SpotifyAuthView: View {
    let musicEngine: MLMusicEngine
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Connect to Spotify")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Connect your Spotify account to get AI-powered music recommendations based on your health data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    BenefitRow(
                        icon: "brain.head.profile",
                        title: "AI Music Analysis",
                        description: "Machine learning algorithms analyze your music preferences"
                    )
                    
                    BenefitRow(
                        icon: "waveform.path.ecg",
                        title: "Health-Based Recommendations",
                        description: "Music suggestions based on real-time health metrics"
                    )
                    
                    BenefitRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Performance Optimization",
                        description: "Tempo and energy matching for optimal workout performance"
                    )
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: authenticateWithSpotify) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "music.note")
                                    .font(.title2)
                            }
                            
                            Text(isLoading ? "Connecting..." : "Connect with Spotify")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    
                    Button("Skip for Now") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Spotify Integration")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func authenticateWithSpotify() {
        isLoading = true
        musicEngine.authenticateWithSpotify()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            dismiss()
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
