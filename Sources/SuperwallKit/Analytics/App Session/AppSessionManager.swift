//
//  File.swift
//  
//
//  Created by Yusuf Tör on 04/05/2022.
//

import UIKit
import Combine

class AppSessionManager {
  var appSessionTimeout: Milliseconds?

  private(set) var appSession = AppSession() {
    didSet {
      Task {
        await sessionEventsManager.updateAppSession(appSession)
      }
    }
  }
  private var lastAppClose: Date?
  private var didTrackAppLaunch = false
  private var cancellable: AnyCancellable?

  private unowned let configManager: ConfigManager
  private unowned let storage: Storage
  private unowned var sessionEventsManager: SessionEventsManager!

  /// **Note**: Remember to call `postInit` after init.
  init(
    configManager: ConfigManager,
    storage: Storage
  ) {
    self.configManager = configManager
    self.storage = storage
    Task {
      await addActiveStateObservers()
    }
    listenForAppSessionTimeout()
  }

  /// Initialises variables that can't be immediately init'd.
  func postInit(sessionEventsManager: SessionEventsManager) {
    self.sessionEventsManager = sessionEventsManager
  }

  // MARK: - Listeners
  @MainActor
  private func addActiveStateObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillTerminate),
      name: UIApplication.willTerminateNotification,
      object: nil
    )
  }

  private func listenForAppSessionTimeout() {
    cancellable = configManager.$config
      .compactMap { $0 }
      .sink { [weak self] config in
        guard let self = self else {
          return
        }
        self.appSessionTimeout = config.appSessionTimeout

        // Account for fact that dev may have delayed the init of Superwall
        // such that applicationDidBecomeActive() doesn't activate.
        if !self.didTrackAppLaunch {
          self.sessionCouldRefresh()
        }
      }
  }

  @objc private func applicationWillResignActive() {
    Task.detached(priority: .utility) {
      await Superwall.track(InternalSuperwallEvent.AppClose())
    }
    lastAppClose = Date()
    appSession.endAt = Date()
  }

  @objc private func applicationWillTerminate() {
    appSession.endAt = Date()
  }

  @objc private func applicationDidBecomeActive() {
    Task.detached(priority: .userInitiated) {
      await Superwall.track(InternalSuperwallEvent.AppOpen())
    }
    sessionCouldRefresh()
  }

  // MARK: - Logic

  /// Tries to track a new app session, app launch, and first seen.
  private func sessionCouldRefresh() {
    detectNewSession()
    trackAppLaunch()
    storage.recordFirstSeenTracked()
  }

  private func detectNewSession() {
    let didStartNewSession = AppSessionLogic.didStartNewSession(
      lastAppClose,
      withSessionTimeout: appSessionTimeout
    )

    if didStartNewSession {
      appSession = AppSession()
      Task.detached(priority: .userInitiated) {
        await Superwall.track(InternalSuperwallEvent.SessionStart())
      }
    } else {
      appSession.endAt = nil
    }
  }

  private func trackAppLaunch() {
    if didTrackAppLaunch {
      return
    }
    Task.detached(priority: .userInitiated) {
      await Superwall.track(InternalSuperwallEvent.AppLaunch())
    }
    didTrackAppLaunch = true
  }
}