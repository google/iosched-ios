//
//  Copyright (c) 2017 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import MaterialComponents
import GoogleSignIn
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import UserNotifications
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var mdcWindow: MDCOverlayWindow?
  var window: UIWindow? {
    get {
      mdcWindow = mdcWindow ?? MDCOverlayWindow(frame: UIScreen.main.bounds)
      return mdcWindow
    }
    set {}
  }
  private(set) lazy var app: Application = {
    return Application.sharedInstance
  }()

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Firebase setup
    FirebaseApp.configure()
    // Uncomment this line to enable debug logging from Firebase.
    // FirebaseConfiguration.shared.setLoggerLevel(.debug)

    var launchedFromShortcut = false

    if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
      launchedFromShortcut = true
      _ = handleShortcutItem(shortcutItem: shortcutItem)
    }

    // Auth
    app.analytics.setUserProperty("false", forName: "user_logged_in")
    _ = SignIn.sharedInstance.addGoogleSignInHandler(self) { [weak self] in
      guard let self = self else { return }
      self.app.serviceLocator.userState.registerForFCM()
      self.app.serviceLocator.userState.updateUserRegistrationStatus()

      self.app.analytics.setUserProperty("true", forName: "user_logged_in")
    }
    _ = SignIn.sharedInstance.addGoogleSignOutHandler(self) { [weak self] in
      guard let self = self else { return }
      self.app.serviceLocator.userState.updateUserRegistrationStatus()
    }
    SignIn.sharedInstance.signInSilently { (_, error) in
      guard error == nil else {
        print("While trying to silently sign in, an error ocurred: \(error!)")
        return
      }
    }

    // UI setup
    Application.sharedInstance.configureMainInterface(in: self.window)
    self.window?.makeKeyAndVisible()

    // Notification setup
    self.app.setupNotifications(for: application, with: self)

    // Update conference data
    app.serviceLocator.updateConferenceData { [weak self] in
      self?.app.registerImFeelingLuckyShortcut()
    }

    registerForTimeZoneNotifications()

    return !launchedFromShortcut
  }

  func application(_ application: UIApplication,
                   open url: URL,
                   options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
    let sourceApplication = options[.sourceApplication] as? String
    return GIDSignIn.sharedInstance().handle(url,
                                             sourceApplication: sourceApplication,
                                             annotation: [:])
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    if let user = Auth.auth().currentUser {
      Firestore.firestore().setLastVisitedDate(for: user)
    }
  }

}

@available(iOS 10.0, *)
extension AppDelegate: UNUserNotificationCenterDelegate {

  public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     willPresent notification: UNNotification,
                                     withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // Play sound and show alert to the user
    completionHandler([.alert, .sound])
  }

  public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     didReceive response: UNNotificationResponse,
                                     withCompletionHandler completionHandler: @escaping () -> Void) {
    // Determine the user action
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      if let sessionID = response.notification.request.content.userInfo["sessionId"] as? String {
        print(sessionID)
        Application.sharedInstance.navigateToDeepLink(uniqueIdPath: sessionID)
      }
    }
    completionHandler()
  }
}

// MARK: Notification handling

@available(iOS 9.0, *)
extension AppDelegate {
  func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
    if application.applicationState == .active {
      let title = notification.alertTitle
      let message = notification.alertBody
      let alertController = MDCAlertController(title: title, message: message)
      let okAction = MDCAlertAction(title: "OK") { _ in
        if let sessionID = notification.userInfo?["sessionId"] as? String {
          print(sessionID)
          Application.sharedInstance.navigateToDeepLink(uniqueIdPath: sessionID)
        }
      }
      let dismissAction = MDCAlertAction(title: "Dismiss")
      alertController.addAction(okAction)
      alertController.addAction(dismissAction)

      application.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
  }
}

// MARK: - Time zone change handling

extension AppDelegate {

  func registerForTimeZoneNotifications() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(timeZoneDidChange),
                                           name: .NSSystemTimeZoneDidChange,
                                           object: nil)
  }

  @objc private func timeZoneDidChange() {
    NotificationCenter.default.post(name: .timezoneUpdate, object: nil)
  }

}
