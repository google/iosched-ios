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
import CoreSpotlight
import MobileCoreServices

extension Application {
  private enum DeepLinkingConstants {
    static let sessionID = "sessionId"
  }

  func navigateToDeepLink(uniqueIdPath: String) {
    let uniqueIdComponents = uniqueIdPath.components(separatedBy: "/")
    if uniqueIdComponents.count == 2 {
      let uniqueIdentifier = uniqueIdComponents[1]
      if let type = IndexConstants(rawValue: uniqueIdComponents[0]) {
        switch type {
        case .sessionDomainIdentifier:
          tabBarController.selectedViewController = scheduleNavigationController
          scheduleNavigator.navigateToSessionDetails(sessionID: uniqueIdentifier, popToRoot: true)

        case .speakerDomainIdentifier:
          tabBarController.selectedViewController = scheduleNavigationController
          // This won't work unless we can get a speaker object for the id.
          //scheduleNavigator.navigateToSpeakerDetails(speakerId: uniqueIdentifier, popToRoot: true)
        }
      }
    }
  }

  func navigateToImFeelingLucky(_ shortcutItem: UIApplicationShortcutItem) {
    guard let userInfo = shortcutItem.userInfo,
          let sessionID = userInfo[DeepLinkingConstants.sessionID] as? String else { return }

    // navigate to session detected in launch shortcut
    navigateToDeepLink(uniqueIdPath: sessionID)

    // ... and re-register launch shortcut with a new random session
    registerImFeelingLuckyShortcut()
  }

  @objc func registerImFeelingLuckyShortcut() {
    if let sessionID = serviceLocator.sessionsDataSource.randomSessionId() {
      let userInfo = [
        DeepLinkingConstants.sessionID: IndexConstants.sessionDomainIdentifier.rawValue
            + "/" + sessionID
      ]
      let icon = UIApplicationShortcutIcon(type: .search)
      let item = UIApplicationShortcutItem(
        type: "com.google.iosched.imfeelinglucky",
        localizedTitle: NSLocalizedString("I'm feeling lucky",
            comment: "I'm feeling luck Siri shortcut name"),
        localizedSubtitle: NSLocalizedString("Show a random session",
            comment: "Describes the function of the I'm feeling lucky shortcut"),
        icon: icon,
        userInfo: userInfo as [String: NSSecureCoding]
      )
      UIApplication.shared.shortcutItems = [item]
    }
  }

}

extension AppDelegate {
  func application(_ application: UIApplication,
                   continue userActivity: NSUserActivity,
                   restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if userActivity.activityType == CSSearchableItemActionType {
      if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
        Application.sharedInstance.navigateToDeepLink(uniqueIdPath: uniqueIdentifier)
      }
    }

    return true
  }

  func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
    app.navigateToImFeelingLucky(shortcutItem)
    return true
  }

  func application(_ application: UIApplication,
                   performActionFor shortcutItem: UIApplicationShortcutItem,
                   completionHandler: @escaping (Bool) -> Void) {
    let handledShortCutItem = handleShortcutItem(shortcutItem: shortcutItem)
    completionHandler(handledShortCutItem)
  }
}
