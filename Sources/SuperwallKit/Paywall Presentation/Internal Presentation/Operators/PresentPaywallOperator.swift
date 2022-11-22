//
//  File.swift
//  
//
//  Created by Yusuf Tör on 26/09/2022.
//

import UIKit
import Combine

extension AnyPublisher where Output == PresentablePipelineOutput, Failure == Error {
  /// Presents the paywall view controller, stores the presentation request for future use,
  /// and sends back a `presented` state to the paywall state publisher.
  ///
  /// - Parameters:
  ///   - paywallStatePublisher: A `PassthroughSubject` that gets sent ``PaywallState`` objects.
  ///
  /// - Returns: A publisher that contains info for the next pipeline operator.
  func presentPaywall(
    _ paywallStatePublisher: PassthroughSubject<PaywallState, Never>,
    _ presentationSubject: PresentationSubject
  ) -> AnyPublisher<PresentablePipelineOutput, Error> {
    flatMap { input in
      Future { promise in
        Task {
          await MainActor.run {
            input.paywallViewController.present(
              on: input.presenter,
              eventData: input.request.presentationInfo.eventData,
              presentationStyleOverride: input.request.paywallOverrides?.presentationStyle,
              paywallStatePublisher: paywallStatePublisher,
              presentationPublisher: presentationSubject
            ) { isPresented in
              if isPresented {
                Superwall.shared.lastSuccessfulPresentationRequest = input.request
                let state: PaywallState = .presented(input.paywallViewController.paywallInfo)
                paywallStatePublisher.send(state)
              } else {
                Logger.debug(
                  logLevel: .info,
                  scope: .paywallPresentation,
                  message: "Paywall Already Presented",
                  info: input.debugInfo
                )
              }
              promise(.success(input))
            }
          }
        }
      }
    }
    .eraseToAnyPublisher()
  }
}