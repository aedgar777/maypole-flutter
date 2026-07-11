import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API Key
    GMSServices.provideAPIKey("AIzaSyA7kcPWjaVK3iC4qbmSO1vuTBEk11llq9A")
    GeneratedPluginRegistrant.register(with: self)
    MaypoleInstallGoogleMapPoiBridge()

    if let url = launchOptions?[.url] as? URL {
      NSLog("Maypole DeepLink: app launched via URL \(url.absoluteString)")
    }
    if let userActivityDict = launchOptions?[.userActivityDictionary] as? [String: Any],
       let userActivity = userActivityDict["UIApplicationLaunchOptionsUserActivityKey"] as? NSUserActivity,
       userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let webpageURL = userActivity.webpageURL {
      NSLog("Maypole DeepLink: app launched via universal link \(webpageURL.absoluteString)")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    NSLog("Maypole DeepLink: custom URL scheme opened \(url.absoluteString)")
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let webpageURL = userActivity.webpageURL {
      NSLog("Maypole DeepLink: universal link continued \(webpageURL.absoluteString)")
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
