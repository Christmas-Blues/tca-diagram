import Foundation

import ArgumentParser

import TCADiagramLib

@main
struct TCADiagram: ParsableCommand {
  @Option(name: .shortAndLong, help: "Root directory of swift files")
  var rootDirectory: String = "."

  @Argument(help: "Markdown file")
  var output: String

  mutating func run() throws {
    try FileManager
      .default
      .createDirectory(
        at: URL(filePath: output).deletingLastPathComponent(),
        withIntermediateDirectories: true
      )

    let files = try FileManager
      .default
      .enumerator(atPath: rootDirectory)?
      .compactMap { $0 as? String }
      .filter { element in element.hasSuffix(".swift") }
      .map { URL(fileURLWithPath: [rootDirectory, $0].joined(separator: "/")) }
      .map { url in try String(contentsOf: url, encoding: .utf8) }

    try Diagram.dump(files ?? [])
      .write(toFile: output, atomically: true, encoding: .utf8)
  }
}
