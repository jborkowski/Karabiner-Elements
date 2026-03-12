import Foundation
import SwiftUI

@MainActor
final class VisualEditorDocument: ObservableObject {
  static let shared = VisualEditorDocument()

  @Published var layers: [VisualLayer] = [VisualLayer.makeBase()]
  @Published var activeLayerID: UUID?
  @Published var hasUnsavedChanges: Bool = false

  var ownedRuleIndices: [Int] = []

  private init() {
    activeLayerID = layers.first?.id
  }

  var activeLayer: VisualLayer? {
    layers.first { $0.id == activeLayerID }
  }

  var activeLayerIndex: Int? {
    layers.firstIndex { $0.id == activeLayerID }
  }

  // MARK: - Layer CRUD

  func addLayer(name: String) {
    let colorIndex = layers.count % VisualLayer.palette.count
    let layer = VisualLayer(
      id: UUID(), name: name, colorIndex: colorIndex,
      isBase: false, assignments: [:])
    layers.append(layer)
    activeLayerID = layer.id
    hasUnsavedChanges = true
  }

  func removeLayer(id: UUID) {
    guard let layer = layers.first(where: { $0.id == id }), !layer.isBase else { return }
    for i in layers.indices {
      layers[i].assignments = layers[i].assignments.filter { _, action in
        if case .layerActivation(let targetID) = action, targetID == id {
          return false
        }
        return true
      }
    }
    layers.removeAll { $0.id == id }
    if activeLayerID == id {
      activeLayerID = layers.first?.id
    }
    hasUnsavedChanges = true
  }

  func renameLayer(id: UUID, newName: String) {
    guard let idx = layers.firstIndex(where: { $0.id == id }) else { return }
    layers[idx].name = newName
    hasUnsavedChanges = true
  }

  // MARK: - Key Assignment

  func assignAction(keyCode: String, action: KeyAction) {
    guard let idx = activeLayerIndex else { return }
    layers[idx].assignments[keyCode] = action
    hasUnsavedChanges = true
  }

  func removeAction(keyCode: String) {
    guard let idx = activeLayerIndex else { return }
    layers[idx].assignments.removeValue(forKey: keyCode)
    hasUnsavedChanges = true
  }

  func actionForKey(_ keyCode: String) -> KeyAction? {
    activeLayer?.assignments[keyCode]
  }

  func layerName(for id: UUID) -> String? {
    layers.first { $0.id == id }?.name
  }
}
