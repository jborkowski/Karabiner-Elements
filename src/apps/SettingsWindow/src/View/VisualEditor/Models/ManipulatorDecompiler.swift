import Foundation

@MainActor
struct ManipulatorDecompiler {

  static let descriptionPrefix = "[Visual Editor]"

  static func decompile(
    rules: [LibKrbn.ComplexModificationsRule]
  ) -> (layers: [VisualLayer], ruleIndices: [Int])? {
    var layerActivations: [(ruleIndex: Int, layerName: String, manipulators: [[String: Any]])] = []
    var layerAssignments: [(ruleIndex: Int, layerName: String, isBase: Bool, manipulators: [[String: Any]])] = []
    var ruleIndices: [Int] = []

    for rule in rules {
      guard rule.description.hasPrefix(descriptionPrefix),
        let codeString = rule.codeString,
        let data = codeString.data(using: .utf8),
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let manipulators = json["manipulators"] as? [[String: Any]]
      else { continue }

      ruleIndices.append(rule.index)

      if rule.description.contains("Layer activation:") {
        let name = extractLayerName(from: rule.description, prefix: "Layer activation:")
        layerActivations.append((rule.index, name, manipulators))
      } else if rule.description.contains("Layer:") {
        let name = extractLayerName(from: rule.description, prefix: "Layer:")
        let isBase = name == "Base"
        layerAssignments.append((rule.index, name, isBase, manipulators))
      }
    }

    guard !ruleIndices.isEmpty else { return nil }

    // Build layers from assignment rules
    var layers: [VisualLayer] = []
    var variableToLayerID: [String: UUID] = [:]

    for (index, assignment) in layerAssignments.enumerated() {
      let layer = VisualLayer(
        id: UUID(),
        name: assignment.layerName,
        colorIndex: index,
        isBase: assignment.isBase,
        assignments: [:]
      )

      if !assignment.isBase, let firstManipulator = assignment.manipulators.first,
        let conditions = firstManipulator["conditions"] as? [[String: Any]],
        let firstCondition = conditions.first,
        let varName = firstCondition["name"] as? String
      {
        variableToLayerID[varName] = layer.id
      }

      layers.append(layer)
    }

    if !layers.contains(where: { $0.isBase }) {
      layers.insert(VisualLayer.makeBase(), at: 0)
    }

    // Parse key assignments into layers
    for (assignmentIdx, assignment) in layerAssignments.enumerated() {
      let layerIdx =
        layers.contains(where: { $0.isBase }) && !layerAssignments[0].isBase
        ? assignmentIdx + 1 : assignmentIdx
      let targetIdx = min(layerIdx, layers.count - 1)

      for manipulator in assignment.manipulators {
        guard let from = manipulator["from"] as? [String: Any],
          let keyCode = from["key_code"] as? String
        else { continue }

        if let action = parseAction(from: manipulator) {
          layers[targetIdx].assignments[keyCode] = action
        }
      }
    }

    // Parse activation rules
    for activation in layerActivations {
      guard let targetLayerID = findLayerID(named: activation.layerName, in: layers)
      else { continue }

      for manipulator in activation.manipulators {
        guard let from = manipulator["from"] as? [String: Any],
          let keyCode = from["key_code"] as? String
        else { continue }

        let sourceLayerIdx = findSourceLayerIndex(
          manipulator: manipulator, layers: layers, variableToLayerID: variableToLayerID)

        layers[sourceLayerIdx].assignments[keyCode] = .layerActivation(layerID: targetLayerID)
      }
    }

    return (layers, ruleIndices)
  }

  // MARK: - Helpers

  private static func extractLayerName(from description: String, prefix: String) -> String {
    guard let range = description.range(of: prefix) else { return "Unknown" }
    return description[range.upperBound...].trimmingCharacters(in: .whitespaces)
  }

  private static func parseAction(from manipulator: [String: Any]) -> KeyAction? {
    guard let toArray = manipulator["to"] as? [[String: Any]],
      let firstTo = toArray.first
    else { return nil }

    if let keyCode = firstTo["key_code"] as? String {
      if keyCode == "vk_none" { return .disabled }
      let modifiers = firstTo["modifiers"] as? [String] ?? []
      return .remap(toKeyCode: keyCode, toModifiers: modifiers)
    }

    return nil
  }

  private static func findLayerID(named name: String, in layers: [VisualLayer]) -> UUID? {
    layers.first { $0.name == name }?.id
  }

  private static func findSourceLayerIndex(
    manipulator: [String: Any],
    layers: [VisualLayer],
    variableToLayerID: [String: UUID]
  ) -> Int {
    if let conditions = manipulator["conditions"] as? [[String: Any]],
      let firstCondition = conditions.first,
      let varName = firstCondition["name"] as? String,
      let layerID = variableToLayerID[varName],
      let idx = layers.firstIndex(where: { $0.id == layerID })
    {
      return idx
    }
    return layers.firstIndex(where: { $0.isBase }) ?? 0
  }
}
