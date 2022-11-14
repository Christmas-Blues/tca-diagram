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
  """
]
