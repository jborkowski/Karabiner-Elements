import Foundation
import SwiftUI

struct VisualLayer: Identifiable, Codable, Equatable {
  let id: UUID
  var name: String
  var colorIndex: Int
  var isBase: Bool
  var assignments: [String: KeyAction]

  static let palette: [Color] = [
    .blue, .green, .orange, .purple, .pink, .teal, .indigo, .mint,
  ]

  var color: Color {
    Self.palette[colorIndex % Self.palette.count]
  }

  var variableName: String {
    "ve_layer_\(id.uuidString.prefix(8).lowercased())"
  }

  static func makeBase() -> VisualLayer {
    VisualLayer(
      id: UUID(),
      name: "Base",
      colorIndex: 0,
      isBase: true,
      assignments: [:]
    )
  }

  // Codable conformance — Color is not Codable, but colorIndex is
  enum CodingKeys: String, CodingKey {
    case id, name, colorIndex, isBase, assignments
  }
}
