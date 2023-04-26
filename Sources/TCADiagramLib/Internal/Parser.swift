import SwiftSyntax

extension SourceFileSyntax {
  func travel(
    node: Syntax,
    actions: inout Set<String>,
    relations: inout [Relation]
  ) throws {

    if let reducerProtocolParent = try predicateReducerProtocol(node) {
      try travel(parent: reducerProtocolParent, node: node, actions: &actions, relations: &relations)
    }

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

  /// ReducerProtocol이 선언된 파일에서 child를 가져옵니다.
  ///
  /// pullback과는 다르게 ReducerProtocol의 Scope나 ifLet에서는 부모피쳐 이름을 찾을수가 없습니다.
  /// Reducer 선언부에서 찾은 부모 이름을 유지하면서 자식 피쳐들을 찾아나갑니다.
  func travel(
    parent: String,
    node: Syntax,
    actions: inout Set<String>,
    relations: inout [Relation]
  ) throws {
    if let (childs, isOptional) = try predicateChildReducerProtocol(node) {
      childs.forEach { child in
        relations.append(
          .init(
            parent: parent,
            child: child.firstUppercased,
            optional: isOptional
          )
        )
      }
    } else {
      for child in node.children(viewMode: .all) {
        try travel(
          parent: parent,
          node: child,
          actions: &actions,
          relations: &relations
        )
      }
    }
  }
}

extension SourceFileSyntax {

  /// ReducerProtocol을 상속한 부분을 찾아 부모 피쳐 이름을 가져옵니다.
  private func predicateReducerProtocol(_ node: Syntax) throws -> String? {
    if
      let node = StructDeclSyntax(node),
      node.inheritanceClause?.tokens(viewMode: .fixedUp).contains(where: { $0.tokenKind == .identifier("ReducerProtocol") }) == true
    {
      return node.identifier.text
    }
    return nil
  }

  /// Scope 또는 ifLet 호출을 찾아 자식 피쳐 이름을 가져옵니다.
  private func predicateChildReducerProtocol(_ node: Syntax) throws -> ([String], Bool)? {
    if
      let node = FunctionCallExprSyntax(node),
      node.argumentList.contains(where: { syntax in syntax.label?.text == "action" })
    {
      if
        node.tokens(viewMode: .fixedUp).contains(where: { $0.tokenKind == .identifier("Scope") }),
        let child = node.trailingClosure?.statements.first?.description
          .firstMatch(of: try Regex("\\s*(.+?)\\(\\)"))?[1]
          .substring?
          .description {
        return ([child], false)
      }

      // ifLet은 method chaining으로 연달아서 붙어있기 때문에
      // 매칭되는 모든 리듀서 이름들을 가져와 child 에 저장합니다.
      if
        node.tokens(viewMode: .fixedUp).contains(where: { $0.tokenKind == .identifier("ifLet") }) {
        let childs = node.description
          .matches(of: try Regex("ifLet.+{\\s+(.+?)\\(\\)"))
          .compactMap {
            $0[1].substring?.description
          }
          .filter {
            $0 != "EmptyReducer"
          }
        return (childs, true)
      }
    }
    return .none
  }

  /// pullback 함수 호출이 있는 부분을 찾아 부모, 자식 피쳐 이름을 가져옵니다.
  ///
  /// 1. pullback 호출 부분을 찾습니다(코드 상으로는 마지막 컨디션입니다. 파라미터를 먼저 보는게 속도 측면에서 유리할 것 같아서).
  /// 1. 해당 코드 블럭의 첫부분은 Reducer일 것이고(reducler.pullback을 한 것이니), 그 리듀서 이름을 child로 저장합니다.
  /// 1. 그리고 pullback의 action 파라미터를 보면 부모의 액션이 포함되어 있으므로, 그 액션의 이름을 parent로 저장합니다.
  private func predicatePullbackCall(_ node: Syntax) throws -> (FunctionCallExprSyntax, String, String)? {
    if
      let node = FunctionCallExprSyntax(node),
      let action = node.argumentList.first(where: { syntax in syntax.label?.text == "action" })?.expression
    {
      let child = node.description.firstMatch(of: try Regex("\\s+(.+?)Reducer"))?[1].substring?.description
      let parent = "\(action)".firstMatch(of: try Regex("\\/(.+?)Action.+"))?[1].substring?.description
      switch (child, parent) {
      case (.some("Any"), .some(let parent)):
        if
          let child = node.description
            .firstMatch(of: try Regex("(?s)\\s+AnyReducer.*\\{.+?\\s+(\\w+?)\\("))?[1]
            .substring?
            .description,
          node.tokens(viewMode: .fixedUp).map(\.text).contains("pullback")
        {
          return (node, parent, child)
        }
        return .none

      case (.some(let child), .some(let parent)):
        if node.tokens(viewMode: .fixedUp).map(\.text).contains("pullback") {
          return (node, parent, child)
        }
        return .none

      default:
        return .none
      }
    }
    return .none
  }

  /// `enum`으로 정의된 액션을 찾아 피쳐 이름을 가져옵니다.
  private func predicateActionDecl(_ node: Syntax) throws -> String? {
    if let node = EnumDeclSyntax(node) {
      if node.identifier.text == "Action" {
        var parent = node.parent
        while parent != nil {
          if
            let ext = ExtensionDeclSyntax(parent),
            let name = ext.children(viewMode: .fixedUp)
              .compactMap(SimpleTypeIdentifierSyntax.init)
              .first?
              .name
              .text
          {
            return name
          } else {
            parent = parent?.parent
          }
        }
        return .none
      } else if node.identifier.text.hasSuffix("Action") {
        return node.identifier.text.replacing("Action", with: "")
      } else {
        return .none
      }
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
