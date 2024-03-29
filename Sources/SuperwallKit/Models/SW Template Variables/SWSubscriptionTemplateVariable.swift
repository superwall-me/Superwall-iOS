//
//  SubscriptionTemplateVariable.swift
//  Superwall
//
//  Created by Yusuf Tör on 02/03/2022.
//

import Foundation
import StoreKit

struct SWSubscriptionTemplateVariable: Encodable {
  enum TemplateType: String, Encodable {
    case subscription
    case trial
    case discount
    case lifetime
  }

  var price: SWPriceTemplateVariable?
  var period: SWPeriodTemplateVariable?
  var identifier: String?
  var type: TemplateType
  var exists = true

  init(
    type: TemplateType,
    product: SK1Product
  ) {
    let swProduct = SWProduct(product: product)
    self.type = type

    switch type {
    case .subscription:
      if let subscriptionPeriod = swProduct.subscriptionPeriod {
        self.identifier = swProduct.productIdentifier
        self.period = SWPeriodTemplateVariable(
          period: subscriptionPeriod,
          locale: product.priceLocale
        )
        self.price = SWPriceTemplateVariable(
          value: swProduct.price,
          locale: product.priceLocale,
          period: subscriptionPeriod
        )
        return
      }
    case .trial:
      if let discount = swProduct.introductoryPrice {
        self.identifier = discount.identifier
        if discount.price != 0 {
          self.price = SWPriceTemplateVariable(
            value: discount.price,
            locale: product.priceLocale,
            period: discount.subscriptionPeriod
          )
        }
        self.period = SWPeriodTemplateVariable(
          period: discount.subscriptionPeriod,
          locale: product.priceLocale
        )
        return
      }
    case .discount:
      break
    case .lifetime:
      if swProduct.subscriptionPeriod == nil {
        self.exists = true
        self.price = SWPriceTemplateVariable(
          value: swProduct.price,
          locale: product.priceLocale,
          period: nil
        )
      }
    }

    self.exists = false
  }

  @available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  init(
    type: TemplateType,
    product: SK2Product
  ) {
    let swProduct = SWProduct(product: product)
    self.type = type

    switch type {
    case .subscription:
      if let subscriptionPeriod = swProduct.subscriptionPeriod {
        self.identifier = swProduct.productIdentifier
        self.period = SWPeriodTemplateVariable(
          period: subscriptionPeriod,
          locale: product.priceFormatStyle.locale
        )
        self.price = SWPriceTemplateVariable(
          value: swProduct.price,
          locale: product.priceFormatStyle.locale,
          period: subscriptionPeriod
        )
        return
      }
    case .trial:
      if let discount = swProduct.introductoryPrice {
        self.identifier = discount.identifier
        if discount.price != 0 {
          self.price = SWPriceTemplateVariable(
            value: discount.price,
            locale: product.priceFormatStyle.locale,
            period: discount.subscriptionPeriod
          )
        }
        self.period = SWPeriodTemplateVariable(
          period: discount.subscriptionPeriod,
          locale: product.priceFormatStyle.locale
        )
        return
      }
    case .discount:
      break
    case .lifetime:
      if swProduct.subscriptionPeriod == nil {
        self.exists = true
        self.price = SWPriceTemplateVariable(
          value: swProduct.price,
          locale: product.priceFormatStyle.locale,
          period: nil
        )
      }
    }

    self.exists = false
  }
}
