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
import Firebase
import Domain
import Platform
import Alamofire
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

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Firebase setup
    FirebaseApp.configure()
    // Uncomment this line to enable debug logging from Firebase.
    // FirebaseConfiguration.shared.setLoggerLevel(.debug)

    var launchedFromShortcut = false

    if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
      launchedFromShortcut = true
      _ = handleShortcutItem(shortcutItem: shortcutItem)
    }

    // Enable realtime database offline
    Database.database().isPersistenceEnabled = true

    // Auth
    Application.sharedInstance.analytics.setUserProperty("false", forName: "user_logged_in")
    SignIn.sharedInstance
      .onSignIn {
        DefaultServiceLocator.sharedInstance.userState.registerForSyncMessages()
        DefaultServiceLocator.sharedInstance.bookmarkStore.sync()

        if let googleUser = GIDSignIn.sharedInstance().currentUser {
          self.firebaseSignIn(user: googleUser)
        }
        Application.sharedInstance.analytics.setUserProperty("true", forName: "user_logged_in")
      }.onSignOut {
        do {
          try Auth.auth().signOut()
        } catch {}
        DefaultServiceLocator.sharedInstance.reservationStore.purgeLocalReservations()
        DefaultServiceLocator.sharedInstance.userState.updateUserRegistrationStatus()
      }
      .signInSilently { (_, error) in
        guard error == nil else {
          print("While trying to silently sign in, an error ocurred: \(error!)")
          return
        }
      }

    // UI setup
    Application.sharedInstance.configureMainInterface(in: self.window)
    self.window?.makeKeyAndVisible()

    // Notification setup
    Application.sharedInstance.setupNotifications(for: application, with: self)

    // Update conference data
    DispatchQueue.global().async {
      DefaultServiceLocator.sharedInstance.updateConferenceData {
        Application.sharedInstance.registerImFeelingLuckyShortcut()
      }
    }

    return !launchedFromShortcut
  }

  func application(_ application: UIApplication,
                   open url: URL,
                   options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
    return GIDSignIn.sharedInstance().handle(url,
                                             sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                             annotation: [:])
  }

  func firebaseSignIn(user: GIDGoogleUser) {
    guard let authentication = user.authentication else { return }
    let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                   accessToken: authentication.accessToken)
    print("Signed in with Google")

    Auth.auth().signIn(with: credential, completion: { (_, _) in
      print("Authenticated with Firebase")
      DefaultServiceLocator.sharedInstance.reservationStore.sync()
      DefaultServiceLocator.sharedInstance.userState.updateUserRegistrationStatus()
    })
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    if let user = Auth.auth().currentUser {
      Firestore.firestore().setLastVisited(Date(), for: user)
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
      if let sessionId = response.notification.request.content.userInfo["sessionId"] as? String {
        print(sessionId)
        Application.sharedInstance.navigateToDeepLink(uniqueIdPath: sessionId)
      } else if let action = response.notification.request.content.userInfo["action"] as? String,
          action == "GO_TO_INFO" {
        
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
      let okAction = MDCAlertAction(title:"OK") { _ in
        if let sessionId = notification.userInfo?["sessionId"] as? String {
          print(sessionId)
          Application.sharedInstance.navigateToDeepLink(uniqueIdPath: sessionId)
        }
      }
      let dismissAction = MDCAlertAction(title: "Dismiss")
      alertController.addAction(okAction)
      alertController.addAction(dismissAction)

      application.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
  }
}
