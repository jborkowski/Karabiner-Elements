import SwiftUI

struct KeyCapView: View {
  let key: PhysicalKey
  let remapTarget: String?
  let isSelected: Bool
  let unitSize: CGFloat
  var layerColor: Color? = nil

  var body: some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(backgroundColor)
      .overlay(
        VStack(spacing: 1) {
          Text(key.label)
            .font(.system(size: fontSize))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)

          if let target = remapTarget {
            Text(target)
              .font(.system(size: max(fontSize * 0.55, 6)))
              .foregroundStyle(remapColor)
              .lineLimit(1)
              .minimumScaleFactor(0.5)
          }
        }
        .padding(2)
      )
      .frame(
        width: key.width * unitSize - keyGap,
        height: key.height * unitSize - keyGap
      )
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
      )
  }

  private var keyGap: CGFloat { 3.0 }

  private var fontSize: CGFloat {
    let base = unitSize * 0.28
    if key.label.count > 3 { return base * 0.75 }
    return base
  }

  private var tintColor: Color { layerColor ?? .orange }

  private var remapColor: Color { tintColor }

  private var backgroundColor: Color {
    if isSelected { return Color.accentColor.opacity(0.3) }
    if remapTarget != nil { return tintColor.opacity(0.3) }
    return Color(NSColor.controlBackgroundColor)
  }

  private var borderColor: Color {
    if isSelected { return Color.accentColor }
    if remapTarget != nil { return tintColor.opacity(0.5) }
    return Color(NSColor.separatorColor)
  }
}
