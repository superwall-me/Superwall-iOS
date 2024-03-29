//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/10/2022.
//

import Foundation

/// Corresponds to the variables in the paywall editor.
/// Consists of a dictionary of product, user, and device data.
struct Variables: Encodable {
  let user: JSON
  let device: JSON
  let params: JSON
  var primary: JSON = [:]
  var secondary: JSON = [:]
  var tertiary: JSON = [:]

  init(
    productVariables: [ProductVariable]?,
    params: JSON?,
    userAttributes: [String: Any],
    templateDeviceDictionary: [String: Any]?
  ) {
    self.params = params ?? [:]
    self.user = JSON(userAttributes)
    self.device = JSON(templateDeviceDictionary ?? [:])
    guard let productVariables = productVariables else {
      return
    }
    for productVariable in productVariables {
      switch productVariable.type {
      case .primary:
        primary = productVariable.attributes
      case .secondary:
        secondary = productVariable.attributes
      case .tertiary:
        tertiary = productVariable.attributes
      }
    }
  }

  func templated() -> JSON {
    let template: [String: Any] = [
      "event_name": "template_variables",
      "variables": dictionary() ?? [:]
    ]
    return JSON(template)
  }
}
