import SwiftUI

struct LayerBarView: View {
  @ObservedObject var document: VisualEditorDocument
  @State private var isAddingLayer = false
  @State private var newLayerName = ""
  @State private var editingLayerID: UUID?
  @State private var editingName = ""

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 4) {
        ForEach(document.layers) { layer in
          layerTab(layer)
        }

        Button(action: { isAddingLayer = true }) {
          Image(systemName: "plus.circle")
        }
        .popover(isPresented: $isAddingLayer) {
          VStack(spacing: 8) {
            TextField("Layer name", text: $newLayerName)
              .textFieldStyle(.roundedBorder)
              .frame(width: 150)
            HStack {
              Button("Cancel") { isAddingLayer = false; newLayerName = "" }
              Button("Add") {
                if !newLayerName.isEmpty {
                  document.addLayer(name: newLayerName)
                  newLayerName = ""
                  isAddingLayer = false
                }
              }
              .buttonStyle(.borderedProminent)
            }
          }
          .padding()
        }
      }
      .padding(.horizontal, 12)
    }
    .frame(height: 36)
  }

  @ViewBuilder
  private func layerTab(_ layer: VisualLayer) -> some View {
    let isActive = document.activeLayerID == layer.id

    Button(action: { document.activeLayerID = layer.id }) {
      HStack(spacing: 4) {
        Circle()
          .fill(layer.color)
          .frame(width: 8, height: 8)
        Text(layer.name)
          .font(.system(size: 12, weight: isActive ? .semibold : .regular))
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 4)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(isActive ? layer.color.opacity(0.2) : Color.clear)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(isActive ? layer.color : Color(NSColor.separatorColor), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
    .contextMenu {
      if !layer.isBase {
        Button("Rename...") {
          editingLayerID = layer.id
          editingName = layer.name
        }
        Divider()
        Button("Delete", role: .destructive) {
          document.removeLayer(id: layer.id)
        }
      }
    }
    .popover(
      isPresented: Binding(
        get: { editingLayerID == layer.id },
        set: { if !$0 { editingLayerID = nil } }
      )
    ) {
      VStack(spacing: 8) {
        TextField("Layer name", text: $editingName)
          .textFieldStyle(.roundedBorder)
          .frame(width: 150)
        HStack {
          Button("Cancel") { editingLayerID = nil }
          Button("Save") {
            document.renameLayer(id: layer.id, newName: editingName)
            editingLayerID = nil
          }
          .buttonStyle(.borderedProminent)
        }
      }
      .padding()
    }
  }
}
