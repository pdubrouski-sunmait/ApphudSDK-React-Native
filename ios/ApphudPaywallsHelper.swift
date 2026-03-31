import ApphudSDK
import Combine

final class ApphudPaywallsHelper {
  static func getPaywall(options: [AnyHashable: Any]) async -> ApphudPaywall? {
    let maxAttempts = options["maxAttempts"] as? Int ?? APPHUD_DEFAULT_RETRIES
    let forceRefresh = options["forceRefresh"] as? Bool ?? false
    
    let placementId = options["placementIdentifier"] as? String
    let paywallId = options["paywallIdentifier"] as? String
    
    return await withCheckedContinuation { @MainActor continuation in
      Apphud.fetchPlacements(maxAttempts: maxAttempts, forceRefresh: forceRefresh) { placements, error in
        if let placementId {
          let paywall = placements.first { $0.identifier == placementId }?.paywall
          continuation.resume(returning: paywall)
        } else if let paywallId {
          let paywall = placements.compactMap(\.paywall).first { $0.identifier == paywallId }
          continuation.resume(returning: paywall)
        } else {
          continuation.resume(returning: nil)
        }
      }
    }
  }
  
  static func getPaywalls(maxAttempts: Int = APPHUD_DEFAULT_RETRIES, forceRefresh: Bool = false) async -> [ApphudPaywall] {
    return await withCheckedContinuation { @MainActor continuation in
      Apphud.fetchPlacements(maxAttempts: maxAttempts, forceRefresh: forceRefresh) { placements, error in
        continuation.resume(returning: placements.compactMap(\.paywall))
      }
    }
  }
}
