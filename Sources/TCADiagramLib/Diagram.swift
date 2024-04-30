import Foundation

import SwiftSyntax
import SwiftParser

public enum Diagram {
  public static func dump(_ sources: [String]) throws -> String {
    var relations: [Relation] = []         // Parent ---> Child
    var actions: Set<String> = []          // All Action names in file
    var pullbackCount: [String: Int] = [:] // [Action name: pullback count]

    // go through all files and fill in actions and relations.
    try sources.enumerated().forEach { index, source in
      print("Parsing... (\(index + 1)/\(sources.count))")
      let root: SourceFileSyntax = Parser.parse(source: source)
      var reducer = root.description.firstMatch(of: try Regex("Reducer\n.*struct (.*) {"))?[1].substring?
        .description ?? ""
      if reducer == "" {
        reducer = root.description.firstMatch(of: try Regex("\\s+struct (.+?): Reducer"))?[1].substring?
          .description ?? ""
      }
      try root.travel(reducer: reducer, node: Syntax(root), actions: &actions, relations: &relations)
    }

    return Array
      .init(
        [
          "```mermaid",
          Self.mermaidHeader,
          Self.relationSection(relations: relations, actions: actions, pullbackCount: &pullbackCount),
          "",
          Self.idSection(pullbackCount: pullbackCount),
          "```"
        ]
      )
      .joined(separator: "\n")
  }

  private static let mermaidHeader = """
  %%{ init : { "theme" : "default", "flowchart" : { "curve" : "monotoneY" }}}%%
  graph LR
  """

  private static func relationSection(
    relations: [Relation],
    actions: Set<String>,
    pullbackCount: inout [String: Int]
  ) -> String {
    relations
      .sorted(
        // order parent first, then child.
        using: [
          KeyPathComparator(\.parent, order: .forward),
          KeyPathComparator(\.child, order: .forward),
        ]
      )
      .map { (relation: Relation) -> Relation in
        // to fix case problems like AITutor, aiTutor, AiTutor,
        // if there is defined Action, use that name.
        if let action = actions.first(where: { action in action.lowercased() == relation.child.lowercased() }) {
          pullbackCount[action] = (pullbackCount[action] ?? 0) + 1
          return Relation(
            parent: relation.parent,
            child: action,
            optional: relation.optional
          )
        }

        // 실제 정의된 Action에서 찾을 수 없으면 Reducer에서 찾은 이름을 그대로 사용합니다.
        print("warning: Unknown feature: \(relation.child)")
        pullbackCount[relation.child] = (pullbackCount[relation.child] ?? 0) + 1
        return relation
      }
      .map(\.description)
      .joined(separator: "\n")
  }

  /// 각 피쳐 뒤에 pullback count를 표시합니다.
  private static func idSection(
    pullbackCount: [String: Int]
  ) -> String {
    pullbackCount
      .sorted(by: { $0.0 < $1.0 })
      .map { (key, value) in "\(key)(\(key): \(value))".indent }
      .joined(separator: "\n")
  }
}
