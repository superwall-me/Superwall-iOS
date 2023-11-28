//
//  File.swift
//  
//
//  Created by Yusuf Tör on 15/09/2023.
//
// swiftlint:disable all

import XCTest
@testable import SuperwallKit

class StorageTests: XCTestCase {
  func test_saveConfirmedAssignments() {
    let dependencyContainer = DependencyContainer()
    let storage = dependencyContainer.storage
    let network = dependencyContainer.network
    let configManager = dependencyContainer.configManager

    let assignments: [Experiment.ID: Experiment.Variant] = [
      "123": .init(id: "1", type: .treatment, paywallId: "23")
    ]
    storage.saveConfirmedAssignments(assignments)

    let retrievedAssignments = storage.getConfirmedAssignments()
    XCTAssertEqual(retrievedAssignments["123"], assignments["123"])

    storage.reset()
    configManager.reset()

    let retrievedAssignments2 = storage.getConfirmedAssignments()
    XCTAssertTrue(retrievedAssignments2.isEmpty)
  }
}

