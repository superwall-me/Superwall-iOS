//
//  File.swift
//  
//
//  Created by Yusuf Tör on 28/04/2022.
//

import Foundation
import StoreKit

extension TriggerSession.Transaction.Product {
  struct Period: Codable, Equatable {
    /// Matches SKProduct.PeriodUnit
    let unit: SubscriptionPeriod.Unit

    /// Matches SKProductSubscriptionPeriod.numberOfUnits
    let count: Int

    /// Normalized & rounded to period days.
    let days: Int
  }
}
