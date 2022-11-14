extension StringProtocol {
  /// 제일 처음 문자를 대문자로 변경합니다.
  var firstUppercased: String {
    prefix(1).uppercased() + dropFirst()
  }

  /// 문자열 앞에 4개의 공백을 추가합니다.
  var indent: String {
    "    \(self)"
  }
}
