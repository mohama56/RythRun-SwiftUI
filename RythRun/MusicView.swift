import SwiftUI

struct MusicView: View {
    @EnvironmentObject var musicEngine: MLMusicEngine
    @State private var showingSpotifyAuth = false
    @State private var isConnected = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Music Engine")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Machine Learning-powered music recommendations for optimal workout performance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Connection Status
                    connectionStatusSection
                    
                    if isConnected {
                        // ML Predictions
                        mlPredictionsSection
                        
                        // Music Controls
                        musicControlsSection
                    }
                    
                    // Settings
                    settingsSection
                }
                .padding()
            }
            .navigationTitle("Music")
            .sheet(isPresented: $showingSpotifyAuth) {
                SpotifyAuthView(musicEngine: musicEngine)
            }
        }
    }
    
    // MARK: - Connection Status Section
    private var connectionStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isConnected ? .green : .red)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Spotify Connection")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(isConnected ? "Connected to Spotify" : "Not Connected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !isConnected {
                    Button("Connect") {
                        isConnected = true // Simple toggle for now
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            if !isConnected {
                Button(action: { isConnected = true }) {
                    HStack {
                        Image(systemName: "music.note")
                            .font(.title2)
                        
                        Text("Connect with Spotify")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - ML Predictions Section
    private var mlPredictionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current ML Predictions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MLPredictionCard(
                    title: "Optimal Energy",
                    value: "0.75",
                    color: .orange
                )
                
                MLPredictionCard(
                    title: "Optimal Tempo",
                    value: "140 BPM",
                    color: .blue
                )
                
                MLPredictionCard(
                    title: "Optimal Valence",
                    value: "0.68",
                    color: .green
                )
                
                MLPredictionCard(
                    title: "ML Confidence",
                    value: "92%",
                    color: .purple
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Music Controls Section
    private var musicControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Music Controls")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Now Playing (if available)
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading) {
                        Text("No Track Playing")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Connect to start AI recommendations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.05))
                .cornerRadius(12)
                
                // Control Buttons
                HStack(spacing: 16) {
                    Button("Get Recommendations") {
                        // Generate ML recommendations
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    
                    Button("Sync Health") {
                        // Sync with health data
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SettingRow(
                    title: "ML Model Training",
                    subtitle: "Help improve recommendations with your feedback",
                    icon: "brain.head.profile"
                ) {
                    print("ML training settings")
                }
                
                SettingRow(
                    title: "Music Preferences",
                    subtitle: "Customize your music taste profile",
                    icon: "music.note.list"
                ) {
                    print("Music preferences")
                }
                
                SettingRow(
                    title: "Health Integration",
                    subtitle: "Configure health data usage",
                    icon: "heart.fill"
                ) {
                    print("Health integration")
                }
                
                SettingRow(
                    title: "Export Data",
                    subtitle: "Export your music and health correlation data",
                    icon: "square.and.arrow.up"
                ) {
                    print("Export data")
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views

struct MLPredictionCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SettingRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}
