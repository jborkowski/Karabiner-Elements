import Foundation

struct PhysicalKey: Identifiable {
  let id: String
  let keyCode: String
  let label: String
  let x: CGFloat
  let width: CGFloat
  let height: CGFloat
  // key_code JSON key name (most keys use "key_code", fn uses "apple_vendor_top_case_key_code")
  let jsonKeyName: String

  init(
    _ keyCode: String, _ label: String,
    x: CGFloat, width: CGFloat = 1.0, height: CGFloat = 1.0,
    jsonKeyName: String = "key_code"
  ) {
    self.id = keyCode
    self.keyCode = keyCode
    self.label = label
    self.x = x
    self.width = width
    self.height = height
    self.jsonKeyName = jsonKeyName
  }
}

struct KeyRow: Identifiable {
  let id: Int
  let y: CGFloat
  let keys: [PhysicalKey]
}

struct KeyboardGeometry {
  let rows: [KeyRow]
  let totalWidth: CGFloat
  let totalHeight: CGFloat

  // ANSI MacBook layout: 6 rows, ~78 keys, 15u wide
  static let ansiMacBook: KeyboardGeometry = {
    let gap: CGFloat = 0.125 // small gap between keys

    // Row 0: Function row (height 0.75u)
    let row0 = KeyRow(id: 0, y: 0, keys: [
      PhysicalKey("escape", "Esc", x: 0, width: 1.0, height: 0.75),
      PhysicalKey("f1", "F1", x: 1.25, width: 1.0, height: 0.75),
      PhysicalKey("f2", "F2", x: 2.25, width: 1.0, height: 0.75),
      PhysicalKey("f3", "F3", x: 3.25, width: 1.0, height: 0.75),
      PhysicalKey("f4", "F4", x: 4.25, width: 1.0, height: 0.75),
      PhysicalKey("f5", "F5", x: 5.5, width: 1.0, height: 0.75),
      PhysicalKey("f6", "F6", x: 6.5, width: 1.0, height: 0.75),
      PhysicalKey("f7", "F7", x: 7.5, width: 1.0, height: 0.75),
      PhysicalKey("f8", "F8", x: 8.5, width: 1.0, height: 0.75),
      PhysicalKey("f9", "F9", x: 9.75, width: 1.0, height: 0.75),
      PhysicalKey("f10", "F10", x: 10.75, width: 1.0, height: 0.75),
      PhysicalKey("f11", "F11", x: 11.75, width: 1.0, height: 0.75),
      PhysicalKey("f12", "F12", x: 12.75, width: 1.0, height: 0.75),
    ])

    // Row 1: Number row
    let row1 = KeyRow(id: 1, y: 1.0, keys: [
      PhysicalKey("grave_accent_and_tilde", "`", x: 0),
      PhysicalKey("1", "1", x: 1),
      PhysicalKey("2", "2", x: 2),
      PhysicalKey("3", "3", x: 3),
      PhysicalKey("4", "4", x: 4),
      PhysicalKey("5", "5", x: 5),
      PhysicalKey("6", "6", x: 6),
      PhysicalKey("7", "7", x: 7),
      PhysicalKey("8", "8", x: 8),
      PhysicalKey("9", "9", x: 9),
      PhysicalKey("0", "0", x: 10),
      PhysicalKey("hyphen", "-", x: 11),
      PhysicalKey("equal_sign", "=", x: 12),
      PhysicalKey("delete_or_backspace", "Delete", x: 13, width: 1.5),
    ])

    // Row 2: QWERTY row
    let row2 = KeyRow(id: 2, y: 2.0, keys: [
      PhysicalKey("tab", "Tab", x: 0, width: 1.5),
      PhysicalKey("q", "Q", x: 1.5),
      PhysicalKey("w", "W", x: 2.5),
      PhysicalKey("e", "E", x: 3.5),
      PhysicalKey("r", "R", x: 4.5),
      PhysicalKey("t", "T", x: 5.5),
      PhysicalKey("y", "Y", x: 6.5),
      PhysicalKey("u", "U", x: 7.5),
      PhysicalKey("i", "I", x: 8.5),
      PhysicalKey("o", "O", x: 9.5),
      PhysicalKey("p", "P", x: 10.5),
      PhysicalKey("open_bracket", "[", x: 11.5),
      PhysicalKey("close_bracket", "]", x: 12.5),
      PhysicalKey("backslash", "\\", x: 13.5, width: 1.0),
    ])

    // Row 3: Home row
    let row3 = KeyRow(id: 3, y: 3.0, keys: [
      PhysicalKey("caps_lock", "Caps Lock", x: 0, width: 1.75),
      PhysicalKey("a", "A", x: 1.75),
      PhysicalKey("s", "S", x: 2.75),
      PhysicalKey("d", "D", x: 3.75),
      PhysicalKey("f", "F", x: 4.75),
      PhysicalKey("g", "G", x: 5.75),
      PhysicalKey("h", "H", x: 6.75),
      PhysicalKey("j", "J", x: 7.75),
      PhysicalKey("k", "K", x: 8.75),
      PhysicalKey("l", "L", x: 9.75),
      PhysicalKey("semicolon", ";", x: 10.75),
      PhysicalKey("quote", "'", x: 11.75),
      PhysicalKey("return_or_enter", "Return", x: 12.75, width: 1.75),
    ])

    // Row 4: Shift row
    let row4 = KeyRow(id: 4, y: 4.0, keys: [
      PhysicalKey("left_shift", "Shift", x: 0, width: 2.25),
      PhysicalKey("z", "Z", x: 2.25),
      PhysicalKey("x", "X", x: 3.25),
      PhysicalKey("c", "C", x: 4.25),
      PhysicalKey("v", "V", x: 5.25),
      PhysicalKey("b", "B", x: 6.25),
      PhysicalKey("n", "N", x: 7.25),
      PhysicalKey("m", "M", x: 8.25),
      PhysicalKey("comma", ",", x: 9.25),
      PhysicalKey("period", ".", x: 10.25),
      PhysicalKey("slash", "/", x: 11.25),
      PhysicalKey("right_shift", "Shift", x: 12.25, width: 2.25),
    ])

    // Row 5: Bottom row + arrows
    // Arrow up/down are half-height, stacked
    let row5 = KeyRow(id: 5, y: 5.0, keys: [
      PhysicalKey(
        "fn", "fn", x: 0, width: 1.0,
        jsonKeyName: "apple_vendor_top_case_key_code"),
      PhysicalKey("left_control", "Control", x: 1.0, width: 1.25),
      PhysicalKey("left_option", "Option", x: 2.25, width: 1.25),
      PhysicalKey("left_command", "Command", x: 3.5, width: 1.25),
      PhysicalKey("spacebar", "Space", x: 4.75, width: 5.25),
      PhysicalKey("right_command", "Command", x: 10.0, width: 1.25),
      PhysicalKey("right_option", "Option", x: 11.25, width: 1.25),
      PhysicalKey("left_arrow", "\u{2190}", x: 12.5),
      PhysicalKey("up_arrow", "\u{2191}", x: 13.5, width: 1.0, height: 0.5),
      PhysicalKey("right_arrow", "\u{2192}", x: 14.5),
    ])

    // Down arrow in a separate "row" at y=5.5 (half-height, below up_arrow)
    let row5b = KeyRow(id: 6, y: 5.5, keys: [
      PhysicalKey("down_arrow", "\u{2193}", x: 13.5, width: 1.0, height: 0.5),
    ])

    return KeyboardGeometry(
      rows: [row0, row1, row2, row3, row4, row5, row5b],
      totalWidth: 15.5,
      totalHeight: 6.0
    )
  }()
}
