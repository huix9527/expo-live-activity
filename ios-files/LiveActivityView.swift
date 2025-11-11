import SwiftUI
import WidgetKit

#if canImport(ActivityKit)

  struct ConditionalForegroundViewModifier: ViewModifier {
    let color: String?

    func body(content: Content) -> some View {
      if let color = color {
        content.foregroundStyle(Color(hex: color))
      } else {
        content
      }
    }
  }

  struct DebugLog: View {
    #if DEBUG
      private let message: String
      init(_ message: String) {
        self.message = message
        print(message)
      }

      var body: some View {
        Text(message)
          .font(.caption2)
          .foregroundStyle(.red)
      }
    #else
      init(_: String) {}
      var body: some View { EmptyView() }
    #endif
  }

  struct LiveActivityView: View {
    let contentState: LiveActivityAttributes.ContentState
    let attributes: LiveActivityAttributes
    @State private var imageContainerSize: CGSize?
    @State private var debugInfo: String = ""
    @State private var isDebugExpanded: Bool = false
    @State private var avatarImage: UIImage? = nil

    var progressViewTint: Color? {
      attributes.progressViewTint.map { Color(hex: $0) }
    }

    private var imageAlignment: Alignment {
      switch attributes.imageAlign {
      case "center":
        return .center
      case "bottom":
        return .bottom
      default:
        return .top
      }
    }

    private var petEmoji: String {
      let species = contentState.species ?? attributes.petSpecies ?? "dog"
      switch species.lowercased() {
      case "cat", "feline", "猫":
        return "🐱"
      case "dog", "canine", "犬", "狗":
        return "🐶"
      default:
        return "🐶"
      }
    }

    #if DEBUG
    private func captureDebugInfo() {
      var info = ""
      let appGroupID = "group.com.epbs.fun.patpet"

      // 1. 检查容器访问权限
      let fileManager = FileManager.default
      guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
        info = "❌ PERMISSION ERROR\n"
        info += "无法访问 App Groups\n\n"
        info += "请检查：\n"
        info += "• Entitlements 配置\n"
        info += "• App Group ID\n"
        info += "• Code Signing"
        self.debugInfo = info
        print("🔴 Widget - Cannot access App Groups container")
        return
      }

      info += "📦 Container OK\n"
      info += "ID: \(appGroupID)\n"
      info += "Path: \(containerURL.path)\n\n"

      // 2. 列出文件
      do {
        let contents = try fileManager.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)

        if contents.isEmpty {
          info += "⚠️ Container is EMPTY\n\n"
          info += "主应用未写入数据\n"
          info += "请在主应用中调用：\n"
          info += "AppgroupStorageHelper\n"
          info += "  .writeJSON(...)"
        } else {
          info += "✅ 文件列表:\n"
          for item in contents {
            let isDir = (try item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
              info += "📂 \(item.lastPathComponent)/\n"
              let subItems = try fileManager.contentsOfDirectory(at: item, includingPropertiesForKeys: nil)

              if subItems.isEmpty {
                info += "  (empty)\n"
              } else {
                for subItem in subItems {
                  info += "  📄 \(subItem.lastPathComponent)"

                  // 显示文件大小
                  if let attrs = try? fileManager.attributesOfItem(atPath: subItem.path),
                     let size = attrs[.size] as? Int {
                    info += " (\(size) bytes)"
                  }
                  info += "\n"

                  // 特别检查 avatar.png
                  if subItem.lastPathComponent == "avatar.png" {
                    let avatarPath = subItem.path
                    if let img = UIImage(contentsOfFile: avatarPath) {
                      info += "    ✅ Image loaded: \(Int(img.size.width))x\(Int(img.size.height))\n"
                    } else {
                      info += "    ❌ Failed to load image\n"
                    }
                  }
                }
              }
            } else {
              info += "📄 \(item.lastPathComponent)\n"
            }
          }
        }
      } catch {
        info += "❌ Read Error:\n"
        info += error.localizedDescription
      }

      self.debugInfo = info
      print("🟡 Widget - Debug Info:\n\(info)")
    }
    #endif

    private func alignedImage(imageName: String) -> some View {
      let defaultHeight: CGFloat = 64
      let computedHeight = CGFloat(attributes.imageSize ?? Int(defaultHeight))
      let computedWidth: CGFloat? = nil

      return ZStack(alignment: .center) {
        Group {
          let fit = attributes.contentFit ?? "cover"
          switch fit {
          case "contain":
            Image.dynamic(assetNameOrPath: imageName).resizable().scaledToFit().frame(width: computedWidth, height: computedHeight)
          case "fill":
            Image.dynamic(assetNameOrPath: imageName).resizable().frame(
              width: computedWidth,
              height: computedHeight
            )
          case "none":
            Image.dynamic(assetNameOrPath: imageName).renderingMode(.original).frame(width: computedWidth, height: computedHeight)
          case "scale-down":
            Image.dynamic(assetNameOrPath: imageName).resizable().scaledToFit().frame(width: computedWidth, height: computedHeight)
          case "cover":
            Image.dynamic(assetNameOrPath: imageName).resizable().scaledToFill().frame(
              width: computedWidth,
              height: computedHeight
            ).clipped()
          default:
            DebugLog("⚠️ [ExpoLiveActivity] Unknown contentFit '\(fit)'")
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: imageAlignment)
      .background(
        GeometryReader { proxy in
          Color.clear
            .onAppear {
              let s = proxy.size
              if s.width > 0, s.height > 0 { imageContainerSize = s }
            }
            .onChange(of: proxy.size) { s in
              if s.width > 0, s.height > 0 { imageContainerSize = s }
            }
        }
      )
    }

    var body: some View {
      let defaultPadding = 24

      let top = CGFloat(
        attributes.paddingDetails?.top
          ?? attributes.paddingDetails?.vertical
          ?? attributes.padding
          ?? defaultPadding
      )

      let bottom = CGFloat(
        attributes.paddingDetails?.bottom
          ?? attributes.paddingDetails?.vertical
          ?? attributes.padding
          ?? defaultPadding
      )

      let leading = CGFloat(
        attributes.paddingDetails?.left
          ?? attributes.paddingDetails?.horizontal
          ?? attributes.padding
          ?? defaultPadding
      )

      let trailing = CGFloat(
        attributes.paddingDetails?.right
          ?? attributes.paddingDetails?.horizontal
          ?? attributes.padding
          ?? defaultPadding
      )

      // 显示正常的 Live Activity 内容
      VStack(alignment: .leading, spacing: 16) {
        // Time badge and logo row
        let timeText = contentState.time ?? "--:--"
        HStack {
          // Time badge at left
          HStack(spacing: 6) {
            Circle()
              .fill(Color(hex:"D6FFA3"))
              .frame(width: 8, height: 8)

            Text(timeText)
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(Color(hex: "D6FFA3"))
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(
            Capsule()
              .fill(Color(hex: "D6FFA3").opacity(0.2))
          )

          Spacer()

          // Logo at right
          Image.dynamic(assetNameOrPath:"Logo")
            .resizable()
            .scaledToFit()
            .frame(width: 72, height: 16)
        }

        // Inner thought bubble in the middle (where title was)
        let thoughtText = contentState.innerThought ?? "..."
        HStack(alignment: .bottom, spacing: 0) {
          // Dog emoji/image on the left
          if let avatar = avatarImage {
            Image(uiImage: avatar)
              .resizable()
              .scaledToFill()
              .frame(width: 36, height: 36)
              .clipShape(Circle())
              .padding(.bottom, 0)
          } else {
            Text(petEmoji)
              .font(.system(size: 36, weight: .semibold))
              .padding(.bottom, -7)
          }
          
          // Inner thought text bubble
          Text(thoughtText)
            .font(.body)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.leading, 16)
            .padding(.vertical, 10)
            .background(
              Image.dynamic(assetNameOrPath: "ThoughtBg")
                .resizable(capInsets: EdgeInsets(
                  top: 25,
                  leading: 60,
                  bottom: 25,
                  trailing: 25
                ))
            )
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing))
      .background(
        LinearGradient(
          colors: [
            Color(hex: "252525"),
            Color(hex: "252525")
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()
      )
      .onAppear {
        AppGroupsHelper.debugPrintAllFiles()

        // 尝试加载 App Groups 中的头像
        if let avatarPath = AppGroupsHelper.getImagePath("avatar.png") {
          avatarImage = UIImage(contentsOfFile: avatarPath)
          if avatarImage != nil {
            print("✅ Avatar loaded from App Groups: \(avatarPath)")
          } else {
            print("⚠️ Avatar file exists but failed to load: \(avatarPath)")
          }
        } else {
          print("ℹ️ No avatar.png found in App Groups")
        }
      }
    }
  }
#endif
