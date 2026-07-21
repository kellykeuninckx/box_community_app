import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Expliciet aanroepen: bij dit project-template gebeurt Firebase's eigen
    // automatische trigger hiervoor niet betrouwbaar op tijd.
    DispatchQueue.main.async {
      print("[APNs] registerForRemoteNotifications() aanroepen...")
      application.registerForRemoteNotifications()
    }
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("[APNs] Geregistreerd, device token: \(deviceToken.map { String(format: "%02x", $0) }.joined())")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[APNs] Registratie mislukt: \(error)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
