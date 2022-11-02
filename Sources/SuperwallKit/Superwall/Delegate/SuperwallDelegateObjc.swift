//
//  File.swift
//  
//
//  Created by Yusuf Tör on 14/10/2022.
//

import Foundation
import StoreKit

/// The objective-c only delegate protocol that handles Superwall lifecycle events.
///
/// The delegate methods receive callbacks from the SDK in response to certain events that happen on the paywall.
/// It contains some required and some optional methods. To learn how to conform to the delegate in your app and
/// best practices, see <doc:GettingStarted>.
@MainActor
@objc(SuperwallDelegate)
public protocol SuperwallDelegateObjc: AnyObject {
  /// Called when the user initiates purchasing of a product.
  ///
  /// Add your purchase logic here and call the completion block with the result. You can use Apple's StoreKit APIs,
  /// or if you use RevenueCat, you can call [`Purchases.shared.purchase(product:)`](https://revenuecat.github.io/purchases-ios-docs/4.13.4/documentation/revenuecat/purchases/purchase(product:completion:)).
  /// - Parameters:
  ///   - product: The `SKProduct` the user would like to purchase.
  ///   - completion: A completion block the accepts a ``PurchaseResult`` object and an optional `Error`.
  ///   Call this with the result of your purchase logic. When you pass a `.failed` result, make sure you also pass
  ///   the error.
  ///    **Note:** Make sure you handle all cases of ``PurchaseResult``.
  @objc func purchase(
    product: SKProduct,
    completion: @escaping (PurchaseResultObjc, Error?) -> Void
  )

  /// Called when the user initiates a restore.
  ///
  /// Add your restore logic here.
  ///
  /// - Parameters:
  ///   - completion: Call the completion with `true` if the user's purchases were restored or `false` if they weren't.
  @objc func restorePurchases(completion: @escaping (Bool) -> Void)

  /// Decides whether a paywall should be presented based on the user's subscription status.
  ///
  /// A paywall will never be shown if this function returns `true`.
  ///
  /// - Returns: A boolean that indicates whether or not the user has an active subscription.
  @objc func isUserSubscribed() -> Bool

  /// Called when the user taps a button on your paywall that has a `data-pw-custom` tag attached.
  ///
  /// To learn more about using this function, see <doc:CustomPaywallButtons>. To learn about the types of tags that
  /// can be attached to elements on your paywall, see [Data Tags](https://docs.superwall.com/docs/data-tags).
  ///
  ///  - Parameter name: The value of the `data-pw-custom` tag in your HTML element that the user selected.
  @objc optional func handleCustomPaywallAction(withName name: String)

  /// Called right before the paywall is dismissed.
  @objc optional func willDismissPaywall()

  /// Called right before the paywall is presented.
  @objc optional func willPresentPaywall()

  /// Called right after the paywall is dismissed.
  @objc optional func didDismissPaywall()

  /// Called right after the paywall is presented.
  @objc optional func didPresentPaywall()

  /// Called when the user opens a URL by selecting an element on your paywall that has a `data-pw-open-url` tag.
  ///
  /// - Parameter url: The URL to open
  @objc optional func willOpenURL(url: URL)

  /// Called when the user taps a deep link in your paywall.
  ///
  /// - Parameter url: The deep link URL to open
  @objc optional func willOpenDeepLink(url: URL)

  /// Called whenever an internal analytics event is tracked. See <doc:AutomaticallyTrackedEvents> for more.
  ///
  /// Use this method when you want to track internal analytics events in your own analytics.
  ///
  /// If you want the event's name as an enum, do this:
  ///
  /// ```swift
  /// let event = SuperwallEvent(
  ///   rawValue: name
  /// )
  /// ```
  ///
  /// Possible Values:
  ///  ```swift
  /// // App Lifecycle Events
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "app_install",
  ///   params: nil
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "app_open",
  ///   params: nil
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "app_close",
  ///   params: nil
  /// )
  ///
  /// // Superwall Events
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywall_open",
  ///   params: ['paywall_id': 'someid']
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywall_close",
  ///   params: ['paywall_id': 'someid']
  /// )
  ///
  /// // Transaction Events
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "transaction_start",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "transaction_fail",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "transaction_abandon",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "transaction_complete",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "transaction_restore",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
  ///
  /// // Purchase Events
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "subscription_start",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "freeTrial_start",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "nonRecurringProduct_purchase",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
  ///
  /// // Superwall API Request Events
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywallResponseLoad_start",
  ///   params: ['paywall_id': 'someid']
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywallResponseLoad_fail",
  ///   params: ['paywall_id': 'someid']
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywallResponseLoad_complete",
  ///   params: ['paywall_id': 'someid']
  /// )
  ///
  /// // Webview Request Events
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywallWebviewLoad_start",
  ///   params: ['paywall_id': 'someid']
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywallWebviewLoad_fail",
  ///   params: ['paywall_id': 'someid']
  /// )
  /// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywallWebviewLoad_complete",
  ///   params: ['paywall_id': 'someid']
  /// )
  /// ```
  @objc optional func trackAnalyticsEvent(
    withName name: String,
    params: [String: Any]
  )

  /// Receive all the log messages generated by the SDK.
  ///
  /// - Parameters:
  ///   - level: Specifies the detail of the logs returned from the SDK to the console.
  ///   Can be either `DEBUG`, `INFO`, `WARN`, or `ERROR`, as defined by ``LogLevel``.
  ///   - scope: The possible scope of logs to print to the console, as defined by ``LogScope``.
  ///   - message: The message associated with the log.
  ///   - info: A dictionary of information associated with the log.
  ///   - error: The error associated with the log.
  @objc optional func handleLog(
    level: String,
    scope: String,
    message: String?,
    info: [String: Any]?,
    error: Swift.Error?
  )
}