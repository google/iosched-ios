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
import GoogleSignIn

extension User {
  public init?(user googleUser: GIDGoogleUser) {
    // GIDGoogleUser's header doesn't have nullability annotations,
    // so this code is excessively cautious to avoid crashing.
    guard let id = googleUser.userID,
        let profile = googleUser.profile,
        let name = profile.name,
        let email = profile.email,
        // Set dimension to 3x the largest place we use it to account for high dpi screens.
        let imageURLString = profile.imageURL(withDimension: 72 * 3)?.absoluteString else {
      return nil
    }
    self.init(id: id, name: name, email: email, thumbnailURL: imageURLString)
  }
}
