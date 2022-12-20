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
