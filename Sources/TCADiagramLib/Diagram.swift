import Foundation

import SwiftSyntax
import SwiftParser

public enum Diagram {
  public static func dump(_ sources: [String]) throws -> String {
    var relations: [Relation] = []         // Parent ---> Child
    var actions: Set<String> = []          // 파일에 존재하는 모든 Action 이름
    var pullbackCount: [String: Int] = [:] // 액션이름: pullback count

    // 각 소스 파일을 순회하여 actions, relations를 채웁니다.
    try sources.enumerated().forEach { index, source in
      print("Parsing... (\(index + 1)/\(sources.count))")
      let root: SourceFileSyntax = Parser.parse(source: source)
      try root.travel(node: Syntax(root), actions: &actions, relations: &relations)
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
        // parent 먼저 정렬 후 child를 정렬합니다.
        using: [
          KeyPathComparator(\.parent, order: .forward),
          KeyPathComparator(\.child, order: .forward),
        ]
      )
      .map { (relation: Relation) -> Relation in
        // AITutor, aiTutor, AiTutor와 같은 문제를 해결하기 위해
        // 실제 정의된 Action 이름에서 같은 이름이 있다면 Action 이름으로 대체합니다.
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
