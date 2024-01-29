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
    XCTAssertEqual(result, expected)
  }

  func testReducerProtocolExample() throws {
    let result = try Diagram.dump(reducerProtocolSampleSource)
    let expected = """
    ```mermaid
    %%{ init : { "theme" : "default", "flowchart" : { "curve" : "monotoneY" }}}%%
    graph LR
        SelfLessonDetail -- optional --> DoubleIfLetChild
        SelfLessonDetail ---> DoubleScopeChild
        SelfLessonDetail ---> Payment
        SelfLessonDetail -- optional --> SantaWeb
        SelfLessonDetail -- optional --> SelfLessonDetailFilter

        DoubleIfLetChild(DoubleIfLetChild: 1)
        DoubleScopeChild(DoubleScopeChild: 1)
        Payment(Payment: 1)
        SantaWeb(SantaWeb: 1)
        SelfLessonDetailFilter(SelfLessonDetailFilter: 1)
    ```
    """
    XCTAssertEqual(result, expected)
  }

  func testReducerExample() throws {
    let result = try Diagram.dump(reducerSampleSource)
    let expected = """
    ```mermaid
    %%{ init : { "theme" : "default", "flowchart" : { "curve" : "monotoneY" }}}%%
    graph LR
        SelfLessonDetail -- optional --> DoubleIfLetChild
        SelfLessonDetail ---> DoubleScopeChild
        SelfLessonDetail ---> Payment
        SelfLessonDetail -- optional --> SantaWeb
        SelfLessonDetail -- optional --> SelfLessonDetailFilter

        DoubleIfLetChild(DoubleIfLetChild: 1)
        DoubleScopeChild(DoubleScopeChild: 1)
        Payment(Payment: 1)
        SantaWeb(SantaWeb: 1)
        SelfLessonDetailFilter(SelfLessonDetailFilter: 1)
    ```
    """
    XCTAssertEqual(result, expected)
  }
}
