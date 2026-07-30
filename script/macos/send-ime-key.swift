import CoreGraphics
import Foundation

// Emit the physical Japanese IME keys (かな / 英数) via CGEvent so the active
// input method reliably switches its conversion mode.
//
// TISSelectInputSource on an input *mode* (base <-> Roman) of the same input
// method only updates the menu-bar indicator; it does not reliably notify the
// already-running Google Japanese IME to change its conversion mode. That leaves
// the tooltip showing Hiragana while typing still produces alphanumeric.
// The physical かな/英数 keys are handled by macOS at the HID level and switch
// the IME (and the input source) reliably, which is exactly what Kanary's
// Command-tap mappings rely on.

func keyCode(for name: String) -> CGKeyCode? {
  switch name {
  case "kana", "hiragana", "japanese":
    return 104  // かな key
  case "eisuu", "eisu", "alphanumeric", "roman":
    return 102  // 英数 key
  default:
    if let raw = UInt16(name) {
      return CGKeyCode(raw)
    }
    return nil
  }
}

guard CommandLine.arguments.count == 2, let key = keyCode(for: CommandLine.arguments[1]) else {
  fputs("usage: send-ime-key <kana|eisuu|keycode>\n", stderr)
  exit(64)
}

let source = CGEventSource(stateID: .hidSystemState)
guard
  let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true),
  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
else {
  fputs("failed to create key events\n", stderr)
  exit(1)
}

keyDown.post(tap: .cghidEventTap)
keyUp.post(tap: .cghidEventTap)
