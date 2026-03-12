import SwiftUI

struct KeyboardCanvasView: View {
  let geometry: KeyboardGeometry
  let remaps: [String: String]
  let selectedKeyCode: String?
  let onKeyTap: (PhysicalKey) -> Void
  let unitSize: CGFloat

  var body: some View {
    ZStack(alignment: .topLeading) {
      ForEach(geometry.rows) { row in
        ForEach(row.keys) { key in
          KeyCapView(
            key: key,
            remapTarget: remaps[key.keyCode],
            isSelected: key.keyCode == selectedKeyCode,
            unitSize: unitSize
          )
          .offset(
            x: key.x * unitSize,
            y: row.y * unitSize
          )
          .onTapGesture { onKeyTap(key) }
        }
      }
    }
    .frame(
      width: geometry.totalWidth * unitSize,
      height: geometry.totalHeight * unitSize
    )
  }
}
