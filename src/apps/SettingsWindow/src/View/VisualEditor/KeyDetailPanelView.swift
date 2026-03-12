import SwiftUI

struct KeyDetailPanelView: View {
  let selectedKey: PhysicalKey?
  let currentRemap: LibKrbn.SimpleModification?
  let onAssignRemap: (_ toJson: String) -> Void
  let onRemoveRemap: () -> Void

  @ObservedObject private var settings = LibKrbn.Settings.shared

  var body: some View {
    GroupBox(label: Text("Key Details")) {
      if let key = selectedKey {
        VStack(alignment: .leading, spacing: 12.0) {
          LabeledContent("Key") { Text(key.label) }
          LabeledContent("Key Code") {
            Text(key.keyCode).font(.system(.body, design: .monospaced))
          }

          Divider()

          Text("Remap To:").font(.headline)

          SimpleModificationPickerView(
            categories: LibKrbn.SimpleModificationDefinitions.shared.toCategories,
            label: currentRemap?.toEntry.label ?? "--- (No remap)",
            action: { json in onAssignRemap(json) },
            showUnsafe: settings.unsafeUI
          )

          if currentRemap != nil {
            Button(role: .destructive, action: onRemoveRemap) {
              Label("Remove Remap", systemImage: "trash")
            }
            .deleteButtonStyle()
          }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        Text("Click a key to assign a remap")
          .foregroundStyle(.secondary)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}
