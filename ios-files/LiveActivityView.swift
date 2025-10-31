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
          
          Text("🐶")
            .font(.system(size: 36, weight: .semibold))
            .padding(.bottom, -7)

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
            Color(hex: "252525")                 // 100% 不透明
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()
      )
    }
  }
#endif
