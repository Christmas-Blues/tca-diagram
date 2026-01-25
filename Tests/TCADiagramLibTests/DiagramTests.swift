import XCTest

@testable import TCADiagramLib

final class DiagramTests: XCTestCase {

  // MARK: - TCA 1.x Tests

  func testReducerClassWithEnumAndBody() throws {
    let result = try Diagram.dump(reducerClassSampleSource)
    let expected = """
    ```mermaid
    %%{ init : { "theme" : "default", "flowchart" : { "curve" : "monotoneY" }}}%%
    graph LR
        RootFeature ---> NavigationFeature
        RootFeature ---> TabSelection
        TabSelection ---> HomeFeature
        TabSelection ---> ProfileFeature
        TabSelection ---> SearchFeature

        HomeFeature(HomeFeature: 1)
        NavigationFeature(NavigationFeature: 1)
        ProfileFeature(ProfileFeature: 1)
        SearchFeature(SearchFeature: 1)
        TabSelection(TabSelection: 1)
    ```
    """
    XCTAssertEqual(result, expected)
  }

  func testNestedReducerEnumWithImplicitReducer() throws {
    let result = try Diagram.dump(nestedReducerEnumSampleSource)
    let expected = """
    ```mermaid
    %%{ init : { "theme" : "default", "flowchart" : { "curve" : "monotoneY" }}}%%
    graph LR
        ContainerFeature ---> Destination
        Destination ---> DetailFeature
        Destination ---> SettingsFeature

        Destination(Destination: 1)
        DetailFeature(DetailFeature: 1)
        SettingsFeature(SettingsFeature: 1)
    ```
    """
    XCTAssertEqual(result, expected)
  }

  func testReducerWithEquatableConformance() throws {
    let result = try Diagram.dump(reducerWithEquatableConformanceSampleSource)
    let expected = """
    ```mermaid
    %%{ init : { "theme" : "default", "flowchart" : { "curve" : "monotoneY" }}}%%
    graph LR
        FormFeature -- optional --> ConfirmationFeature

        ConfirmationFeature(ConfirmationFeature: 1)
    ```
    """
    XCTAssertEqual(result, expected)
  }

  func testReducerEnumWithBodyPattern() throws {
    let result = try Diagram.dump(reducerEnumSampleSource)
    let expected = """
    ```mermaid
    %%{ init : { "theme" : "default", "flowchart" : { "curve" : "monotoneY" }}}%%
    graph LR
        ListFeature -- optional --> Sheet
        Sheet ---> EditFeature
        Sheet ---> PreviewFeature

        EditFeature(EditFeature: 1)
        PreviewFeature(PreviewFeature: 1)
        Sheet(Sheet: 1)
    ```
    """
    XCTAssertEqual(result, expected)
  }

  // MARK: - TCA 0.x Tests (pullback-based)

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

  func testReducerMacroExample() throws {
    let result = try Diagram.dump(reducerMacroSampleSource)
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

  func testreducerWithExtensionSampleSource() throws {
    let result = try Diagram.dump(reducerWithExtensionSampleSource)
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
