import SwiftSyntax

extension SourceFileSyntax {
  func travel(
    reducer: String = "",
    node: Syntax,
    actions: inout Set<String>,
    relations: inout [Relation]
  ) throws {
    if let reducerProtocolParent = try predicateReducerProtocol(node) {
      // Handle @Reducer enum with child features in cases
      if let enumChildren = try predicateEnumReducerChildren(node) {
        for child in enumChildren {
          relations.append(
            .init(
              parent: reducerProtocolParent,
              child: child.firstUppercased,
              optional: false
            )
          )
        }
      }
      // Traverse children of this reducer, not the node itself (to avoid re-detection)
      for child in node.children(viewMode: .all) {
        try travel(parent: reducerProtocolParent, node: child, actions: &actions, relations: &relations)
      }
      return
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
      if reducer.isEmpty {
        for child in node.children(viewMode: .all) {
          try travel(
            node: child,
            actions: &actions,
            relations: &relations
          )
        }
      } else {
        for child in node.children(viewMode: .all) {
          try travel(
            parent: reducer,
            node: child,
            actions: &actions,
            relations: &relations
          )
        }
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
    // Check for nested @Reducer declarations (TCA 1.x)
    if let reducerProtocolParent = try predicateReducerProtocol(node) {
      // Add relation from containing reducer to this nested reducer
      // Only if truly nested (inside a member block), not a file-level sibling
      if node.parent?.as(MemberBlockItemSyntax.self) != nil,
         parent != reducerProtocolParent {
        relations.append(
          .init(
            parent: parent,
            child: reducerProtocolParent.firstUppercased,
            optional: false
          )
        )
      }
      // Handle @Reducer enum with child features in cases (always extract, nested or not)
      if let enumChildren = try predicateEnumReducerChildren(node) {
        for child in enumChildren {
          relations.append(
            .init(
              parent: reducerProtocolParent,
              child: child.firstUppercased,
              optional: false
            )
          )
        }
      }
    }

    if let children = try predicateIfLetDecl(node) {
      children.forEach { child in
        relations.append(
          .init(
            parent: parent,
            child: child.firstUppercased,
            optional: true
          )
        )
      }
    } else if let (children, isOptional) = try predicateChildReducerProtocol(node) {
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
  /// Get parent name from feature.
  private func predicateReducerProtocol(_ node: Syntax) throws -> String? {
    if
      let node = StructDeclSyntax(node)
    {
      /// Has @Reducer macro
      if
        node.attributes.contains(where: { element in
          element.tokens(viewMode: .fixedUp).contains { el in
            el.tokenKind == .identifier("Reducer")
          }
        }) == true
      {
        return node.name.text
      }
      /// superclass of ReducerProtocol or Reducer
      if
        node.inheritanceClause?.tokens(viewMode: .fixedUp)
          .contains(where: {
            $0.tokenKind == .identifier("ReducerProtocol")
              || $0.tokenKind == .identifier("Reducer")
          }) == true
      {
        return node.name.text
      }
    }

    // @Reducer class (TCA 1.x)
    if let node = ClassDeclSyntax(node) {
      if
        node.attributes.contains(where: { element in
          element.tokens(viewMode: .fixedUp).contains { el in
            el.tokenKind == .identifier("Reducer")
          }
        }) == true
      {
        return node.name.text
      }
    }

    // @Reducer enum (TCA 1.x)
    if let node = EnumDeclSyntax(node) {
      if
        node.attributes.contains(where: { element in
          element.tokens(viewMode: .fixedUp).contains { el in
            el.tokenKind == .identifier("Reducer")
          }
        }) == true
      {
        return node.name.text
      }
    }

    return nil
  }

  /// Extract child features from @Reducer enum cases.
  private func predicateEnumReducerChildren(_ node: Syntax) throws -> [String]? {
    guard let enumNode = EnumDeclSyntax(node) else { return nil }

    guard enumNode.attributes.contains(where: { element in
      element.tokens(viewMode: .fixedUp).contains { el in
        el.tokenKind == .identifier("Reducer")
      }
    }) else { return nil }

    var children: [String] = []

    for member in enumNode.memberBlock.members {
      if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
        for element in caseDecl.elements {
          if let associatedValue = element.parameterClause {
            for param in associatedValue.parameters {
              let typeName = param.type.description.trimmingCharacters(in: .whitespaces)
              if !typeName.isEmpty {
                children.append(typeName)
              }
            }
          }
        }
      }
    }

    return children.isEmpty ? nil : children
  }

  /// Get child feature name by looking for Scope or ifLet calls.
  private func predicateChildReducerProtocol(_ node: Syntax) throws -> ([String], Bool)? {
    if
      let node = FunctionCallExprSyntax(node),
      node.arguments.contains(where: { syntax in syntax.label?.text == "action" })
    {
      if node.tokens(viewMode: .fixedUp).contains(where: { $0.tokenKind == .identifier("Scope") }) {
        let closureContent = node.trailingClosure?.statements.first?.description ?? ""

        // Match SomeFeature() pattern
        if let child = closureContent
          .firstMatch(of: try Regex("\\s*(.+?)\\(\\)"))?[1]
          .substring?
          .description
        {
          return ([child], false)
        }

        // Match SomeFeature.body pattern (TCA 1.x enum reducers)
        if let child = closureContent
          .firstMatch(of: try Regex("\\s*(.+?)\\.body"))?[1]
          .substring?
          .description
        {
          return ([child], false)
        }
      }

      // ifLet can be in "method chaining"
      if
        node.tokens(viewMode: .fixedUp).contains(where: { $0.tokenKind == .identifier("ifLet") })
      {
        var children: [String] = []

        // Match SomeFeature() pattern
        children.append(contentsOf: node.description
          .matches(of: try Regex("ifLet.+\\{\\s+(.+?)\\(\\)"))
          .compactMap { $0[1].substring?.description }
        )

        // Match SomeFeature.body pattern (TCA 1.x enum reducers)
        children.append(contentsOf: node.description
          .matches(of: try Regex("ifLet.+\\{\\s+(.+?)\\.body"))
          .compactMap { $0[1].substring?.description }
        )

        children = children.filter { $0 != "EmptyReducer" }
        return children.isEmpty ? nil : (children, true)
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
      let action = node.arguments.first(where: { syntax in syntax.label?.text == "action" })?.expression
    {
      if
        let child = node.description.firstMatch(of: try Regex("\\s+(.+?)Reducer"))?[1].substring?.description,
        let parent = "\(action)".firstMatch(of: try Regex("\\/(.+?)Action.+"))?[1].substring?.description
      {
        switch (child, parent) {
        case ("Any", let parent):
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

        case (let child, let parent):
          if node.tokens(viewMode: .fixedUp).map(\.text).contains("pullback") {
            return (node, parent, child)
          }
          return .none
        }
      }
    }
    return .none
  }

  /// parse `enum` Action for feature name.
  private func predicateActionDecl(_ node: Syntax) throws -> String? {
    if let node = EnumDeclSyntax(node) {
      if node.name.text == "Action" {
        var parent = node.parent
        while parent != nil {
          if
            let ext = ExtensionDeclSyntax(parent),
            let name = ext.children(viewMode: .fixedUp)
              .compactMap(IdentifierTypeSyntax.init)
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
      } else if node.name.text.hasSuffix("Action") {
        return node.name.text.replacing("Action", with: "")
      } else {
        return .none
      }
    }
    return .none
  }

  /// check if `pullback` chains `optional()`.
  private func isOptionalPullback(_ node: FunctionCallExprSyntax) -> Bool {
    var stack: [Syntax] = node.children(viewMode: .fixedUp).reversed()
    while !stack.isEmpty {
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

  /// parse `enum` Action for feature name.
  private func predicateIfLetDecl(_ node: Syntax) throws -> [String]? {
    if
      let node = FunctionCallExprSyntax(node),
      node.arguments.contains(where: { syntax in syntax.label?.text == "action" })
    {
      if
        node.tokens(viewMode: .fixedUp).contains(where: { $0.tokenKind == .identifier("ifLet") })
      {
        var children: [String] = []

        // Match SomeFeature() pattern
        children.append(contentsOf: node.description
          .matches(of: try Regex("ifLet.+\\{\\s+(.+?)\\(\\)"))
          .compactMap { $0[1].substring?.description }
        )

        // Match SomeFeature.body pattern (TCA 1.x enum reducers)
        children.append(contentsOf: node.description
          .matches(of: try Regex("ifLet.+\\{\\s+(.+?)\\.body"))
          .compactMap { $0[1].substring?.description }
        )

        children = children.filter { $0 != "EmptyReducer" }
        return children.isEmpty ? nil : children
      }
    }
    return .none
  }
}
