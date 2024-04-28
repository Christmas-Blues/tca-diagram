let sources: [String] = [
  """
  let selfLessonDetailReducer = SelfLessonDetailReducer
    .combine(
      selfLessonDetailFilterReducer
        .optional()
        .pullback(
          state: \\.filter,
          action: /SelfLessonDetailAction.filter,
          environment: \\.filter
        ),
      santaWebReducer
        .optional()
        .pullback(
          state: \\Identified.value,
          action: .self,
          environment: { $0 }
        )
        .optional()
        .pullback(
          state: \\SelfLessonDetailState.selection,
          action: /SelfLessonDetailAction.web,
          environment: \\.web
        ),
      PaymentReducer()
        .pullback(
          state: \\.payment,
          action: /SelfLessonDetailAction.payment,
          environment: \\.payment
        ),
      .init { state, action, environment in
        switch action {
        default:
          return .none
        }
      }
    )
  """,
  """
  enum SelfLessonDetailAction: Equatable {
  }
  enum PaymentAction: Equatable {
  }
  enum SantaWebAction: Equatable {
  }
  enum SelfLessonDetailFilterAction: Equatable {
  }
  """,
  """
  public let emailSignUpReducer = EmailSignUpReducer
    .combine(
      AnyReducer<SignUpAgreement.State, SignUpAgreement.Action, Void> { _ in
        SignUpAgreement()
      }
      .pullback(
        state: \\.signUpAgreement,
        action: /EmailSignUpAction.signUpAgreement,
        environment: { _ in }
      ),
      .init { state, action, environment in
        switch action {
        default:
          return .none
        }
      }
    )
  """,
  """
  enum EmailSignUpAction {
  }
  extension SignUpAgreement {
    public enum Action: Equatable {
    }
  }
  """,
]

let reducerProtocolSampleSource: [String] = [
  """
  public struct SelfLessonDetail: ReducerProtocol {
    @Dependency(\\.environmentSelfLessonDetail) private var environment

    public init() {}

    public var body: some ReducerProtocol<State, Action> {
      BindingReducer()
      Scope(state: \\State.payment, action: /Action.payment) {
        Payment()
      }

      Scope(state: \\.subState, action: .self) {
        Scope(
          state: /State.SubState.promotionWeb,
          action: /Action.promotionWeb
        ) {
          DoubleScopeChild()
        }
      }

      Reduce { state, action in
        switch action {
          case default:
            return .none
        }
      }
      .ifLet(\\.filter, action: /Action.filter) {
        SelfLessonDetailFilter()
      }
      .ifLet(\\.selection, action: /Action.web) {
        SantaWeb()
      }
      .ifLet(\\SelfLessonDetail.State.selection, action: /SelfLessonDetail.Action.webView) {
        EmptyReducer()
          .ifLet(\\Identified.value, action: .self) {
            DoubleIfLetChild()
          }
      }
    }
  }
  """,
  """
  extension SelfLessonDetail {
    public enum Action: Equatable {
    }
  }
  extension Payment {
    public enum Action: Equatable {
    }
  }
  extension SantaWeb {
    public enum Action: Equatable {
    }
  }
  extension SelfLessonDetailFilter {
    public enum Action: Equatable {
    }
  }
  """
]

let reducerSampleSource: [String] = [
  """
  public struct SelfLessonDetail: Reducer {
    @Dependency(\\.environmentSelfLessonDetail) private var environment

    public init() {}

    public var body: some Reducer<State, Action> {
      BindingReducer()
      Scope(state: \\State.payment, action: /Action.payment) {
        Payment()
      }

      Scope(state: \\.subState, action: .self) {
        Scope(
          state: /State.SubState.promotionWeb,
          action: /Action.promotionWeb
        ) {
          DoubleScopeChild()
        }
      }

      Reduce { state, action in
        switch action {
          case default:
            return .none
        }
      }
      .ifLet(\\.filter, action: /Action.filter) {
        SelfLessonDetailFilter()
      }
      .ifLet(\\.$selection, action: /Action.web) {
        SantaWeb()
      }
      .ifLet(\\SelfLessonDetail.State.selection, action: /SelfLessonDetail.Action.webView) {
        EmptyReducer()
          .ifLet(\\Identified.value, action: .self) {
            DoubleIfLetChild()
          }
      }
    }
  }
  """,
  """
  extension SelfLessonDetail {
    public enum Action: Equatable {
    }
  }
  extension Payment {
    public enum Action: Equatable {
    }
  }
  extension SantaWeb {
    public enum Action: Equatable {
    }
  }
  extension SelfLessonDetailFilter {
    public enum Action: Equatable {
    }
  }
  """
]

let reducerMacroSampleSource: [String] = [
  """
  @Reducer
  public struct SelfLessonDetail {
    @Dependency(\\.environmentSelfLessonDetail) private var environment

    public init() {}

    public var body: some Reducer<State, Action> {
      BindingReducer()
      Scope(state: \\State.payment, action: /Action.payment) {
        Payment()
      }

      Scope(state: \\.subState, action: .self) {
        Scope(
          state: /State.SubState.promotionWeb,
          action: /Action.promotionWeb
        ) {
          DoubleScopeChild()
        }
      }

      Reduce { state, action in
        switch action {
          case default:
            return .none
        }
      }
      .ifLet(\\.filter, action: \\.filter) {
        SelfLessonDetailFilter()
      }
      .ifLet(\\.selection, action: \\.web) {
        SantaWeb()
      }
      .ifLet(\\SelfLessonDetail.State.selection, action: /SelfLessonDetail.Action.webView) {
        EmptyReducer()
          .ifLet(\\Identified.value, action: .self) {
            DoubleIfLetChild()
          }
      }
    }
  }
  """,
  """
  extension SelfLessonDetail {
    public enum Action: Equatable {
    }
  }
  extension Payment {
    public enum Action: Equatable {
    }
  }
  extension SantaWeb {
    public enum Action: Equatable {
    }
  }
  extension SelfLessonDetailFilter {
    public enum Action: Equatable {
    }
  }
  """
]
