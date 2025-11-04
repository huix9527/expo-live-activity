import Foundation

/// Helper class for reading data from App Groups shared container
/// Used by Live Activity Widget to fetch data shared from main app
struct AppGroupsHelper {
  private static let appGroupIdentifier = "group.com.epbs.fun.patpet"

  // MARK: - Container Access

  /// Get the shared container URL
  static func getContainerURL() -> URL? {
    return FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
  }

  // MARK: - JSON Reading

  /// Read and decode JSON from shared container
  /// - Parameters:
  ///   - fileName: File name without extension (e.g., "current-pet")
  ///   - type: The Decodable type to decode into
  /// - Returns: Decoded object or nil if not found or decode fails
  static func readJSON<T: Decodable>(_ fileName: String, as type: T.Type) -> T? {
    guard let containerURL = getContainerURL() else {
      print("❌ Failed to access App Groups container")
      return nil
    }

    let fileURL = containerURL
      .appendingPathComponent("data")
      .appendingPathComponent("\(fileName).json")

    do {
      let data = try Data(contentsOf: fileURL)
      let decoder = JSONDecoder()
      let decoded = try decoder.decode(type, from: data)
      print("✅ Successfully read JSON: \(fileName)")
      return decoded
    } catch {
      print("❌ Failed to read JSON '\(fileName)': \(error)")
      return nil
    }
  }

  // MARK: - Image Reading

  /// Get the absolute path to a shared image
  /// - Parameter imageName: Image filename (e.g., "pet-avatar.jpg")
  /// - Returns: Absolute path to the image or nil if not found
  static func getImagePath(_ imageName: String) -> String? {
    guard let containerURL = getContainerURL() else {
      return nil
    }

    let imageURL = containerURL
      .appendingPathComponent("images")
      .appendingPathComponent(imageName)

    // Check if file exists
    if FileManager.default.fileExists(atPath: imageURL.path) {
      print("✅ Image found at: \(imageURL.path)")
      return imageURL.path
    } else {
      print("⚠️ Image not found: \(imageName)")
      return nil
    }
  }

  /// Load image from shared container
  /// - Parameter imageName: Image filename
  /// - Returns: UIImage or nil if not found/failed to load
  static func loadImage(_ imageName: String) -> UIImage? {
    guard let imagePath = getImagePath(imageName) else {
      return nil
    }

    guard let image = UIImage(contentsOfFile: imagePath) else {
      print("❌ Failed to load image from: \(imagePath)")
      return nil
    }

    print("✅ Successfully loaded image: \(imageName)")
    return image
  }

  // MARK: - File Reading

  /// Read text file from shared container
  /// - Parameter fileName: Relative path from container root (e.g., "data/config.json")
  /// - Returns: File content as string or nil if not found
  static func readFile(_ fileName: String) -> String? {
    guard let containerURL = getContainerURL() else {
      return nil
    }

    let fileURL = containerURL.appendingPathComponent(fileName)

    do {
      let content = try String(contentsOf: fileURL, encoding: .utf8)
      print("✅ Successfully read file: \(fileName)")
      return content
    } catch {
      print("❌ Failed to read file '\(fileName)': \(error)")
      return nil
    }
  }

  // MARK: - File Existence

  /// Check if file exists in shared container
  /// - Parameter fileName: Relative path from container root
  /// - Returns: true if file exists
  static func fileExists(_ fileName: String) -> Bool {
    guard let containerURL = getContainerURL() else {
      return false
    }

    let fileURL = containerURL.appendingPathComponent(fileName)
    return FileManager.default.fileExists(atPath: fileURL.path)
  }

  // MARK: - Debug

  /// Print all files in shared container (for debugging)
  static func debugPrintAllFiles() {
    guard let containerURL = getContainerURL() else {
      print("❌ Cannot access App Groups container")
      return
    }

    print("📦 Shared Container URL: \(containerURL.path)")

    do {
      let contents = try FileManager.default.contentsOfDirectory(
        at: containerURL,
        includingPropertiesForKeys: nil
      )

      for item in contents {
        let isDir = (try item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        if isDir {
          print("📁 \(item.lastPathComponent)/")
          let subItems = try FileManager.default.contentsOfDirectory(at: item, includingPropertiesForKeys: nil)
          for subItem in subItems {
            print("  📄 \(subItem.lastPathComponent)")
          }
        } else {
          print("📄 \(item.lastPathComponent)")
        }
      }
    } catch {
      print("❌ Failed to list files: \(error)")
    }
  }
}

// MARK: - Pet Data Models

/// Pet data structure matching the one shared from main app
struct SharedPetData: Codable {
  let id: String
  let name: String
  let breed: String?
  let avatarPath: String?
  let lastUpdated: String

  enum CodingKeys: String, CodingKey {
    case id, name, breed
    case avatarPath = "avatarPath"
    case lastUpdated
  }
}

/// Activity configuration shared from main app
struct SharedActivityConfig: Codable {
  let showAvatar: Bool
  let updateInterval: Int
  let theme: String  // "light", "dark", "auto"
}
