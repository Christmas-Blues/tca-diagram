struct Relation {
  let parent: String
  let child: String
  let optional: Bool
}

extension Relation: CustomStringConvertible {
  /// mermaid 문법으로 변경합니다.
  ///
  /// * Parent ---> Child
  /// * Parent -- optional --> Child
  var description: String {
    self.optional
      ? "\(parent) -- optional --> \(child)".indent
      : "\(parent) ---> \(child)".indent
  }
}
