import Carbon
import Foundation

func stringProperty(_ source: TISInputSource, _ key: CFString) -> String {
  guard let property = TISGetInputSourceProperty(source, key) else {
    return ""
  }

  return Unmanaged<CFString>.fromOpaque(property).takeUnretainedValue() as String
}

func inputSources(includeAllInstalled: Bool) -> [TISInputSource] {
  guard let unmanagedSources = TISCreateInputSourceList(nil, includeAllInstalled) else {
    return []
  }

  return unmanagedSources.takeRetainedValue() as! [TISInputSource]
}

func inputSource(withID targetID: String) -> TISInputSource? {
  let targetCFID = targetID as CFString
  let query = [kTISPropertyInputSourceID as String: targetCFID] as CFDictionary
  if
    let unmanagedSources = TISCreateInputSourceList(query, false),
    let sources = unmanagedSources.takeRetainedValue() as? [TISInputSource],
    let source = sources.first
  {
    return source
  }

  return inputSources(includeAllInstalled: false).first {
    stringProperty($0, kTISPropertyInputSourceID) == targetID
      || stringProperty($0, kTISPropertyInputModeID) == targetID
  }
}

func describe(_ source: TISInputSource) -> String {
  let sourceID = stringProperty(source, kTISPropertyInputSourceID)
  let modeID = stringProperty(source, kTISPropertyInputModeID)
  let localizedName = stringProperty(source, kTISPropertyLocalizedName)

  return "\(sourceID)\t\(modeID)\t\(localizedName)"
}

if CommandLine.arguments.count == 2, CommandLine.arguments[1] == "--list" {
  for source in inputSources(includeAllInstalled: true) {
    print(describe(source))
  }
  exit(0)
}

if CommandLine.arguments.count == 2, CommandLine.arguments[1] == "--current" {
  guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
    fputs("current input source not found\n", stderr)
    exit(66)
  }

  print(describe(source))
  exit(0)
}

guard CommandLine.arguments.count == 2 else {
  fputs("usage: select-input-source <input-source-id>\n", stderr)
  exit(64)
}

let targetID = CommandLine.arguments[1]
guard let source = inputSource(withID: targetID) else {
  fputs("input source not found: \(targetID)\n", stderr)
  exit(66)
}

let status = TISSelectInputSource(source)
if status != noErr {
  fputs("failed to select input source: \(status)\n", stderr)
  exit(1)
}
