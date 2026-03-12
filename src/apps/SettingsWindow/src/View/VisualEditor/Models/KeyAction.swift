import Foundation

enum KeyAction: Codable, Equatable, Hashable {
  case remap(toKeyCode: String, toModifiers: [String])
  case disabled
  case layerActivation(layerID: UUID)

  var displayLabel: String {
    switch self {
    case .remap(let toKeyCode, let toModifiers):
      if toModifiers.isEmpty { return toKeyCode }
      return toModifiers.joined(separator: "+") + "+" + toKeyCode
    case .disabled:
      return "Disabled"
    case .layerActivation:
      return "Layer"
    }
  }
}
