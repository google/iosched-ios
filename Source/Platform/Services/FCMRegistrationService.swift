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
import Domain
import GoogleSignIn
import GTMSessionFetcher
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

public protocol FCMRegistrationService {
  func register(device deviceId: String)
  func unregister(device deviceId: String)
}

public class DefaultFCMRegistrationService: FCMRegistrationService {

  private let firestore: Firestore
  private let auth: Auth

  init(firestore: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
    self.firestore = firestore
    self.auth = auth
  }

  public func register(device deviceId: String) {
    guard let user = auth.currentUser else { return }

    guard let currentToken = Messaging.messaging().fcmToken else { return }
    if deviceId != currentToken {
      let token = currentToken
      print("Warning: registered token is different from the current FCM token: \(token)")
    }

    firestore.setToken(deviceId, for: user)
  }

  public func unregister(device deviceId: String) {
    guard let user = auth.currentUser else { return }

    firestore.removeToken(deviceId, for: user)
  }

}
