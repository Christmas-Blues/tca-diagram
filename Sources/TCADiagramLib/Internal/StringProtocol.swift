extension StringProtocol {
  /// uppercase first letter
  var firstUppercased: String {
    prefix(1).uppercased() + dropFirst()
  }

  /// add 4 space indent as prefix
  var indent: String {
    "    \(self)"
  }
}
