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

      VStack(alignment: .leading, spacing: 16) {
        // Time badge at top left
        if let timeText = contentState.time ?? attributes.timePlaceholder {
          HStack(spacing: 6) {
            Circle()
              .fill(Color.green)
              .frame(width: 8, height: 8)

            Text(timeText)
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(.white)
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(
            Capsule()
              .fill(Color.white.opacity(0.2))
          )
        }

        // Inner thought bubble in the middle (where title was)
        if let thoughtText = contentState.innerThought ?? attributes.innerThoughtPlaceholder {
          HStack(alignment: .center, spacing: 12) {
            // Dog emoji/image on the left
            if let imageName = contentState.imageName {
              Image.dynamic(assetNameOrPath: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            }

            // Inner thought text bubble
            Text(thoughtText)
              .font(.body)
              .foregroundStyle(.white)
              .padding(.horizontal, 16)
              .padding(.vertical, 12)
              .background(
                Image("ThoughtBg")
                  .resizable(capInsets: EdgeInsets(
                    top: 15,
                    leading: 20,
                    bottom: 15,
                    trailing: 20
                  ))
              )
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
      .padding(EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing))
      .background(
        LinearGradient(
          colors: [
            Color(hex: "001A72"),  // 深蓝
            Color(hex: "38ACDD")   // 浅蓝
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      )
    }
  }
#endif
