import Foundation
import ClipCore
import Darwin

let command = CommandLine.arguments.dropFirst().first ?? "help"
let usage = "Usage: clipctl <help|list|search|copy|clear|prune|pause|resume>"

func writeError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

switch command {
case "help", "--help", "-h":
    print(usage)
    print("Operational commands are not implemented in this scaffold.")
    exit(0)
case "list", "search", "copy", "clear", "prune", "pause", "resume":
    writeError("clipctl \(command): not implemented in this scaffold")
    exit(1)
default:
    writeError("clipctl: unknown command")
    writeError(usage)
    exit(2)
}
