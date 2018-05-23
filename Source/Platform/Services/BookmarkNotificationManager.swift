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

import Foundation
import UserNotifications
import Domain

/// A class that wraps our permissions for sending notifications.
/// Use this instead of calling UIApplication.scheduleLocalNotification
/// directly to respect the user's notification settings.
final class NotificationScheduler {

  private let userState: WritableUserState
  private let application: UIApplication

  init(userState: WritableUserState, application: UIApplication = UIApplication.shared) {
    self.userState = userState
    self.application = application
  }

  func scheduleLocalNotification(_ notification: UILocalNotification) {
    if userState.isNotificationsEnabled {
      UIApplication.shared.scheduleLocalNotification(notification)
    }
  }

  @available(iOS 10.0, *)
  func scheduleRequest(_ request: UNNotificationRequest) {
    if userState.isNotificationsEnabled {
      UNUserNotificationCenter.current().add(request)
    }
  }

}

protocol BookmarkNotificationManager {
  func scheduleNotification(for session: Session)
  func cancelNotification(for session: Session)
}

final class DefaultBookmarkNotificationManager: NSObject, BookmarkNotificationManager {

  private let scheduler: NotificationScheduler

  init(userState: WritableUserState) {
    let scheduler = NotificationScheduler(userState: userState)
    self.scheduler = scheduler
  }

  private enum Constants {
    static let notificationTitle = NSLocalizedString("Session is about to start", comment: "Title for session notification")
    static let sessionIdKey = "sessionId"
    static let alertAction = NSLocalizedString("Open", comment: "Notification action")
    static let DEBUG = false
  }

  func scheduleNotification(for session: Session) {
    if #available(iOS 10.0, *) {
      let content = UNMutableNotificationContent()
      content.title = Constants.notificationTitle
      content.subtitle = session.title
      content.body = session.detail
      content.userInfo = [Constants.sessionIdKey: session.id]
      content.sound = UNNotificationSound.default()

      let calendar = NSCalendar.autoupdatingCurrent
      let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: session.notificationTime)

      let trigger = Constants.DEBUG
        ? UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        : UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

      let request = UNNotificationRequest(identifier: session.id,
                                          content: content,
                                          trigger: trigger)
      scheduler.scheduleRequest(request)
    }
    else {
      // iOS 9
      let notification = UILocalNotification()
      notification.alertTitle = Constants.notificationTitle
      notification.alertBody = session.title
      notification.alertAction = Constants.alertAction
      notification.userInfo = [Constants.sessionIdKey: session.id]
      notification.soundName = UILocalNotificationDefaultSoundName

      let notificationTime = Constants.DEBUG
        ? Date().addingTimeInterval(10)
        : session.notificationTime
      notification.fireDate = notificationTime

      scheduler.scheduleLocalNotification(notification)
    }
  }

  func cancelNotification(for session: Session) {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [session.id])
    }
    else {
      UIApplication.shared.scheduledLocalNotifications?.forEach { notification in
        if session.id == notification.userInfo?[Constants.sessionIdKey] as? String {
          UIApplication.shared.cancelLocalNotification(notification)
        }
      }
    }
  }

}
