import XCTest

@testable import TCADiagramLib

final class DiagramTests: XCTestCase {

  func testExample() throws {
    let result = try Diagram.dump(sources)
    let expected = """
    ```mermaid
    %%{ init : { "theme" : "default", "flowchart" : { "curve" : "monotoneY" }}}%%
    graph LR
        EmailSignUp ---> SignUpAgreement
        SelfLessonDetail ---> Payment
        SelfLessonDetail -- optional --> SantaWeb
        SelfLessonDetail -- optional --> SelfLessonDetailFilter

        Payment(Payment: 1)
        SantaWeb(SantaWeb: 1)
        SelfLessonDetailFilter(SelfLessonDetailFilter: 1)
        SignUpAgreement(SignUpAgreement: 1)
    ```
    """
    XCTAssertEqual(result,  expected)
  }
}
