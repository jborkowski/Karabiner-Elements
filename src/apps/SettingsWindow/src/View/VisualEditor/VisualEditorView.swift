import SwiftUI

struct VisualEditorView: View {
  @ObservedObject private var settings = LibKrbn.Settings.shared
  @State private var selectedKey: PhysicalKey?

  private let unitSize: CGFloat = 48.0
  private let geometry = KeyboardGeometry.ansiMacBook

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ScrollView([.horizontal, .vertical]) {
        VStack(spacing: 0) {
          HStack(spacing: 0) {
            KeyboardCanvasView(
              geometry: geometry,
              remaps: currentRemapLabels,
              selectedKeyCode: selectedKey?.keyCode,
              onKeyTap: { key in selectedKey = key },
              unitSize: unitSize
            )
            .padding(12)
            Spacer(minLength: 0)
          }
          Spacer(minLength: 0)
        }
      }

      Divider()

      KeyDetailPanelView(
        selectedKey: selectedKey,
        currentRemap: selectedKey.flatMap { findRemap(for: $0.keyCode) },
        onAssignRemap: { toJson in assignRemap(toJson: toJson) },
        onRemoveRemap: { removeRemap() }
      )
      .padding()
    }
    .background(Color(NSColor.textBackgroundColor))
  }

  // MARK: - Remap Lookup

  private var currentRemapLabels: [String: String] {
    var remaps: [String: String] = [:]
    for mod in settings.simpleModifications {
      if let fromKeyCode = extractKeyCode(from: mod.fromEntry.json) {
        remaps[fromKeyCode] = mod.toEntry.label
      }
    }
    return remaps
  }

  private func findRemap(for keyCode: String) -> LibKrbn.SimpleModification? {
    settings.simpleModifications.first {
      extractKeyCode(from: $0.fromEntry.json) == keyCode
    }
  }

  private func extractKeyCode(from json: String) -> String? {
    guard let data = json.data(using: .utf8),
      let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }
    // Handle both key_code and apple_vendor_top_case_key_code
    return (dict["key_code"] as? String)
      ?? (dict["apple_vendor_top_case_key_code"] as? String)
  }

  // MARK: - Remap Editing (Tier 2)

  private func assignRemap(toJson: String) {
    guard let key = selectedKey else { return }
    let fromJson = "{\"\(key.jsonKeyName)\":\"\(key.keyCode)\"}"

    if let existing = findRemap(for: key.keyCode) {
      settings.updateSimpleModification(
        index: existing.index,
        fromJsonString: fromJson,
        toJsonString: toJson,
        device: nil
      )
    } else {
      settings.appendSimpleModification(device: nil)
      let newIndex = settings.simpleModifications.count - 1
      settings.updateSimpleModification(
        index: newIndex,
        fromJsonString: fromJson,
        toJsonString: toJson,
        device: nil
      )
    }
  }

  private func removeRemap() {
    guard let key = selectedKey,
      let existing = findRemap(for: key.keyCode)
    else { return }
    settings.removeSimpleModification(index: existing.index, device: nil)
  }
}
