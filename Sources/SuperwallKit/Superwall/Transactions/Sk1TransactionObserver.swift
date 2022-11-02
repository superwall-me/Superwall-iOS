//
//  File.swift
//  
//
//  Created by Jake Mor on 11/16/21.
//

import Foundation
import StoreKit

protocol TransactionObserverDelegate: AnyObject {
  var transactionRecorder: TransactionRecorder { get }

  func trackTransactionDidSucceed(
    _ transaction: TransactionModel,
    product: SKProduct
  ) async

  func trackTransactionRestoration(
    withId id: String?,
    product: SKProduct
  ) async
}

final class Sk1TransactionObserver: NSObject {
  weak var delegate: TransactionObserverDelegate?

  init(delegate: TransactionObserverDelegate) {
    self.delegate = delegate
    super.init()
    SKPaymentQueue.default().add(self)
  }
}

// MARK: - SKPaymentTransactionObserver
extension Sk1TransactionObserver: SKPaymentTransactionObserver {
	func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
		Logger.debug(
      logLevel: .debug,
      scope: .paywallTransactions,
      message: "Restore Completed Transactions Finished",
      info: nil,
      error: nil
    )
	}

	func paymentQueue(
    _ queue: SKPaymentQueue,
    restoreCompletedTransactionsFailedWithError error: Error
  ) {
		Logger.debug(
      logLevel: .debug,
      scope: .paywallTransactions,
      message: "Restore Completed Transactions Failed With Error",
      info: nil,
      error: error
    )
	}

  func paymentQueue(
    _ queue: SKPaymentQueue,
    updatedTransactions transactions: [SKPaymentTransaction]
  ) {
		for transaction in transactions {
      Task {
        guard let transactionModel = await self.delegate?.transactionRecorder.record(transaction) else {
          return
        }

        guard let product = StoreKitManager.shared.productsById[transaction.payment.productIdentifier] else {
          return
        }

        switch transaction.transactionState {
        case .purchased:
          Task.detached(priority: .utility) {
            await self.delegate?.trackTransactionDidSucceed(
              transactionModel,
              product: product
            )
          }
        case .restored:
          Task.detached(priority: .utility) {
            await self.delegate?.trackTransactionRestoration(
              withId: transaction.transactionIdentifier,
              product: product
            )
          }
        case .deferred,
          .failed,
          .purchasing:
          break
        default:
          break
        }
      }
		}
	}
}