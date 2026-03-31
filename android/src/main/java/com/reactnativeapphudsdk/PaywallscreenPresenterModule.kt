package com.reactnativeapphudsdk

import com.apphud.sdk.Apphud
import com.apphud.sdk.domain.ApphudPaywallScreenShowResult
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.modules.core.DeviceEventManagerModule

enum class PaywallscreenPresenterEvent(val eventName: String) {
  ERROR("error"),
  SCREEN_SHOWN("screenShown"),
  CLOSE_BUTTON_TAPPED("closeButtonTapped"),
  TRANSACTION_COMPLETED("transactionCompleted"),
  TRANSACTION_STARTED("transactionStarted"),
}

class PaywallscreenPresenterModule(private val reactApplicationContext: ReactApplicationContext): ReactContextBaseJavaModule(reactApplicationContext) {
  override fun getName(): String = "PaywallscreenPresenter"

  @ReactMethod
  fun displayPaywallScreen(options: ReadableMap) {
    val paywallScreenPresenterId = options.getString("paywallScreenPresenterId") ?: return

    options.getString("placementIdentifier") ?: run {
      emit(PaywallscreenPresenterEvent.ERROR, paywallScreenPresenterId, "Paywall not not found")
      return
    }

    Utils.paywall(options) { paywall ->
      if (paywall == null) {
        emit(PaywallscreenPresenterEvent.ERROR, paywallScreenPresenterId, "Paywall not not found")
        return@paywall
      }

      val callbacks = Apphud.ApphudPaywallScreenCallbacks(
        onScreenShown = {
          emit(PaywallscreenPresenterEvent.SCREEN_SHOWN, paywallScreenPresenterId, null)
        },
        onTransactionStarted = {
          emit(PaywallscreenPresenterEvent.TRANSACTION_STARTED, paywallScreenPresenterId, it?.toMap())
        },
        onTransactionCompleted = {
          if (it !is ApphudPaywallScreenShowResult.TransactionError) {
            emit(PaywallscreenPresenterEvent.TRANSACTION_COMPLETED, paywallScreenPresenterId, it.toMap())
          }
        },
        onCloseButtonTapped = {
          emit(PaywallscreenPresenterEvent.CLOSE_BUTTON_TAPPED, paywallScreenPresenterId, null)
        },
        onScreenError = {
          emit(PaywallscreenPresenterEvent.ERROR, paywallScreenPresenterId, it.message)
        }
      )
      Apphud.showPaywallScreen(reactApplicationContext, paywall, callbacks = callbacks)
    }
  }

  private fun emit(event: PaywallscreenPresenterEvent, paywallScreenPresenterId: String, data: Any?) {
    val params = Arguments.createMap().apply {
      putString("paywallScreenPresenterId", paywallScreenPresenterId)

      when (data) {
        null -> putNull("payload")
        is String -> putString("payload", data)
        is Boolean -> putBoolean("payload", data)
        is Int -> putInt("payload", data)
        is Double -> putDouble("payload", data)
        is Float -> putDouble("payload", data.toDouble())
        is Long -> putDouble("payload", data.toDouble())
        is ReadableMap -> putMap("payload", data)
        is ReadableArray -> putArray("payload", data)
        else -> {
          putString("payload", data.toString())
        }
      }
    }

    reactApplicationContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      .emit(event.eventName, params)
  }
}
