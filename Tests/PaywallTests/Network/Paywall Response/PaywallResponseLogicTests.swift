//
//  PaywallResponseLogicTests.swift
//  
//
//  Created by Yusuf Tör on 17/03/2022.
//
// swiftlint:disable all

import XCTest
@testable import Paywall
import StoreKit

class PaywallResponseLogicTests: XCTestCase {
  // MARK: - Request Hash
  func testRequestHash_withIdentifierNoEvent() {
    // Given
    let id = "myid"
    let locale = "en_US"

    // When
    let hash = PaywallResponseLogic.requestHash(
      identifier: id,
      locale: locale
    )

    // Then
    XCTAssertEqual(hash, "\(id)_\(locale)")
  }

  func testRequestHash_withIdentifierWithEvent() {
    // Given
    let id = "myid"
    let locale = "en_US"
    let event: EventData = .stub()

    // When
    let hash = PaywallResponseLogic.requestHash(
      identifier: id,
      event: event,
      locale: locale
    )

    // Then
    XCTAssertEqual(hash, "\(id)_\(locale)")
  }

  func testRequestHash_noIdentifierWithEvent() {
    // Given
    let locale = "en_US"
    let eventName = "MyEvent"
    let event: EventData = .stub()
      .setting(\.name, to: eventName)

    // When
    let hash = PaywallResponseLogic.requestHash(
      event: event,
      locale: locale
    )

    // Then
    XCTAssertEqual(hash, "\(eventName)_\(locale)")
  }

  func testRequestHash_noIdentifierNoEvent() {
    // Given
    let locale = "en_US"

    // When
    let hash = PaywallResponseLogic.requestHash(
      locale: locale
    )

    // Then
    XCTAssertEqual(hash, "$called_manually_\(locale)")
  }

  // MARK: - Request Hash
  func testHandleTriggerResponse_didNotFetchConfig_noPaywallId() {
    // When
    let outcome = try? PaywallResponseLogic.handleTriggerResponse(
      withPaywallId: nil,
      fromEvent: nil,
      didFetchConfig: false
    )

    // Then
    let expectedOutcome = TriggerResponseIdentifiers(
      paywallId: nil,
      experimentId: nil,
      variantId: nil
    )

    XCTAssertEqual(outcome, expectedOutcome)
  }

  func testHandleTriggerResponse_didNotFetchConfig_hasPaywallId() {
    // Given
    let paywallId = "myid"

    // When
    let outcome = try? PaywallResponseLogic.handleTriggerResponse(
      withPaywallId: paywallId,
      fromEvent: nil,
      didFetchConfig: false
    )

    // Then
    let expectedOutcome = TriggerResponseIdentifiers(
      paywallId: paywallId,
      experimentId: nil,
      variantId: nil
    )

    XCTAssertEqual(outcome, expectedOutcome)
  }

  func testHandleTriggerResponse_didFetchConfig_noEvent_noPaywallId() {
    // When
    let outcome = try? PaywallResponseLogic.handleTriggerResponse(
      withPaywallId: nil,
      fromEvent: nil,
      didFetchConfig: true
    )

    // Then
    let expectedOutcome = TriggerResponseIdentifiers(
      paywallId: nil,
      experimentId: nil,
      variantId: nil
    )

    XCTAssertEqual(outcome, expectedOutcome)
  }

  func testHandleTriggerResponse_didFetchConfig_noEvent_hasPaywallId() {
    // Given
    let paywallId = "myid"

    // When
    let outcome = try? PaywallResponseLogic.handleTriggerResponse(
      withPaywallId: paywallId,
      fromEvent: nil,
      didFetchConfig: true
    )

    // Then
    let expectedOutcome = TriggerResponseIdentifiers(
      paywallId: paywallId,
      experimentId: nil,
      variantId: nil
    )

    XCTAssertEqual(outcome, expectedOutcome)
  }

  func testHandleTriggerResponse_v1Trigger_hasPaywallId() {
    // Given
    let paywallId = "myid"
    let getTriggerResponse: (EventData) -> HandleEventResult = { _ in
      return .presentV1
    }

    // When
    let outcome = try? PaywallResponseLogic.handleTriggerResponse(
      withPaywallId: paywallId,
      fromEvent: .stub(),
      didFetchConfig: true,
      handleEvent: getTriggerResponse
    )

    // Then
    let expectedOutcome = TriggerResponseIdentifiers(
      paywallId: paywallId,
      experimentId: nil,
      variantId: nil
    )

    XCTAssertEqual(outcome, expectedOutcome)
  }

  func testHandleTriggerResponse_v1Trigger_noPaywallId() {
    // Given
    let getTriggerResponse: (EventData) -> HandleEventResult = { _ in
      return .presentV1
    }

    // When
    let outcome = try? PaywallResponseLogic.handleTriggerResponse(
      withPaywallId: nil,
      fromEvent: .stub(),
      didFetchConfig: true,
      handleEvent: getTriggerResponse
    )

    // Then
    let expectedOutcome = TriggerResponseIdentifiers(
      paywallId: nil,
      experimentId: nil,
      variantId: nil
    )

    XCTAssertEqual(outcome, expectedOutcome)
  }

  func testHandleTriggerResponse_presentV2() {
    // Given
    let experimentId = "expId"
    let variantId = "varId"
    let paywallId = "paywallId"
    let eventName = "opened_application"
    let getTriggerResponse: (EventData) -> HandleEventResult = { _ in
      return .presentV2(
        experimentId: experimentId,
        variantId: variantId,
        paywallIdentifier: paywallId
      )
    }
    let trackEvent : (InternalEvent, [String: Any]) -> Void = { event, _ in
      guard case let .triggerFire(triggerResult: result, event: eventData) = event else {
        return XCTFail()
      }
        XCTAssertEqual(eventData.name, eventName)
        switch(result) {
        case let .paywall(experiment, paywallIdentifier):
            XCTAssertEqual(experiment.id, experimentId)
            XCTAssertEqual(experiment.variantId, variantId)
            XCTAssertEqual(paywallIdentifier, paywallId)
            break;
        default:
            XCTFail()
        }
    }

    // When
    let outcome = try? PaywallResponseLogic.handleTriggerResponse(
      withPaywallId: paywallId,
      fromEvent: .stub(),
      didFetchConfig: true,
      handleEvent: getTriggerResponse,
      trackEvent: trackEvent
    )

    // Then
    let expectedOutcome = TriggerResponseIdentifiers(
      paywallId: paywallId,
      experimentId: experimentId,
      variantId: variantId
    )

    XCTAssertEqual(outcome, expectedOutcome)
  }

  func testHandleTriggerResponse_holdout() {
    // Given
    let experimentId = "expId"
    let variantId = "varId"
    let paywallId = "paywallId"
    let eventName = "opened_application"
    let getTriggerResponse: (EventData) -> HandleEventResult = { _ in
      return .holdout(
        experimentId: experimentId,
        variantId: variantId
      )
    }
      let trackEvent : (InternalEvent, [String: Any]) -> Void = { event, _ in
        guard case let .triggerFire(triggerResult: result, event: eventData) = event else {
        return XCTFail()
      }
        XCTAssertEqual(eventData.name, eventName)
        switch(result) {
        case .holdout(let experiment):
            XCTAssertEqual(experiment.id, experimentId)
            XCTAssertEqual(experiment.variantId, variantId)
            break;
        default:
            XCTFail()
        }
    }

    // When
    do {
      _ = try PaywallResponseLogic.handleTriggerResponse(
        withPaywallId: paywallId,
        fromEvent: .stub(),
        didFetchConfig: true,
        handleEvent: getTriggerResponse,
        trackEvent: trackEvent
      )
    } catch let error as NSError {
      // Then
      let userInfo: [String: Any] = [
        "experimentId": experimentId,
        "variantId": variantId,
        NSLocalizedDescriptionKey: NSLocalizedString(
          "Trigger Holdout",
          value: "This user was assigned to a holdout in a trigger experiment",
          comment: "ExperimentId: \(experimentId), VariantId: \(variantId)"
        )
      ]
      let expectedError = NSError(
        domain: "com.superwall",
        code: 4001,
        userInfo: userInfo
      )
      XCTAssertEqual(error, expectedError)
    }
  }

  func testHandleTriggerResponse_noRuleMatch() {
    // Given
    let eventName = "opened_application"
    let getTriggerResponse: (EventData) -> HandleEventResult = { _ in
      return .noRuleMatch
    }
      let trackEvent : (InternalEvent, [String: Any]) -> Void = { event, _ in
        guard case let .triggerFire(triggerResult: result, event: eventData)  = event else {
        return XCTFail()
      }
        XCTAssertEqual(eventData.name, eventName)
        switch(result) {
        case .noRuleMatch:
            break;
        default:
            XCTFail()
        }
    }

    // When
    do {
      _ = try PaywallResponseLogic.handleTriggerResponse(
        withPaywallId: nil,
        fromEvent: .stub(),
        didFetchConfig: true,
        handleEvent: getTriggerResponse,
        trackEvent: trackEvent
      )
    } catch let error as NSError {
      // Then

      let userInfo: [String: Any] = [
        NSLocalizedDescriptionKey: NSLocalizedString(
          "No rule match",
          value: "The user did not match any rules configured for this trigger",
          comment: ""
        )
      ]
      let expectedError = NSError(
        domain: "com.superwall",
        code: 4000,
        userInfo: userInfo
      )
      XCTAssertEqual(error, expectedError)
    }
  }

  func testHandleTriggerResponse_unknownEvent() {
    // Given
    let getTriggerResponse: (EventData) -> HandleEventResult = { _ in
      return .unknownEvent
    }
    let trackEvent : (InternalEvent, [String: Any]) -> Void = { event, _ in
      XCTFail()
    }

    // When
    do {
      _ = try PaywallResponseLogic.handleTriggerResponse(
        withPaywallId: nil,
        fromEvent: .stub(),
        didFetchConfig: true,
        handleEvent: getTriggerResponse,
        trackEvent: trackEvent
      )
    } catch let error as NSError {
      // Then
      let userInfo: [String: Any] = [
        NSLocalizedDescriptionKey: NSLocalizedString(
          "Trigger Disabled",
          value: "There isn't a paywall configured to show in this context",
          comment: ""
        )
      ]
      let expectedError = NSError(
        domain: "SWTriggerDisabled",
        code: 404,
        userInfo: userInfo
      )
      XCTAssertEqual(error, expectedError)
    }
  }

  // MARK: - searchForPaywallResponse
  func testSearchForPaywallResponse_cachedResultSuccess() {
    // Given
    let hash = "hash"
    let experimentId = "experimentId"
    let variantId = "variantId"
    let paywallResponse: PaywallResponse = .stub()
      .setting(\.experimentId, to: experimentId)
      .setting(\.variantId, to: variantId)
    let results: [String: Result<PaywallResponse, NSError>] = [
      hash: .success(paywallResponse)
    ]
    let triggerExperimentId = "triggerExperimentId"
    let triggerVariantId = "triggerVariantId"
    let triggerIdentifiers = TriggerResponseIdentifiers(
      paywallId: "yo",
      experimentId: triggerExperimentId,
      variantId: triggerVariantId
    )

    // When
    let outcome = PaywallResponseLogic.searchForPaywallResponse(
      forEvent: .stub(),
      withHash: hash,
      identifiers: triggerIdentifiers,
      inResultsCache: results,
      handlersCache: [:],
      isDebuggerLaunched: false
    )

    // Then
    guard case let .cachedResult(result) = outcome else {
      return XCTFail()
    }
    switch result {
    case .success(let response):
      XCTAssertEqual(response.variantId, triggerVariantId)
      XCTAssertEqual(response.experimentId, triggerExperimentId)
    case .failure:
      XCTFail()
    }
  }

  func testSearchForPaywallResponse_cachedResultFail() {
    // Given
    let hash = "hash"
    let errorCode = 404
    let errorDomain = "Test"
    let error = NSError(
      domain: errorDomain,
      code: errorCode
    )
    let results: [String: Result<PaywallResponse, NSError>] = [
      hash: .failure(error)
    ]

    // When
    let outcome = PaywallResponseLogic.searchForPaywallResponse(
      forEvent: .stub(),
      withHash: hash,
      identifiers: nil,
      inResultsCache: results,
      handlersCache: [:],
      isDebuggerLaunched: false
    )

    // Then
    guard case let .cachedResult(result) = outcome else {
      return XCTFail()
    }
    switch result {
    case .success:
      XCTFail()
    case .failure(let error):
      XCTAssertEqual(error.code, errorCode)
      XCTAssertEqual(error.domain, errorDomain)
    }
  }

  func testSearchForPaywallResponse_enqueueCompletionBlock() {
    // Given
    let hash = "hash"

    let paywallResultCompletionBlock: PaywallResponseCompletionBlock = { result in
      switch result {
      case .success:
        XCTFail()
      case .failure:
        break
      }
    }

    let handlersCache: [String: [PaywallResponseCompletionBlock]] = [
      hash: [paywallResultCompletionBlock]
    ]

    // When
    let outcome = PaywallResponseLogic.searchForPaywallResponse(
      forEvent: .stub(),
      withHash: hash,
      identifiers: nil,
      inResultsCache: [:],
      handlersCache: handlersCache,
      isDebuggerLaunched: false
    )

    // Then
    guard case let .enqueCompletionBlock(hash: givenHash, completionBlocks: completionBlocks) = outcome else {
      return XCTFail()
    }
    XCTAssertEqual(hash, givenHash)
    guard let result = completionBlocks.first else {
      return XCTFail()
    }
    result(.failure(NSError()))
  }

  func testSearchForPaywallResponse_setCompletionBlock() {
    // Given
    let hash = "hash"

    // When
    let outcome = PaywallResponseLogic.searchForPaywallResponse(
      forEvent: .stub(),
      withHash: hash,
      identifiers: nil,
      inResultsCache: [:],
      handlersCache: [:],
      isDebuggerLaunched: false
    )

    // Then
    guard case let .setCompletionBlock(hash: givenHash) = outcome else {
      return XCTFail()
    }
    XCTAssertEqual(hash, givenHash)
  }

  // MARK: - handlePaywallError
  func testHandlePaywallError_notFoundNetworkError() {
    // Given
    let error = URLSession.NetworkError.notFound
    let trackEvent : (InternalEvent, [String: Any]) -> Void = { event, _ in
      switch event {
      case let .paywallResponseLoadNotFound(fromEvent: isFromEvent, event: event):
        XCTAssertFalse(isFromEvent)
        XCTAssertNil(event)
      default:
        XCTFail()
      }
    }

    // When
    let response = PaywallResponseLogic.handlePaywallError(
      error,
      forEvent: nil,
      withHash: "hash",
      handlersCache: [:],
      trackEvent: trackEvent
    )

    // Then
    XCTAssertNil(response)
  }

  func testHandlePaywallError_paywallResponseLoadFail() {
    // Given
    let error = URLSession.NetworkError.unknown
    let trackEvent : (InternalEvent, [String: Any]) -> Void = { event, _ in
      switch event {
      case let .paywallResponseLoadFail(fromEvent: isFromEvent, event: event):
        XCTAssertFalse(isFromEvent)
        XCTAssertNil(event)
      default:
        XCTFail()
      }
    }

    // When
    let response = PaywallResponseLogic.handlePaywallError(
      error,
      forEvent: nil,
      withHash: "hash",
      handlersCache: [:],
      trackEvent: trackEvent
    )

    // Then
    XCTAssertNil(response)
  }
  
  func testHandlePaywallError_errorResponse() {
    // Given
    let hash = "hash"
    let paywallResultCompletionBlock: PaywallResponseCompletionBlock = { result in
      switch result {
      case .success:
        XCTFail()
      case .failure:
        break
      }
    }
    let handlersCache: [String: [PaywallResponseCompletionBlock]] = [
      hash: [paywallResultCompletionBlock]
    ]

    let userInfo: [String: Any] = [
      NSLocalizedDescriptionKey: NSLocalizedString(
        "Not Found",
        value: "There isn't a paywall configured to show in this context",
        comment: ""
      )
    ]
    let error = NSError(
      domain: "SWPaywallNotFound",
      code: 404,
      userInfo: userInfo
    )

    // When
    guard let response = PaywallResponseLogic.handlePaywallError(
      error,
      forEvent: nil,
      withHash: "hash",
      handlersCache: handlersCache
    ) else {
      return XCTFail()
    }

    // Then
    let expectedResponse = PaywallErrorResponse(
      handlers: [paywallResultCompletionBlock],
      error: error
    )
    XCTAssertEqual(expectedResponse.error, response.error)

    guard let handler = response.handlers.first else {
      return XCTFail()
    }
    handler(.failure(error))
  }

  // MARK: - getVariablesAndFreeTrial
  func testGetVariablesAndFreeTrial_noProducts() {
    let response = PaywallResponseLogic.getVariablesAndFreeTrial(
      fromProducts: [],
      productsById: [:],
      isFreeTrialAvailableOverride: nil
    )

    let expectation = ProductProcessingOutcome(
      variables: [],
      productVariables: [],
      isFreeTrialAvailable: nil,
      resetFreeTrialOverride: false
    )

    XCTAssertEqual(response.isFreeTrialAvailable, expectation.isFreeTrialAvailable)
    XCTAssertTrue(response.variables.isEmpty)
    XCTAssertEqual(response.resetFreeTrialOverride, expectation.resetFreeTrialOverride)
    XCTAssertTrue(response.productVariables.isEmpty)
  }

  func testGetVariablesAndFreeTrial_productNotFound() {
    let productId = "id1"
    let products = [Product(
      type: .primary,
      id: productId
    )]

    let skProductId = "id2"
    let skProduct = SKProduct(
      identifier: skProductId,
      price: "1.99"
    )
    let productsById = [skProductId: skProduct]
    
    let response = PaywallResponseLogic.getVariablesAndFreeTrial(
      fromProducts: products,
      productsById: productsById,
      isFreeTrialAvailableOverride: nil
    )

    let expectation = ProductProcessingOutcome(
      variables: [],
      productVariables: [],
      isFreeTrialAvailable: nil,
      resetFreeTrialOverride: false
    )

    XCTAssertEqual(response.isFreeTrialAvailable, expectation.isFreeTrialAvailable)
    XCTAssertTrue(response.variables.isEmpty)
    XCTAssertEqual(response.resetFreeTrialOverride, expectation.resetFreeTrialOverride)
    XCTAssertTrue(response.productVariables.isEmpty)
  }

  func testGetVariablesAndFreeTrial_secondaryProduct() {
    // Given
    let productId = "id1"
    let productType: ProductType = .secondary
    let products = [Product(
      type: productType,
      id: productId
    )]

    let skProduct = SKProduct(
      identifier: productId,
      price: "1.99"
    )
    let productsById = [productId: skProduct]

    // When
    let response = PaywallResponseLogic.getVariablesAndFreeTrial(
      fromProducts: products,
      productsById: productsById,
      isFreeTrialAvailableOverride: nil
    )

    // Then

    let expectedVariables = [Variable(
      key: productType.rawValue,
      value: skProduct.eventData
    )]
    let expectedProductVariables = [ProductVariable(
      key: productType.rawValue,
      value: skProduct.productVariables
    )]
    XCTAssertNil(response.isFreeTrialAvailable)
    XCTAssertEqual(response.variables, expectedVariables)
    XCTAssertFalse(response.resetFreeTrialOverride)
    XCTAssertEqual(response.productVariables, expectedProductVariables)
  }

  func testGetVariablesAndFreeTrial_primaryProductHasPurchased_noOverride() {
    // Given
    let productId = "id1"
    let productType: ProductType = .primary
    let products = [Product(
      type: productType,
      id: productId
    )]
    let mockIntroPeriod = MockIntroductoryPeriod(
      testSubscriptionPeriod: MockSubscriptionPeriod()
    )
    let skProduct = SKProduct(
      identifier: productId,
      price: "1.99",
      introductoryPrice: mockIntroPeriod
    )
    let productsById = [productId: skProduct]

    
    // When
    let response = PaywallResponseLogic.getVariablesAndFreeTrial(
      fromProducts: products,
      productsById: productsById,
      isFreeTrialAvailableOverride: nil,
      hasPurchased: { _ in
        return true
      }
    )

    // Then
    let expectedVariables = [Variable(
      key: productType.rawValue,
      value: skProduct.eventData
    )]
    let expectedProductVariables = [ProductVariable(
      key: productType.rawValue,
      value: skProduct.productVariables
    )]

    guard let freeTrialAvailable = response.isFreeTrialAvailable else {
      return XCTFail()
    }
    XCTAssertFalse(freeTrialAvailable)
    XCTAssertEqual(response.variables, expectedVariables)
    XCTAssertFalse(response.resetFreeTrialOverride)
    XCTAssertEqual(response.productVariables, expectedProductVariables)
  }

  func testGetVariablesAndFreeTrial_primaryProductHasntPurchased_noOverride() {
    // Given
    let productId = "id1"
    let productType: ProductType = .primary
    let products = [Product(
      type: productType,
      id: productId
    )]
    let mockIntroPeriod = MockIntroductoryPeriod(
      testSubscriptionPeriod: MockSubscriptionPeriod()
    )
    let skProduct = SKProduct(
      identifier: productId,
      price: "1.99",
      introductoryPrice: mockIntroPeriod
    )
    let productsById = [productId: skProduct]

    // When
    let response = PaywallResponseLogic.getVariablesAndFreeTrial(
      fromProducts: products,
      productsById: productsById,
      isFreeTrialAvailableOverride: nil,
      hasPurchased: { _ in
        return false
      }
    )

    // Then
    let expectedVariables = [Variable(
      key: productType.rawValue,
      value: skProduct.eventData
    )]
    let expectedProductVariables = [ProductVariable(
      key: productType.rawValue,
      value: skProduct.productVariables
    )]

    guard let freeTrialAvailable = response.isFreeTrialAvailable else {
      return XCTFail()
    }
    XCTAssertTrue(freeTrialAvailable)
    XCTAssertEqual(response.variables, expectedVariables)
    XCTAssertFalse(response.resetFreeTrialOverride)
    XCTAssertEqual(response.productVariables, expectedProductVariables)
  }

  func testGetVariablesAndFreeTrial_primaryProductHasntPurchased_withOverride() {
    // Given
    let productId = "id1"
    let productType: ProductType = .primary
    let products = [Product(
      type: productType,
      id: productId
    )]
    let mockIntroPeriod = MockIntroductoryPeriod(
      testSubscriptionPeriod: MockSubscriptionPeriod()
    )
    let skProduct = SKProduct(
      identifier: productId,
      price: "1.99",
      introductoryPrice: mockIntroPeriod
    )
    let productsById = [productId: skProduct]

    // When
    let response = PaywallResponseLogic.getVariablesAndFreeTrial(
      fromProducts: products,
      productsById: productsById,
      isFreeTrialAvailableOverride: true,
      hasPurchased: { _ in
        return true
      }
    )

    // Then
    let expectedVariables = [Variable(
      key: productType.rawValue,
      value: skProduct.eventData
    )]
    let expectedProductVariables = [ProductVariable(
      key: productType.rawValue,
      value: skProduct.productVariables
    )]

    guard let freeTrialAvailable = response.isFreeTrialAvailable else {
      return XCTFail()
    }
    XCTAssertTrue(freeTrialAvailable)
    XCTAssertEqual(response.variables, expectedVariables)
    XCTAssertTrue(response.resetFreeTrialOverride)
    XCTAssertEqual(response.productVariables, expectedProductVariables)
  }
}
