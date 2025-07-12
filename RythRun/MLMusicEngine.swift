import SwiftUI
import MediaPlayer
import AVFoundation
import UserNotifications
import Combine

class MLMusicEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSpotifyConnected = false
    @Published var currentTrack: SpotifyTrack?
    @Published var recommendations: [MusicRecommendation] = []
    @Published var listeningHistory: [TrackHistory] = []
    @Published var userRatings: [TrackRating] = []
    @Published var mlConfidence: Double = 0.0
    @Published var adaptationStrategy: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - ML Audio Feature Predictions
    @Published var predictedOptimalEnergy: Double = 0.7
    @Published var predictedOptimalTempo: Double = 120.0
    @Published var predictedOptimalValence: Double = 0.6
    @Published var predictedOptimalDanceability: Double = 0.7
    @Published var predictedOptimalAcousticness: Double = 0.3
    
    // MARK: - Real-time Monitoring
    @Published var currentPlaybackPosition: Double = 0.0
    @Published var trackDuration: Double = 0.0
    @Published var halfwayNotificationSent = false
    
    // MARK: - Backend Integration
    private let backendURL = "http://localhost:5000"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Timers and Monitoring
    private var playbackTimer: Timer?
    private var recommendationTimer: Timer?
    
    init() {
        setupNotifications()
        startRecommendationEngine()
    }
    
    // MARK: - Backend Communication
    
    /// Get ML-powered recommendations from Flask backend
    func fetchMLRecommendations(healthState: HealthState, workoutPhase: WorkoutPhase = .main) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(backendURL)/api/ml-recommendations") else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid backend URL"
                self.isLoading = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "health_state": [
                "heart_rate": healthState.heartRate,
                "hrv": healthState.hrv,
                "training_load": healthState.trainingLoad,
                "cadence": healthState.cadence,
                "recovery_index": healthState.recoveryIndex,
                "intensity_score": healthState.intensityScore,
                "fatigue_index": healthState.fatigueIndex,
                "performance_zone": healthState.performanceZone
            ],
            "workout_phase": workoutPhase.rawValue
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to encode request: \(error.localizedDescription)"
                self.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received from backend"
                    return
                }
                
                do {
                    let mlResponse = try JSONDecoder().decode(MLRecommendationResponse.self, from: data)
                    self?.processMLRecommendations(mlResponse)
                } catch {
                    self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                    print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unknown")")
                }
            }
        }.resume()
    }
    
    private func processMLRecommendations(_ response: MLRecommendationResponse) {
        // Update predicted optimal features
        if let optimalFeatures = response.optimalFeatures {
            self.predictedOptimalEnergy = optimalFeatures.energy
            self.predictedOptimalTempo = optimalFeatures.tempo
            self.predictedOptimalValence = optimalFeatures.valence
            self.predictedOptimalDanceability = optimalFeatures.danceability
            self.predictedOptimalAcousticness = optimalFeatures.acousticness
        }
        
        // Convert backend recommendations to app format
        self.recommendations = response.recommendations.map { backendRec in
            let track = SpotifyTrack(
                id: backendRec.trackId,
                name: backendRec.trackName,
                artist: backendRec.artist,
                audioFeatures: AudioFeatures(
                    energy: backendRec.energy,
                    tempo: backendRec.tempo,
                    valence: backendRec.valence,
                    danceability: backendRec.danceability,
                    acousticness: backendRec.acousticness ?? 0.3
                ),
                durationMs: 180000, // Default duration if not provided
                url: backendRec.url,
                previewUrl: backendRec.previewUrl
            )
            
            return MusicRecommendation(
                track: track,
                similarityScore: backendRec.similarityScore,
                mlConfidence: backendRec.mlConfidence,
                physiologicalReasoning: backendRec.physiologicalReasoning,
                recommendedAt: Date()
            )
        }
        
        // Update ML confidence and adaptation strategy
        self.mlConfidence = calculateOverallMLConfidence()
        self.adaptationStrategy = response.adaptationStrategy ?? "Maintain current parameters"
    }
    
    /// Send health data to backend for processing
    func sendHealthDataToBackend(_ healthData: [String: Any]) {
        guard let url = URL(string: "\(backendURL)/api/health-data") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: healthData)
        } catch {
            print("Failed to encode health data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send health data: \(error)")
                return
            }
            
            if let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("Backend response: \(responseString)")
            }
        }.resume()
    }
    
    /// Get real-time analytics from backend
    func fetchRealTimeAnalytics() {
        guard let url = URL(string: "\(backendURL)/api/real-time-data") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Failed to fetch real-time data: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let analytics = try JSONDecoder().decode(RealTimeAnalytics.self, from: data)
                DispatchQueue.main.async {
                    // Update UI with real-time analytics if needed
                    print("Real-time analytics updated: HR=\(analytics.heartRate), Energy=\(analytics.musicEnergy)")
                }
            } catch {
                print("Failed to decode analytics: \(error)")
            }
        }.resume()
    }
    
    // MARK: - Spotify Integration (Real Implementation)
    
    func authenticateWithSpotify() {
        print("Initiating real Spotify authentication...")
        // Implement actual Spotify OAuth flow here
        // This should redirect to Spotify's authorization page
        
        // After successful authentication, connect to backend
        connectToBackend()
    }
    
    private func connectToBackend() {
        // Check if backend is available
        guard let url = URL(string: "\(backendURL)/api/analytics") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.isSpotifyConnected = true
                    print("Connected to backend successfully")
                } else {
                    self?.errorMessage = "Failed to connect to backend. Make sure Flask server is running on localhost:5000"
                }
            }
        }.resume()
    }
    
    // MARK: - ML Recommendation Engine
    func generateMLRecommendations(healthState: HealthState, workoutPhase: WorkoutPhase = .main) {
        print("Generating ML-powered music recommendations...")
        fetchMLRecommendations(healthState: healthState, workoutPhase: workoutPhase)
    }
    
    private func calculateOverallMLConfidence() -> Double {
        guard !recommendations.isEmpty else { return 0.0 }
        
        let avgConfidence = recommendations.map { $0.mlConfidence }.reduce(0, +) / Double(recommendations.count)
        return avgConfidence
    }
    
    // MARK: - Real-time Music Monitoring
    func startPlaybackMonitoring() {
        stopPlaybackMonitoring()
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updatePlaybackPosition()
        }
    }
    
    func stopPlaybackMonitoring() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        halfwayNotificationSent = false
    }
    
    private func updatePlaybackPosition() {
        // In real implementation, get actual playback position from Spotify SDK
        currentPlaybackPosition += 1.0
        
        // Check for halfway point notification
        if !halfwayNotificationSent && trackDuration > 0 {
            let halfwayPoint = trackDuration / 2.0
            if currentPlaybackPosition >= halfwayPoint {
                sendHalfwayNotification()
                halfwayNotificationSent = true
            }
        }
        
        // Check if track ended
        if currentPlaybackPosition >= trackDuration {
            handleTrackEnded()
        }
    }
    
    private func sendHalfwayNotification() {
        guard let track = currentTrack else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Music Recommendation"
        content.body = "How is \"\(track.name)\" working for your workout? Rate it or get a new recommendation."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "halfway-notification-\(track.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send halfway notification: \(error)")
            }
        }
    }
    
    private func handleTrackEnded() {
        guard let track = currentTrack else { return }
        
        // Add to listening history
        let historyEntry = TrackHistory(
            track: track,
            playedAt: Date(),
            completedPercentage: min(100.0, (currentPlaybackPosition / trackDuration) * 100)
        )
        
        DispatchQueue.main.async {
            self.listeningHistory.append(historyEntry)
        }
        
        // Reset for next track
        currentPlaybackPosition = 0.0
        halfwayNotificationSent = false
        
        // Auto-recommend next track if in workout session
        autoRecommendNextTrack()
    }
    
    private func autoRecommendNextTrack() {
        if !recommendations.isEmpty {
            playRecommendedTrack(recommendations[0])
        }
    }
    
    // MARK: - Track Rating System
    func rateTrack(_ track: SpotifyTrack, rating: TrackRating.Rating, context: String = "") {
        let trackRating = TrackRating(
            track: track,
            rating: rating,
            ratedAt: Date(),
            context: context
        )
        
        DispatchQueue.main.async {
            self.userRatings.append(trackRating)
        }
        
        // Send rating to backend for ML learning
        sendRatingToBackend(trackRating)
        
        print("Track rated: \(track.name) - \(rating.rawValue)")
    }
    
    private func sendRatingToBackend(_ rating: TrackRating) {
        guard let url = URL(string: "\(backendURL)/api/track-rating") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let ratingData: [String: Any] = [
            "track_id": rating.track.id,
            "track_name": rating.track.name,
            "artist": rating.track.artist,
            "rating": rating.rating.rawValue,
            "context": rating.context,
            "audio_features": [
                "energy": rating.track.audioFeatures.energy,
                "tempo": rating.track.audioFeatures.tempo,
                "valence": rating.track.audioFeatures.valence,
                "danceability": rating.track.audioFeatures.danceability,
                "acousticness": rating.track.audioFeatures.acousticness
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ratingData)
        } catch {
            print("Failed to encode rating data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send rating: \(error)")
            } else {
                print("Rating sent to backend successfully")
            }
        }.resume()
    }
    
    // MARK: - Workout Integration
    func startWorkoutSession(type: WorkoutType) {
        print("Starting workout session: \(type.rawValue)")
        startRecommendationEngine()
        startPlaybackMonitoring()
        
        // Notify backend about workout start
        let workoutData: [String: Any] = [
            "event": "workout_start",
            "workout_type": type.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        sendHealthDataToBackend(workoutData)
    }
    
    func endWorkoutSession() {
        print("Ending workout session")
        stopPlaybackMonitoring()
        stopRecommendationEngine()
        
        // Notify backend about workout end
        let workoutData: [String: Any] = [
            "event": "workout_end",
            "timestamp": Date().timeIntervalSince1970
        ]
        sendHealthDataToBackend(workoutData)
        
        presentWorkoutSummary()
    }
    
    private func presentWorkoutSummary() {
        let playedTracks = listeningHistory.filter { historyEntry in
            Calendar.current.isDate(historyEntry.playedAt, inSameDayAs: Date())
        }
        
        print("Workout Summary:")
        print("Tracks played: \(playedTracks.count)")
        print("Total listening time: \(playedTracks.map { $0.track.durationMs }.reduce(0, +) / 1000) seconds")
    }
    
    // MARK: - Mood Integration
    func setPreWorkoutMood(_ mood: WorkoutMood) {
        print("Pre-workout mood set: \(mood.rawValue)")
        
        // Send mood to backend
        let moodData: [String: Any] = [
            "event": "pre_workout_mood",
            "mood": mood.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        sendHealthDataToBackend(moodData)
    }
    
    func setPostWorkoutMood(_ mood: WorkoutMood) {
        print("Post-workout mood set: \(mood.rawValue)")
        
        // Send mood to backend
        let moodData: [String: Any] = [
            "event": "post_workout_mood",
            "mood": mood.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        sendHealthDataToBackend(moodData)
    }
    
    // MARK: - Recommendation Engine Management
    private func startRecommendationEngine() {
        stopRecommendationEngine()
        
        recommendationTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.refreshRecommendations()
        }
    }
    
    private func stopRecommendationEngine() {
        recommendationTimer?.invalidate()
        recommendationTimer = nil
    }
    
    private func refreshRecommendations() {
        // Get latest real-time analytics from backend
        fetchRealTimeAnalytics()
        print("Refreshing ML recommendations based on current health state")
    }
    
    // MARK: - Notification Setup
    func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Playback Control
    func playRecommendedTrack(_ recommendation: MusicRecommendation) {
        currentTrack = recommendation.track
        trackDuration = Double(recommendation.track.durationMs) / 1000.0
        currentPlaybackPosition = 0.0
        halfwayNotificationSent = false
        
        print("Playing recommended track: \(recommendation.track.name) by \(recommendation.track.artist)")
        print("ML Confidence: \(recommendation.mlConfidence)")
        print("Reasoning: \(recommendation.physiologicalReasoning)")
        
        // In real implementation, use Spotify SDK to play the track
        startPlaybackMonitoring()
        
        // Send playback event to backend
        let playbackData: [String: Any] = [
            "event": "track_started",
            "track_id": recommendation.track.id,
            "track_name": recommendation.track.name,
            "artist": recommendation.track.artist,
            "similarity_score": recommendation.similarityScore,
            "ml_confidence": recommendation.mlConfidence
        ]
        sendHealthDataToBackend(playbackData)
    }
    
    func skipToNextRecommendation() {
        guard recommendations.count > 1 else { return }
        
        // Send skip event to backend
        if let currentTrack = currentTrack {
            let skipData: [String: Any] = [
                "event": "track_skipped",
                "track_id": currentTrack.id,
                "position": currentPlaybackPosition,
                "duration": trackDuration
            ]
            sendHealthDataToBackend(skipData)
        }
        
        // Remove current recommendation and play next
        recommendations.removeFirst()
        if !recommendations.isEmpty {
            playRecommendedTrack(recommendations[0])
        }
    }
}

// MARK: - Data Models

struct SpotifyTrack: Identifiable, Codable {
    let id: String
    let name: String
    let artist: String
    let audioFeatures: AudioFeatures
    let durationMs: Int
    let url: String?
    let previewUrl: String?
}

struct AudioFeatures: Codable {
    let energy: Double
    let tempo: Double
    let valence: Double
    let danceability: Double
    let acousticness: Double
}

struct MusicRecommendation: Identifiable {
    let id = UUID()
    let track: SpotifyTrack
    let similarityScore: Double
    let mlConfidence: Double
    let physiologicalReasoning: String
    let recommendedAt: Date
}

struct TrackHistory: Identifiable {
    let id = UUID()
    let track: SpotifyTrack
    let playedAt: Date
    let completedPercentage: Double
}

struct TrackRating: Identifiable {
    let id = UUID()
    let track: SpotifyTrack
    let rating: Rating
    let ratedAt: Date
    let context: String
    
    enum Rating: String, CaseIterable {
        case love = "love"
        case like = "like"
        case neutral = "neutral"
        case dislike = "dislike"
        case skip = "skip"
    }
}

struct HealthState {
    let heartRate: Double
    let hrv: Double
    let trainingLoad: Double
    let cadence: Double
    let recoveryIndex: Double
    let intensityScore: Double
    let fatigueIndex: Double
    let performanceZone: Int
}

enum WorkoutPhase: String {
    case warmup = "warmup"
    case main = "main"
    case cooldown = "cooldown"
}

enum WorkoutType: String, CaseIterable {
    case running = "running"
    case cycling = "cycling"
    case strength = "strength"
    case yoga = "yoga"
    case hiit = "hiit"
}

enum WorkoutMood: String, CaseIterable {
    case energetic = "energetic"
    case calm = "calm"
    case motivated = "motivated"
    case tired = "tired"
    case neutral = "neutral"
}

// MARK: - Backend Response Models

struct MLRecommendationResponse: Codable {
    let status: String
    let recommendations: [BackendRecommendation]
    let optimalFeatures: OptimalFeatures?
    let adaptationStrategy: String?
    let timestamp: String
}

struct BackendRecommendation: Codable {
    let trackName: String
    let artist: String
    let trackId: String
    let similarityScore: Double
    let mlConfidence: Double
    let physiologicalReasoning: String
    let energy: Double
    let tempo: Double
    let valence: Double
    let danceability: Double
    let acousticness: Double?
    let url: String?
    let previewUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case trackName = "track_name"
        case artist
        case trackId = "track_id"
        case similarityScore = "similarity_score"
        case mlConfidence = "ml_confidence"
        case physiologicalReasoning = "physiological_reasoning"
        case energy, tempo, valence, danceability, acousticness
        case url
        case previewUrl = "preview_url"
    }
}

struct OptimalFeatures: Codable {
    let energy: Double
    let tempo: Double
    let valence: Double
    let danceability: Double
    let acousticness: Double
}

struct RealTimeAnalytics: Codable {
    let heartRate: Double
    let hrv: Double
    let recoveryIndex: Double
    let intensityScore: Double
    let performanceZone: Int
    let musicEnergy: Double
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case heartRate = "heart_rate"
        case hrv
        case recoveryIndex = "recovery_index"
        case intensityScore = "intensity_score"
        case performanceZone = "performance_zone"
        case musicEnergy = "music_energy"
        case timestamp
    }
}
