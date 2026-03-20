import Foundation
import React
import ApphudSDK

enum PaywallscreenPresenterEvent: String, CaseIterable {
  case error
  case screenShown
  case closeButtonTapped
  case transactionCompleted
  case transactionStarted
}

@objc(PaywallscreenPresenter)
class PaywallscreenPresenter : RCTEventEmitter {
  @MainActor
  @objc(displayPaywallScreen:)
  func displayPaywallScreen(options: NSDictionary) {
    guard let paywallScreenPresenterId = options["paywallScreenPresenterId"] as? String else {
      return
    }
    
    guard let placementIdentifier = options["placementIdentifier"] as? String else {
      sendEvent(.error, to: paywallScreenPresenterId, with: NSError(
        domain: "ApphudModule",
        code: 400,
        userInfo: [NSLocalizedDescriptionKey: "placementIdentifier is required"]
      ))
      
      return
    }
    
    let maxAttempts = options["maxAttempts"] as? Int ?? APPHUD_DEFAULT_RETRIES
    let forceRefresh = options["forceRefresh"] as? Bool ?? false
    
    Apphud
      .fetchPlacements(maxAttempts: maxAttempts, forceRefresh: forceRefresh) {
        [
          paywallScreenPresenterId,
          placementIdentifier,
          weak self
        ] placements,
        error in
        let placement = placements.first {
          $0.identifier == placementIdentifier
        }
        
        if let paywall = placement?.paywall {
          Apphud.fetchPaywallScreen(paywall) { result in
            switch result {
            case .success(let controller):
              guard let rootViewController = RCTPresentedViewController() else {
                return
              }
              
              controller.onTransactionStarted = { product in
                self?.sendEvent(
                  .transactionStarted,
                  to: paywallScreenPresenterId,
                  with: product?.toMap()
                )
              }
              
              controller.onTransactionCompleted = { result in
                if result.success {
                  self?.sendEvent(
                    .transactionCompleted,
                    to: paywallScreenPresenterId,
                    with: result.toMap()
                  )
                }
              }
              
              controller.onCloseButtonTapped = {
                self?.sendEvent(
                  .closeButtonTapped,
                  to: paywallScreenPresenterId,
                  with: nil
                )
              }
              
              
              DispatchQueue.main.async {
                rootViewController.present(controller, animated: true)
              }
              
              return
              
            case .error(let error):
              self?.sendEvent(.error, to: paywallScreenPresenterId, with: error)
              
              return
            }
          }
        } else {
          self?.sendEvent(.error, to: paywallScreenPresenterId, with: NSError(
            domain: "ApphudModule",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Paywall not not found"]
          ))
        }
      }
  }
  
  override func startObserving() {
    // Nop
  }
  
  override func stopObserving() {
    // Nop
  }
  
  private func sendEvent(
    _ event: PaywallscreenPresenterEvent,
    to id: String,
    with payload: Any!
  ) {
    sendEvent(
      withName: event.rawValue,
      body: ["paywallScreenPresenterId": id, "payload": payload]
    )
  }
  
  override func supportedEvents() -> [String]! {
    return PaywallscreenPresenterEvent.allCases.map { $0.rawValue }
  }
}
