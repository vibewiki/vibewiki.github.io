// Окна на экране: номер, программа, процесс | заголовок. Нужно scripts/shots/vscode.sh, чтобы снять одно окно.
import Foundation
import CoreGraphics
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
for w in list {
  let owner = w[kCGWindowOwnerName as String] as? String ?? ""
  if owner.contains("Code") || owner.contains("Electron") { print(w[kCGWindowNumber as String]!, owner, w[kCGWindowOwnerPID as String]!, "|", w[kCGWindowName as String] as? String ?? "<no name>", w[kCGWindowBounds as String]!) }
}
