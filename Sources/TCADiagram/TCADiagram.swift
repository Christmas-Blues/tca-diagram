import Foundation

import ArgumentParser

import TCADiagramLib

@main
struct TCADiagram: ParsableCommand {
  static var configuration: CommandConfiguration = .init(
    commandName: "tca-diagram",
    version: "0.3.0"
  )

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

    let files = FileManager
      .default
      .enumerator(
        at: .init(fileURLWithPath: rootDirectory),
        includingPropertiesForKeys: [.nameKey],
        options: .skipsHiddenFiles
      )?
      .compactMap { $0 as? URL }
      .filter { url in url.absoluteString.hasSuffix(".swift") }
      .compactMap { url in try? String(contentsOf: url, encoding: .utf8) }

    try Diagram.dump(files ?? [])
      .write(toFile: output, atomically: true, encoding: .utf8)
  }
}
