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

import UIKit
import UserNotifications
import Firebase
import Domain
import Platform

extension Application {

  func setupNotifications(for application: UIApplication, with delegate: AppDelegate) {
    Messaging.messaging().delegate = delegate
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = delegate
    }
    delegate.registerDeviceWithFCMServer()
  }

  func registerForSyncNotifications() {
    // we receive silent notifications for triggering bookmark sync
    UIApplication.shared.registerForRemoteNotifications()
  }

}

// MARK: - Instance ID Token handling
extension AppDelegate {

  func registerDeviceWithFCMServer() {
    // register for ID token refresh
    registerForIDTokenRefresh()

    performOrUpdateRegistration()
  }

  func registerForIDTokenRefresh() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(didReceiveTokenRefreshNotification),
                                           name: .InstanceIDTokenRefresh,
                                           object: nil)
  }

  @objc func didReceiveTokenRefreshNotification(_ notification: NSNotification?) {
    performOrUpdateRegistration()
  }

  func performOrUpdateRegistration() {
    guard let _ = InstanceID.instanceID().token() else {
      print("ID token not yet available.")
      return
    }

    // register ID token on server
    DefaultServiceLocator.sharedInstance.userState.registerForSyncMessages()
  }
}

// MARK: - Receive notifications
extension AppDelegate: MessagingDelegate {

  fileprivate enum Actions {
    static let syncEventData = "SYNC_EVENT_DATA"
    static let promotion = "PROMOTION"
    static let androidThings = "GO_TO_INFO"
  }

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    let userInfo = [IONotificationFCMToken: fcmToken]
    NotificationCenter.default.post(name: .fcmTokenDidRefresh, object: nil, userInfo: userInfo)
  }

  // Receive data message on iOS 10 devices while app is in the foreground.
  func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
    print("Received remote message \(remoteMessage)")
    if let action = remoteMessage.appData["action"] as? String {
      if action == Actions.syncEventData {
        self.syncEventData(fetchCompletionHandler: { (result: UIBackgroundFetchResult) in })
      }
      else if action == Actions.promotion {
        self.syncUserData(fetchCompletionHandler: { (result: UIBackgroundFetchResult) in })
      }
    }
  }

  // Receive silent notifications, iOS style
  func application(_ application: UIApplication,
                   didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                   fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

    if let action = userInfo["action"] as? String {
      print("Remote notification action: \(action)")
      if action == Actions.syncEventData {
        self.syncEventData(fetchCompletionHandler: completionHandler)
      }
      else if action == Actions.promotion {
        self.syncUserData(fetchCompletionHandler: completionHandler)
      }
    }
  }

  private func syncEventData(fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    DefaultServiceLocator.sharedInstance.updateConferenceData {
      completionHandler(.newData)
    }
  }
  
  private func syncUserData(fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    DefaultServiceLocator.sharedInstance.bookmarkStore.sync {
      completionHandler(.newData)
    }
    DefaultServiceLocator.sharedInstance.reservationStore.sync {
      completionHandler(.newData)
    }
  }

}

// MARK: - Notification error handling
extension AppDelegate {

  func application(_ application: UIApplication,
                   didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications with error \(error)")

    var notification = Notification(name: .notificationRegistrationDidFail)
    let userInfo = [IONotificationRegistrationErrorKey: error]
    notification.userInfo = userInfo
    NotificationCenter.default.post(notification)
  }

  func application(_ application: UIApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    var readableToken = ""
    for i in 0 ..< deviceToken.count {
      readableToken += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
    }
    print("Received an APNs device token: \(readableToken)")

    var notification = Notification(name: .notificationRegistrationDidSucceed)
    let userInfo = [IONotificationRegistrationTokenKey: deviceToken]
    notification.userInfo = userInfo
    NotificationCenter.default.post(notification)
  }
}

private let IONotificationRegistrationErrorKey = "com.google.iosched.notificationRegistrationError"
private let IONotificationRegistrationTokenKey = "com.google.iosched.notificationRegistrationToken"
private let IONotificationFCMToken             = "com.google.iosched.notificationFCMTokenRefresh"

extension Notification.Name {

  /// Posted on notification registration success. Device token data is in the userInfo dictionary
  /// under the IONotificationRegistrationErrorKey key.
  static let notificationRegistrationDidSucceed =
      Notification.Name("com.google.iosched.registrationDidSucceedNotification")

  /// Posted on notification registration failure. Error is in the userInfo dictionary under 
  /// the IONotificationRegistrationTokenKey key.
  static let notificationRegistrationDidFail =
      Notification.Name("com.google.iosched.registrationDidFailNotification")

  /// Posted on FCM token refresh. The FCM token is in the userInfo dictionary under the
  /// IONotificationFCMToken key.
  static let fcmTokenDidRefresh =
      Notification.Name("com.google.iosched.fcmTokenDidRefreshNotification")

}

/// Class responsible for writing and requesting notifications permissions.
final class NotificationPermissions {

  @available(iOS 10.0, *)
  static let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]

  static let notificationTypes: UIUserNotificationType = [.alert, .sound, .badge]

  private let userState: WritableUserState
  private let application: UIApplication

  private var successObserver: Any? {
    willSet {
      if let observer = successObserver {
        NotificationCenter.default.removeObserver(observer)
      }
    }
  }

  private var failureObserver: Any? {
    willSet {
      if let observer = failureObserver {
        NotificationCenter.default.removeObserver(observer)
      }
    }
  }

  private var refreshObserver: Any? {
    willSet {
      if let observer = refreshObserver {
        NotificationCenter.default.removeObserver(observer)
      }
    }
  }

  private var activeObserver: Any? {
    willSet {
      if let observer = activeObserver {
        NotificationCenter.default.removeObserver(observer)
      }
    }
  }

  init(userState: WritableUserState, application: UIApplication) {
    self.userState = userState
    self.application = application
    
    NotificationCenter.default.addObserver(forName: .userRegistrationStateDidUpdate,
                                           object: nil,
                                           queue: nil) { (notification: Notification) in
      self.subscribeToTopics()
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  /// Setting this to true will request notifications permissions if they aren't already granted
  /// and subscribe/unsubscribe to FCM topics.
  var isNotificationsEnabled: Bool {
    get {
      return userState.isNotificationsEnabled
    }
    set {
      setNotificationsEnabled(newValue)
    }
  }

  var arePermissionsGranted: Bool {
    let types = application.currentUserNotificationSettings?.types ?? []
    return types == NotificationPermissions.notificationTypes
  }

  /// Closure is retained until the callback is invoked, and then discarded afterward.
  func setNotificationsEnabled(_ newValue: Bool, completion: ((Bool) -> Void)? = nil) {
    userState.setNotificationsEnabled(newValue)
    if newValue {
      registerForNotifications(completion)
      subscribeToTopics()
    }
    else {
      unsubscribeFromTopics()
      cancelLocalNotifications()
      completion?(false)
    }
  }

  private func registerForNotifications(_ completion: ((Bool) -> Void)? = nil) {
    if application.isRegisteredForRemoteNotifications {
      completion?(true)
      return
    }

    successObserver = NotificationCenter.default.addObserver(forName: .notificationRegistrationDidSucceed,
                                                             object: nil,
                                                             queue: nil,
                                                             using: { _ in
      self.invokeCompletionHandler(granted: true, completion: completion)
    })
    failureObserver = NotificationCenter.default.addObserver(forName: .notificationRegistrationDidFail,
                                                             object: nil,
                                                             queue: nil,
                                                             using: { _ in
      self.invokeCompletionHandler(granted: false, completion: completion)
    })
    refreshObserver = NotificationCenter.default.addObserver(forName: .fcmTokenDidRefresh,
                                                             object: nil,
                                                             queue: nil,
                                                             using: { _ in
      self.subscribeToTopics() // Resubscribe on token refresh.
    })

    // Used to detect when the notifications alert has been dismissed.
    activeObserver = NotificationCenter.default.addObserver(forName: .UIApplicationDidBecomeActive,
                                                            object: nil,
                                                            queue: nil,
                                                            using: { (_) in
      self.application.registerForRemoteNotifications()
      self.activeObserver = nil
    })

    if #available(iOS 10.0, *) {
      let options = NotificationPermissions.authOptions
      UNUserNotificationCenter.current().requestAuthorization(options: options) { (_, _) in
        // This callback is handled by the app delegate methods for iOS 9 compatibility.
      }
    }
    else {
      let types = NotificationPermissions.notificationTypes
      let settings = UIUserNotificationSettings(types: types, categories: nil)
      application.registerUserNotificationSettings(settings)
    }
  }

  private func invokeCompletionHandler(granted: Bool, completion: ((Bool) -> Void)? = nil) {
    completion?(granted)

    // Granted is always true since we register for notifications with no permissions
    // for background sync. The notifications switch in settings should only be enabled
    // if the user granted us the right permissions for full notifications, not just
    // background sync.
    let success = arePermissionsGranted
    self.isNotificationsEnabled = success
    self.successObserver = nil
    self.failureObserver = nil
  }

  private static let fcmTopics = ["CONFERENCE_DATA_SYNC_2018"]
  private static let fcmRegisteredTopics = ["REGISTERED_2018"]

  fileprivate func subscribeToTopics() {
    guard isNotificationsEnabled else { return }
    NotificationPermissions.fcmTopics.forEach {
      Messaging.messaging().subscribe(toTopic: $0)
    }
    // Subscribe only if user is an IO attendee.
    if (userState.isUserRegistered) {
      NotificationPermissions.fcmRegisteredTopics.forEach {
        Messaging.messaging().subscribe(toTopic: $0)
      }
    }
  }

  private func unsubscribeFromTopics() {
    NotificationPermissions.fcmTopics.forEach {
      Messaging.messaging().unsubscribe(fromTopic: $0)
    }
    if (userState.isUserRegistered) {
      NotificationPermissions.fcmRegisteredTopics.forEach {
        Messaging.messaging().unsubscribe(fromTopic: $0)
      }
    }
  }

  private func cancelLocalNotifications() {
    if #available(iOS 10, *) {
      UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    application.scheduledLocalNotifications?.forEach {
      self.application.cancelLocalNotification($0)
    }
  }

}
