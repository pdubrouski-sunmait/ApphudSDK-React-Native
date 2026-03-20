import Foundation
import ApphudSDK

fileprivate struct SerializedError : RNAdapter {
  let code: Int
  let userInfo: [AnyHashable: Any]?
  let localizedDescription: String
  let domain: String
  
  init(
    code: Int,
    userInfo: [AnyHashable : Any]?,
    localizedDescription: String,
    domain: String
  ) {
    self.code = code
    self.userInfo = userInfo
    self.localizedDescription = localizedDescription
    self.domain = domain
  }
  
  init(from error: NSError) {
    self.code = error.code
    self.userInfo = error.userInfo
    self.localizedDescription = error.localizedDescription
    self.domain = error.domain
  }
  
  func toMap() -> NSDictionary {
    var map: [AnyHashable: Any] = [:]
    map["code"] = code
    map["userInfo"] = userInfo
    map["localizedDescription"] = localizedDescription
    map["domain"] = domain
    
    return map as NSDictionary
  }
}

class PaywallScreenView : UIView {
  @objc var onStartLoading: RCTBubblingEventBlock? = nil
  @objc var onReceiveView: RCTBubblingEventBlock? = nil
  @objc var onLoadingError: RCTBubblingEventBlock? = nil
  @objc var onTransactionStarted: RCTBubblingEventBlock? = nil
  @objc var onTransactionCompleted: RCTBubblingEventBlock? = nil
  @objc var onCloseButtonTapped: RCTBubblingEventBlock? = nil
  
  private var currentController: ApphudPaywallScreenController? = nil {
    willSet {
      currentController?.viewWillDisappear(true)
      currentController?.view.removeFromSuperview()
      currentController?.removeFromParent()
    }
    
    didSet {
      guard let currentController = currentController, let newView = currentController.view else {
        return
      }
      
      
      if let parentVC = RCTPresentedViewController() {
        currentController.willMove(toParent: parentVC)
        parentVC.addChild(currentController)
        currentController.didMove(toParent: parentVC)
      }
      
      newView.isUserInteractionEnabled = true
      onReceiveView?([:])
      
      currentController.onTransactionStarted = { [weak self] result in
        self?.onTransactionStarted?(["result": result?.toMap() as Any])
      }
      
      currentController.onTransactionCompleted = {[weak self] result in
        self?.onTransactionCompleted?(["result": result.toMap() as Any])
      }
      
      currentController.onCloseButtonTapped = { [weak self] in
        self?.onCloseButtonTapped?([:])
      }
      
      addSubview(newView)
      
      newView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      

      return
    }
  }
  
  
  deinit {
    currentController?.willMove(toParent: nil)
    currentController?.view.removeFromSuperview()
    currentController?.removeFromParent()
  }

  @objc var placementIdentifier: String? = nil {
    didSet {
      setupView()
    }
  }
  
  @objc var requestPlacementsOptions: NSDictionary? = nil {
    didSet {
      setupView()
    }
  }
  
  func reload() {
    setupView()
  }
  
  private func setupView() {
    isUserInteractionEnabled = true
    guard let placementIdentifier = placementIdentifier else {
      return
    }
    
    self.onStartLoading?(["placementIdentifier": placementIdentifier])
    
    let maxAttempts = requestPlacementsOptions?["maxAttempts"] as? Int ?? APPHUD_DEFAULT_RETRIES
    let forceRefresh = requestPlacementsOptions?["forceRefresh"] as? Bool ?? false

    Apphud
      .fetchPlacements(maxAttempts: maxAttempts, forceRefresh: forceRefresh) {
        [weak self, placementIdentifier] placements,
        error in
        guard let self = self,
              self.placementIdentifier == placementIdentifier else {
          return
        }
      
        let placement = placements.first {
          $0.identifier == placementIdentifier
        }
      
        guard let paywall = placement?.paywall else {  
          let error = NSError(
            domain: "ApphudView",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Paywall not not found"])
          
          self.onLoadingError?([
            "error": SerializedError(from: error).toMap(),
            "placementIdentifier": placementIdentifier
          ])
          return
        }
      
        Apphud
          .fetchPaywallScreen(paywall) { [
            weak self,
            placementIdentifier
          ] result in
            guard let self = self, self.placementIdentifier == placementIdentifier else {
              return
            }

            switch result {
            case .success(let controller):
              self.currentController = controller
              break
            case .error(let error):
              
              self.onLoadingError?(
                [
                  "error": SerializedError(from: error).toMap(),
                  "placementIdentifier": placementIdentifier
                ]
              )
              break
            }
          }
      }
  }
}
