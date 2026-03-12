import SwiftUI

struct VisualEditorView: View {
  @ObservedObject private var settings = LibKrbn.Settings.shared
  @ObservedObject private var document = VisualEditorDocument.shared
  @State private var selectedKey: PhysicalKey?
  @State private var mode: EditorMode = .simpleRemaps

  enum EditorMode: String, CaseIterable {
    case simpleRemaps = "Simple Remaps"
    case layers = "Layers"
  }

  private let unitSize: CGFloat = 48.0
  private let geometry = KeyboardGeometry.ansiMacBook

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Mode picker + Apply button
      HStack {
        Picker("Mode", selection: $mode) {
          ForEach(EditorMode.allCases, id: \.self) { Text($0.rawValue) }
        }
        .pickerStyle(.segmented)
        .frame(width: 250)

        Spacer()

        if mode == .layers && document.hasUnsavedChanges {
          Button(action: { compileAndApply() }) {
            Label("Apply to Config", systemImage: "checkmark.circle.fill")
          }
          .buttonStyle(.borderedProminent)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)

      if mode == .layers {
        LayerBarView(document: document)
      }

      Divider()

      // Keyboard canvas
      ScrollView([.horizontal, .vertical]) {
        VStack(spacing: 0) {
          HStack(spacing: 0) {
            KeyboardCanvasView(
              geometry: geometry,
              remaps: currentDisplayLabels,
              selectedKeyCode: selectedKey?.keyCode,
              onKeyTap: { key in selectedKey = key },
              unitSize: unitSize,
              layerColor: mode == .layers ? document.activeLayer?.color : nil
            )
            .padding(12)
            Spacer(minLength: 0)
          }
          Spacer(minLength: 0)
        }
      }

      Divider()

      // Detail panel
      switch mode {
      case .simpleRemaps:
        KeyDetailPanelView(
          selectedKey: selectedKey,
          currentRemap: selectedKey.flatMap { findRemap(for: $0.keyCode) },
          onAssignRemap: { toJson in assignRemap(toJson: toJson) },
          onRemoveRemap: { removeRemap() }
        )
        .padding()

      case .layers:
        KeyActionPanelView(
          selectedKey: selectedKey,
          document: document,
          allLayers: document.layers
        )
        .padding()
      }
    }
    .background(Color(NSColor.textBackgroundColor))
    .onAppear { loadExistingRules() }
  }

  // MARK: - Simple Remap Lookup (existing Tier 2)

  private var currentDisplayLabels: [String: String] {
    switch mode {
    case .simpleRemaps:
      return currentRemapLabels
    case .layers:
      return layerDisplayLabels
    }
  }

  private var currentRemapLabels: [String: String] {
    var remaps: [String: String] = [:]
    for mod in settings.simpleModifications {
      if let fromKeyCode = extractKeyCode(from: mod.fromEntry.json) {
        remaps[fromKeyCode] = mod.toEntry.label
      }
    }
    return remaps
  }

  private var layerDisplayLabels: [String: String] {
    guard let layer = document.activeLayer else { return [:] }
    var labels: [String: String] = [:]
    for (keyCode, action) in layer.assignments {
      labels[keyCode] = action.displayLabel
    }
    return labels
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

  // MARK: - Layer Mode

  private func loadExistingRules() {
    if let result = ManipulatorDecompiler.decompile(rules: settings.complexModificationsRules) {
      document.layers = result.layers
      document.ownedRuleIndices = result.ruleIndices
      document.activeLayerID = result.layers.first?.id
      document.hasUnsavedChanges = false
      if result.layers.count > 1 {
        mode = .layers
      }
    }
  }

  private func compileAndApply() {
    let ruleJsonStrings = ManipulatorCompiler.compile(layers: document.layers)

    // Remove existing visual editor rules (reverse order to preserve indices)
    let existingRules = settings.complexModificationsRules.filter {
      $0.description.hasPrefix(ManipulatorDecompiler.descriptionPrefix)
    }
    for rule in existingRules.reversed() {
      settings.removeComplexModificationsRule(rule)
    }

    // Push new rules (reverse order so first rule ends up at front)
    for ruleJson in ruleJsonStrings.reversed() {
      let error = settings.pushFrontComplexModificationsRule(
        ruleJson, libkrbn_complex_modifications_rule_code_type_json)
      if let error = error {
        print("Visual Editor compile error: \(error)")
      }
    }

    document.ownedRuleIndices = Array(0..<ruleJsonStrings.count)
    document.hasUnsavedChanges = false
  }
}
