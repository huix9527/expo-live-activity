import ActivityKit
import SwiftUI
import WidgetKit

/// Example implementation showing how to read data from App Groups in Live Activity Widget
/// This demonstrates the complete workflow for accessing shared pet data

// MARK: - Example 1: Using AppGroupsHelper in Widget Configuration

/// Example WidgetBundle configuration
struct ExampleLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivityAttributes.self) { context in
      // Read pet data from shared container on first load
      let petData = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self)
      let avatarPath = petData?.avatarPath

      VStack(spacing: 16) {
        // Display pet name from shared data
        if let pet = petData {
          HStack(spacing: 12) {
            // Load and display pet avatar from shared images
            if let imagePath = AppGroupsHelper.getImagePath("pet-avatar.jpg"),
               let petImage = UIImage(contentsOfFile: imagePath) {
              Image(uiImage: petImage)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
              // Fallback to emoji if image not available
              Text("🐶")
                .font(.system(size: 32))
            }

            VStack(alignment: .leading) {
              Text(pet.name)
                .font(.headline)
              if let breed = pet.breed {
                Text(breed)
                  .font(.caption)
                  .foregroundStyle(.gray)
              }
            }

            Spacer()
          }
          .padding()
          .background(Color.gray.opacity(0.1))
          .cornerRadius(8)
        }

        // Display state data from context
        Text(context.state.title)
          .font(.title2)
          .fontWeight(.semibold)

        if let subtitle = context.state.subtitle {
          Text(subtitle)
            .font(.body)
            .foregroundStyle(.secondary)
        }
      }
      .padding()
    }
  }
}

// MARK: - Example 2: Widget with Data Refresh

/// Extension to track last read time and refresh data periodically
struct DataAwareActivityView: View {
  let contentState: LiveActivityAttributes.ContentState
  let attributes: LiveActivityAttributes

  @State private var petData: SharedPetData?
  @State private var petImage: UIImage?
  @State private var lastReadTime: Date = Date()

  var body: some View {
    VStack(spacing: 16) {
      // Pet information section
      if let pet = petData {
        HStack(spacing: 12) {
          // Pet avatar
          if let image = petImage {
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .frame(width: 50, height: 50)
              .clipShape(Circle())
          } else {
            Text("🐶")
              .font(.system(size: 28))
          }

          VStack(alignment: .leading, spacing: 4) {
            Text(pet.name)
              .font(.headline)
            Text(pet.breed ?? "Unknown breed")
              .font(.caption)
              .foregroundStyle(.gray)
          }

          Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
      }

      // Content state display
      Text(contentState.title)
        .font(.title3)
        .fontWeight(.semibold)

      if let subtitle = contentState.subtitle {
        Text(subtitle)
          .font(.body)
          .foregroundStyle(.secondary)
      }

      // Last update time
      Text("Updated: \(lastReadTime.formatted(date: .omitted, time: .shortened))")
        .font(.caption2)
        .foregroundStyle(.gray)
    }
    .padding()
    .onAppear {
      loadSharedData()
    }
  }

  private func loadSharedData() {
    // Read pet data from shared container
    if let data = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self) {
      petData = data

      // Load pet image
      if let imagePath = data.avatarPath,
         let image = UIImage(contentsOfFile: imagePath) {
        petImage = image
      } else if let image = AppGroupsHelper.loadImage("pet-avatar.jpg") {
        petImage = image
      }
    }

    // For debugging: print all shared files
    #if DEBUG
      AppGroupsHelper.debugPrintAllFiles()
    #endif

    lastReadTime = Date()
  }
}

// MARK: - Example 3: Safe Container Access Pattern

/// Demonstrates error handling and optional chaining
struct SafeDataAccessExample {
  /// Safely read configuration and fall back to defaults
  static func loadConfiguration() -> SharedActivityConfig {
    // Try to read configuration from shared container
    if let config = AppGroupsHelper.readJSON("activity-config", as: SharedActivityConfig.self) {
      return config
    }

    // Return default configuration if not found
    return SharedActivityConfig(
      showAvatar: true,
      updateInterval: 300,
      theme: "auto"
    )
  }

  /// Safely load pet image with fallback
  static func loadPetImageSafely() -> UIImage? {
    // First try to load from the expected path
    if let image = AppGroupsHelper.loadImage("pet-avatar.jpg") {
      return image
    }

    // If not found, try alternative location
    if let image = AppGroupsHelper.loadImage("current-pet-avatar.jpg") {
      return image
    }

    // Return nil if no image found
    print("⚠️ No pet image found in shared container")
    return nil
  }

  /// Check if shared data is fresh and valid
  static func isPetDataValid() -> Bool {
    guard let petData = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self) else {
      return false
    }

    // Verify data has required fields
    guard !petData.id.isEmpty && !petData.name.isEmpty else {
      return false
    }

    // Check if data was updated recently (within last hour)
    let dateFormatter = ISO8601DateFormatter()
    if let lastUpdated = dateFormatter.date(from: petData.lastUpdated) {
      let timeSinceUpdate = Date().timeIntervalSince(lastUpdated)
      return timeSinceUpdate < 3600  // 1 hour
    }

    return true
  }
}

// MARK: - Example 4: Debug View for Development

#if DEBUG
/// Development view to inspect shared container contents
struct DebugAppGroupsView: View {
  @State private var containerURL: String = ""
  @State private var petData: SharedPetData?
  @State private var configData: SharedActivityConfig?
  @State private var fileList: [String] = []
  @State private var petImage: UIImage?

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("App Groups Debug Info")
        .font(.headline)

      // Container URL
      if let url = AppGroupsHelper.getContainerURL() {
        VStack(alignment: .leading) {
          Text("Container URL:")
            .font(.caption)
            .fontWeight(.semibold)
          Text(url.path)
            .font(.caption2)
            .monospaced()
            .lineLimit(1)
        }
      }

      // Pet data
      if let pet = petData {
        VStack(alignment: .leading) {
          Text("Pet Data:")
            .font(.caption)
            .fontWeight(.semibold)
          Text("Name: \(pet.name)")
            .font(.caption2)
          Text("ID: \(pet.id)")
            .font(.caption2)
          Text("Breed: \(pet.breed ?? "N/A")")
            .font(.caption2)
        }
      }

      // Config data
      if let config = configData {
        VStack(alignment: .leading) {
          Text("Config:")
            .font(.caption)
            .fontWeight(.semibold)
          Text("Show Avatar: \(config.showAvatar)")
            .font(.caption2)
          Text("Update Interval: \(config.updateInterval)s")
            .font(.caption2)
          Text("Theme: \(config.theme)")
            .font(.caption2)
        }
      }

      // Files list
      if !fileList.isEmpty {
        VStack(alignment: .leading) {
          Text("Files:")
            .font(.caption)
            .fontWeight(.semibold)
          ForEach(fileList, id: \.self) { file in
            Text("• \(file)")
              .font(.caption2)
          }
        }
      }

      Button("Refresh Data") {
        petData = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self)
        configData = AppGroupsHelper.readJSON("activity-config", as: SharedActivityConfig.self)
        containerURL = AppGroupsHelper.getContainerURL()?.path ?? "N/A"
        petImage = AppGroupsHelper.loadImage("pet-avatar.jpg")
      }

      if let image = petImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(height: 100)
      }

      Spacer()
    }
    .padding()
    .onAppear {
      petData = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self)
      configData = AppGroupsHelper.readJSON("activity-config", as: SharedActivityConfig.self)
      containerURL = AppGroupsHelper.getContainerURL()?.path ?? "N/A"
      petImage = AppGroupsHelper.loadImage("pet-avatar.jpg")
      AppGroupsHelper.debugPrintAllFiles()
    }
  }
}

#endif
