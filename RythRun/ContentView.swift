import SwiftUI
import HealthKit
import MediaPlayer
import AVFoundation

#if os(iOS)
import CoreMotion
#endif

struct ContentView: View {
    @StateObject private var healthManager = HealthKitManager()
    @StateObject private var musicEngine = MLMusicEngine()
    @StateObject private var workoutSession = WorkoutSessionManager()
    @State private var selectedTab = 0
    @State private var isLoggedIn = false
    @State private var showingSpotifyAuth = false
    
    var body: some View {
        if isLoggedIn {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Dashboard")
                    }
                    .tag(0)
                
                HealthMetricsView()
                    .tabItem {
                        Image(systemName: "heart.fill")
                        Text("Health")
                    }
                    .tag(1)
                
                WorkoutView()
                    .tabItem {
                        Image(systemName: "figure.run")
                        Text("Workout")
                    }
                    .tag(2)
                
                MusicView()
                    .tabItem {
                        Image(systemName: "music.note")
                        Text("Music")
                    }
                    .tag(3)
            }
            .accentColor(.blue)
            .sheet(isPresented: $showingSpotifyAuth) {
                SpotifyAuthView(musicEngine: musicEngine)
            }
            .environmentObject(healthManager)
            .environmentObject(musicEngine)
            .environmentObject(workoutSession)
            .onAppear {
                requestHealthPermissions()
                setupMusicNotifications()
            }
        } else {
            LoginView(isLoggedIn: $isLoggedIn)
                .environmentObject(healthManager)
                .environmentObject(musicEngine)
                .environmentObject(workoutSession)
                .onAppear {
                    requestHealthPermissions()
                    setupMusicNotifications()
                }
        }
    }
    
    private func requestHealthPermissions() {
        healthManager.requestAuthorization { success in
            if success {
                healthManager.startRealTimeMonitoring()
                print("HealthKit authorization granted")
            }
        }
    }
    
    private func setupMusicNotifications() {
        musicEngine.setupNotifications()
    }
}

// MARK: - HealthKitManager Implementation
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
#if os(iOS)
    private let motionManager = CMMotionManager()
#endif
    
    // Published properties for real-time monitoring
    @Published var currentHeartRate: Double = 0.0
    @Published var hrv: Double = 0.0
    @Published var cadence: Double = 0.0
    @Published var recoveryIndex: Double = 0.0
    @Published var performanceZone: Int = 1
    @Published var trainingLoad: Double = 0.0
    @Published var intensityScore: Double = 0.0
    @Published var fatigueIndex: Double = 0.0
    
    // Health data types to read
    private let healthTypesToRead: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    ]
    
    init() {
        setupMockData()
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: healthTypesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func startRealTimeMonitoring() {
        // Start heart rate monitoring
        startHeartRateQuery()
        
        // Setup mock data updates
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.updateMockHealthData()
        }
    }
    
    private func startHeartRateQuery() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            
            guard let samples = samples as? [HKQuantitySample] else { return }
            
            DispatchQueue.main.async {
                if let latestSample = samples.last {
                    self?.currentHeartRate = latestSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    self?.updatePerformanceZone()
                }
            }
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else { return }
            
            DispatchQueue.main.async {
                if let latestSample = samples.last {
                    self?.currentHeartRate = latestSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    self?.updatePerformanceZone()
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func updatePerformanceZone() {
        let hr = currentHeartRate > 0 ? currentHeartRate : 72
        
        if hr < 114 {
            performanceZone = 1
        } else if hr < 133 {
            performanceZone = 2
        } else if hr < 152 {
            performanceZone = 3
        } else if hr < 171 {
            performanceZone = 4
        } else {
            performanceZone = 5
        }
    }
    
    private func setupMockData() {
        currentHeartRate = 75.0
        hrv = 42.0
        cadence = 180.0
        recoveryIndex = 85.0
        performanceZone = 2
        trainingLoad = 280.0
        intensityScore = 7.2
        fatigueIndex = 3.1
    }
    
    private func updateMockHealthData() {
        // Simulate realistic health data fluctuations
        currentHeartRate = Double.random(in: 70...85)
        hrv = Double.random(in: 35...55)
        cadence = Double.random(in: 170...190)
        recoveryIndex = Double.random(in: 75...95)
        trainingLoad = Double.random(in: 250...350)
        intensityScore = Double.random(in: 6.0...8.5)
        fatigueIndex = Double.random(in: 2.0...4.0)
        
        updatePerformanceZone()
    }
    
    func sendHealthDataToBackend() {
        let healthData: [String: Any] = [
            "heart_rate": currentHeartRate,
            "hrv": hrv,
            "cadence": cadence,
            "recovery_index": recoveryIndex,
            "performance_zone": performanceZone,
            "training_load": trainingLoad,
            "intensity_score": intensityScore,
            "fatigue_index": fatigueIndex,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Send to music engine for backend processing
        if let musicEngine = self.getMusicEngineInstance() {
            musicEngine.sendHealthDataToBackend(healthData)
        }
    }
    
    private func getMusicEngineInstance() -> MLMusicEngine? {
        // This would be injected or accessed through environment in real implementation
        return nil
    }
}
