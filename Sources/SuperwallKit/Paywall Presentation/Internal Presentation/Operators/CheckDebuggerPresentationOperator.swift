//
//  File.swift
//  
//
//  Created by Yusuf Tör on 23/09/2022.
//

import Foundation
import Combine

extension AnyPublisher where Output == (PresentationRequest, DebugInfo), Failure == Error {
  /// Throws an error and cancels the pipeline if debugger is launched but a paywall
  /// is triggered from outside the debugger.
  func checkDebuggerPresentation(
    _ paywallStatePublisher: PassthroughSubject<PaywallState, Never>
  ) -> AnyPublisher<Output, Failure> {
    tryMap { request, debugInfo in
      if request.injections.isDebuggerLaunched {
        guard request.presentingViewController is SWDebugViewController else {
          let error = InternalPresentationLogic.presentationError(
            domain: "SWPresentationError",
            code: 101,
            title: "Debugger Is Presented",
            value: "Trying to present paywall when debugger is launched."
          )
          let state: PaywallState = .skipped(.error(error))
          paywallStatePublisher.send(state)
          paywallStatePublisher.send(completion: .finished)
          throw PresentationPipelineError.cancelled
        }
      }
      return (request, debugInfo)
    }
    .eraseToAnyPublisher()
  }
}
