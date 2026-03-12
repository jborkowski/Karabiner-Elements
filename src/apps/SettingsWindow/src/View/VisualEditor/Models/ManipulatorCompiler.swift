import Foundation

struct ManipulatorCompiler {

  static func compile(layers: [VisualLayer]) -> [String] {
    var rules: [String] = []

    for layer in layers {
      if layer.assignments.isEmpty { continue }

      if !layer.isBase {
        if let activationRule = compileActivationRule(for: layer, allLayers: layers) {
          rules.append(activationRule)
        }
      }

      if let assignmentRule = compileAssignmentRule(for: layer) {
        rules.append(assignmentRule)
      }
    }

    return rules
  }

  // MARK: - Activation Rule

  private static func compileActivationRule(
    for layer: VisualLayer, allLayers: [VisualLayer]
  ) -> String? {
    var activationKeys: [(keyCode: String, sourceLayer: VisualLayer)] = []
    for sourceLayer in allLayers {
      for (keyCode, action) in sourceLayer.assignments {
        if case .layerActivation(let targetID) = action, targetID == layer.id {
          activationKeys.append((keyCode, sourceLayer))
        }
      }
    }

    guard !activationKeys.isEmpty else { return nil }

    var manipulators: [[String: Any]] = []
    for activation in activationKeys {
      var manipulator: [String: Any] = [
        "type": "basic",
        "from": [
          "key_code": activation.keyCode,
          "modifiers": ["optional": ["any"]],
        ] as [String: Any],
        "to": [
          ["set_variable": ["name": layer.variableName, "value": 1]]
        ],
        "to_after_key_up": [
          ["set_variable": ["name": layer.variableName, "value": 0]]
        ],
      ]

      if !activation.sourceLayer.isBase {
        manipulator["conditions"] = [
          ["type": "variable_if", "name": activation.sourceLayer.variableName, "value": 1]
        ]
      }

      manipulators.append(manipulator)
    }

    let rule: [String: Any] = [
      "description": "[Visual Editor] Layer activation: \(layer.name)",
      "manipulators": manipulators,
    ]

    return jsonString(from: rule)
  }

  // MARK: - Assignment Rule

  private static func compileAssignmentRule(for layer: VisualLayer) -> String? {
    let keyAssignments = layer.assignments.filter {
      if case .layerActivation = $0.value { return false }
      return true
    }

    guard !keyAssignments.isEmpty else { return nil }

    var manipulators: [[String: Any]] = []

    for (keyCode, action) in keyAssignments.sorted(by: { $0.key < $1.key }) {
      var manipulator: [String: Any] = [
        "type": "basic",
        "from": buildFrom(keyCode: keyCode, layer: layer),
      ]

      manipulator["to"] = buildTo(action: action)

      if !layer.isBase {
        manipulator["conditions"] = [
          ["type": "variable_if", "name": layer.variableName, "value": 1]
        ]
      }

      manipulators.append(manipulator)
    }

    let description =
      layer.isBase
      ? "[Visual Editor] Layer: Base"
      : "[Visual Editor] Layer: \(layer.name)"

    let rule: [String: Any] = [
      "description": description,
      "manipulators": manipulators,
    ]

    return jsonString(from: rule)
  }

  // MARK: - From/To builders

  private static func buildFrom(keyCode: String, layer: VisualLayer) -> [String: Any] {
    var from: [String: Any] = ["key_code": keyCode]
    if layer.isBase {
      from["modifiers"] = ["optional": ["any"]]
    }
    return from
  }

  private static func buildTo(action: KeyAction) -> [[String: Any]] {
    switch action {
    case .remap(let toKeyCode, let toModifiers):
      var to: [String: Any] = ["key_code": toKeyCode]
      if !toModifiers.isEmpty {
        to["modifiers"] = toModifiers
      }
      return [to]

    case .disabled:
      return [["key_code": "vk_none"]]

    case .layerActivation:
      return []
    }
  }

  // MARK: - JSON serialization

  private static func jsonString(from dict: [String: Any]) -> String? {
    guard
      let data = try? JSONSerialization.data(
        withJSONObject: dict, options: [.sortedKeys, .prettyPrinted])
    else { return nil }
    return String(data: data, encoding: .utf8)
  }
}
