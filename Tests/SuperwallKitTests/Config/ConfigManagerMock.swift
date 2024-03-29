//
//  File.swift
//  
//
//  Created by Yusuf Tör on 16/08/2022.
//
// swiftlint:disable all

import UIKit
@testable import SuperwallKit

final class ConfigManagerMock: ConfigManager {
  var confirmedAssignment = false

  override func confirmAssignment(
    _ confirmableAssignment: ConfirmableAssignment
  ) {
    confirmedAssignment = true
  }
}
