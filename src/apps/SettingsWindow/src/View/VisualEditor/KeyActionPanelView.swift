import SwiftUI

struct KeyActionPanelView: View {
  let selectedKey: PhysicalKey?
  @ObservedObject var document: VisualEditorDocument
  let allLayers: [VisualLayer]

  @ObservedObject private var settings = LibKrbn.Settings.shared

  var body: some View {
    GroupBox(label: Text("Key Action")) {
      if let key = selectedKey {
        let currentAction = document.actionForKey(key.keyCode)

        VStack(alignment: .leading, spacing: 12) {
          LabeledContent("Key") { Text(key.label) }
          LabeledContent("Key Code") {
            Text(key.keyCode).font(.system(.body, design: .monospaced))
          }
          if let layerName = document.activeLayer?.name {
            LabeledContent("Layer") { Text(layerName) }
          }

          Divider()

          actionPicker(key: key, currentAction: currentAction)

          if currentAction != nil {
            Button(role: .destructive, action: {
              document.removeAction(keyCode: key.keyCode)
            }) {
              Label("Remove Assignment", systemImage: "trash")
            }
            .deleteButtonStyle()
          }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        Text("Click a key to assign an action")
          .foregroundStyle(.secondary)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  @ViewBuilder
  private func actionPicker(key: PhysicalKey, currentAction: KeyAction?) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Action:").font(.headline)

      // Remap picker
      HStack {
        Text("Remap to:")
        SimpleModificationPickerView(
          categories: LibKrbn.SimpleModificationDefinitions.shared.toCategories,
          label: remapLabel(for: currentAction),
          action: { toJson in
            if let keyCode = extractToKeyCode(from: toJson) {
              document.assignAction(
                keyCode: key.keyCode,
                action: .remap(toKeyCode: keyCode, toModifiers: [])
              )
            }
          },
          showUnsafe: settings.unsafeUI
        )
      }

      // Disable button
      Button(action: {
        document.assignAction(keyCode: key.keyCode, action: .disabled)
      }) {
        HStack {
          Image(systemName: currentAction == .disabled ? "checkmark.circle.fill" : "circle")
          Text("Disable key")
        }
      }
      .buttonStyle(.plain)

      // Layer activation (only if non-base layers exist)
      let nonBaseLayers = allLayers.filter { !$0.isBase && $0.id != document.activeLayerID }
      if !nonBaseLayers.isEmpty {
        Text("Activate layer while held:").font(.subheadline)
        ForEach(nonBaseLayers) { layer in
          Button(action: {
            document.assignAction(
              keyCode: key.keyCode,
              action: .layerActivation(layerID: layer.id)
            )
          }) {
            HStack {
              let isActive: Bool = {
                if case .layerActivation(let id) = currentAction, id == layer.id {
                  return true
                }
                return false
              }()
              Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
              Circle().fill(layer.color).frame(width: 8, height: 8)
              Text(layer.name)
            }
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  // MARK: - Helpers

  private func remapLabel(for action: KeyAction?) -> String {
    guard case .remap(let toKeyCode, _) = action else {
      return "--- (Choose remap)"
    }
    return toKeyCode
  }

  private func extractToKeyCode(from json: String) -> String? {
    guard let data = json.data(using: .utf8),
      let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
      let first = array.first,
      let keyCode = first["key_code"] as? String
    else { return nil }
    return keyCode
  }
}
