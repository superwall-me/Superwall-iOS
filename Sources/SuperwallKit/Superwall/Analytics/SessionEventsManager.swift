//
//  File.swift
//  
//
//  Created by Yusuf Tör on 27/05/2022.
//

import UIKit
import Combine

protocol SessionEventsDelegate: AnyObject {
  var triggerSession: TriggerSessionManager { get }

  func enqueue(_ triggerSession: TriggerSession) async
  func enqueue(_ triggerSessions: [TriggerSession]) async
  func enqueue(_ transaction: TransactionModel) async
}

final class SessionEventsManager {
  /// The shared instance of the class
  static let shared = SessionEventsManager()

  /// The trigger session manager.
  lazy var triggerSession = TriggerSessionManager(delegate: self)

  /// A queue of trigger session events that get sent to the server.
  private let queue: SessionEnqueuable

  /// Network class. Can be injected via init for testing.
  private let network: Network

  /// Storage class. Can be injected via init for testing.
  private let storage: Storage

  /// Storage class. Can be injected via init for testing.
  private let configManager: ConfigManager

  private var cancellables: [AnyCancellable] = []


  /// Only instantiate this if you're testing. Otherwise use `SessionEvents.shared`.
  init(
    queue: SessionEnqueuable = SessionEventsQueue(),
    storage: Storage = .shared,
    network: Network = .shared,
    configManager: ConfigManager = .shared
  ) {
    self.queue = queue
    self.storage = storage
    self.network = network
    self.configManager = configManager

    Task {
      await postCachedSessionEvents()
    }
  }

  /// Gets the last 20 cached trigger sessions and transactions from the last time the app was terminated,
  /// sends them back to the server, then clears cache.
  private func postCachedSessionEvents() async {
    guard configManager.config?.featureFlags.enableSessionEvents == true else {
      return
    }
    let cachedTriggerSessions = storage.get(TriggerSessions.self) ?? []
    let cachedTransactions = storage.get(Transactions.self) ?? []

    if cachedTriggerSessions.isEmpty,
      cachedTransactions.isEmpty {
      return
    }

    let sessionEvents = SessionEventsRequest(
      triggerSessions: cachedTriggerSessions,
      transactions: cachedTransactions
    )

    await network.sendSessionEvents(sessionEvents)

    storage.clearCachedSessionEvents()
  }

  /// This only updates the app session in the trigger sessions.
  /// For transactions, the latest app session id is grabbed when the next transaction occurs.
  func updateAppSession(
    _ appSession: AppSession = AppSessionManager.shared.appSession
  ) async {
    await triggerSession.updateAppSession(to: appSession)
  }
}

// MARK: - SessionEventsDelegate
extension SessionEventsManager: SessionEventsDelegate {
  func enqueue(_ triggerSession: TriggerSession) async {
    guard configManager.config?.featureFlags.enableSessionEvents == true else {
      return
    }
    await queue.enqueue(triggerSession)
  }

  func enqueue(_ triggerSessions: [TriggerSession]) async {
    guard configManager.config?.featureFlags.enableSessionEvents == true else {
      return
    }
    await queue.enqueue(triggerSessions)
  }

  func enqueue(_ transaction: TransactionModel) async {
    guard configManager.config?.featureFlags.enableSessionEvents == true else {
      return
    }
    await queue.enqueue(transaction)
  }
}