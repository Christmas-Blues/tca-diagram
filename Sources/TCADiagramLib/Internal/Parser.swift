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

  /// Get child from file with ReducerProtocol
  ///
  /// unlike pullbacks, Scope and ifLet can't find parent's name.
  /// Iterates through the children while keeping the parent name found in Reducer.
  func travel(
    parent: String,
    node: Syntax,
    actions: inout Set<String>,
    relations: inout [Relation]
  ) throws {
    if let (children, isOptional) = try predicateChildReducerProtocol(node) {
      children.forEach { child in
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

  /// Get parent name from feature with superclass of ReducerProtocol
  private func predicateReducerProtocol(_ node: Syntax) throws -> String? {
    if
      let node = StructDeclSyntax(node),
      node.inheritanceClause?.tokens(viewMode: .fixedUp)
        .contains(where: {
          $0.tokenKind == .identifier("ReducerProtocol")
          || $0.tokenKind == .identifier("Reducer")
        }) == true
    {
      return node.identifier.text
    }
    return nil
  }

  /// Get child feature name by looking for Scope or ifLet calls.
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

      // ifLet can be in "method chaining"
      // therefore find all reducer names that match and save in child
      if
        node.tokens(viewMode: .fixedUp).contains(where: { $0.tokenKind == .identifier("ifLet") })
      {
        let children = node.description
          .matches(of: try Regex("ifLet.+{\\s+(.+?)\\(\\)"))
          .compactMap {
            $0[1].substring?.description
          }
          .filter {
            $0 != "EmptyReducer"
          }
        return (children, true)
      }
    }
    return .none
  }

  /// Find pullback calls and get parent, child feature names.
  ///
  /// 1. Find pullback calls (last condition in code. looking for parameters probably would be faster to find)
  /// 2. Code block should start with Reducer (probably reducler.pullback), save the reducer name as child.
  /// 3. pullback action parameter should hold the parent's name, so save it as parent.
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

  /// parse `enum` Action for feature name.
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

  /// check if `pullback` chains `optional()`.
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
