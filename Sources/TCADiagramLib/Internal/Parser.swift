import SwiftSyntax

extension SourceFileSyntax {
  func travel(
    node: Syntax,
    actions: inout Set<String>,
    relations: inout [Relation]
  ) throws {
    if let (node, parent, child) = try predicatePullbackCall(node) {
      relations.append(
        .init(
          parent: parent,
          child: child.firstUppercased,
          optional: isOptionalPullback(node)
        )
      )
    } else if let name = try predicateActionDecl(node) {
      actions.insert(name)
    } else {
      for child in node.children(viewMode: .all) {
        try travel(
          node: child,
          actions: &actions,
          relations: &relations
        )
      }
    }
  }
}

extension SourceFileSyntax {
  /// pullback 함수 호출이 있는 부분을 찾아 부모, 자식 피쳐 이름을 가져옵니다.
  ///
  /// 1. pullback 호출 부분을 찾습니다(코드 상으로는 마지막 컨디션입니다. 파라미터를 먼저 보는게 속도 측면에서 유리할 것 같아서).
  /// 1. 해당 코드 블럭의 첫부분은 Reducer일 것이고(reducler.pullback을 한 것이니), 그 리듀서 이름을 child로 저장합니다.
  /// 1. 그리고 pullback의 action 파라미터를 보면 부모의 액션이 포함되어 있으므로, 그 액션의 이름을 parent로 저장합니다.
  private func predicatePullbackCall(_ node: Syntax) throws -> (FunctionCallExprSyntax, String, String)? {
    if
      let node = FunctionCallExprSyntax(node),
      let action = node.argumentList.first(where: { syntax in syntax.label?.text == "action" })?.expression,
      let child = node.description.firstMatch(of: try Regex("\\s+(.+?)Reducer"))?[1].substring?.description,
      let parent = "\(action)".firstMatch(of: try Regex("\\/(.+?)Action.+"))?[1].substring?.description,
      node.tokens(viewMode: .fixedUp).map(\.text).contains("pullback")
    {
      return (node, parent, child)
    }
    return .none
  }

  /// `enum`으로 정의된 액션을 찾아 피쳐 이름을 가져옵니다.
  private func predicateActionDecl(_ node: Syntax) throws -> String? {
    if let node = EnumDeclSyntax(node), node.identifier.text.hasSuffix("Action") {
      return node.identifier.text.replacing("Action", with: "")
    }
    return .none
  }

  /// `pullback` 호출할 때 `optional()`을 함께 호출하는지 여부를 반환합니다.
  private func isOptionalPullback(_ node: FunctionCallExprSyntax) -> Bool {
    var stack: [Syntax] = node.children(viewMode: .fixedUp).reversed()
    while(!stack.isEmpty) {
      let node = stack.removeFirst()
      if
        let node = FunctionCallExprSyntax(node),
        node.tokens(viewMode: .fixedUp).map(\.text).contains("optional")
      {
        return true
      }
      stack.append(contentsOf: node.children(viewMode: .fixedUp))
    }
    return false
  }
}
