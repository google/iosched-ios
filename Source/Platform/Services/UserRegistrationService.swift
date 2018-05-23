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
import FirebaseAuth

public protocol UserRegistrationService {
  func isUserRegistered(idToken: String, completion: @escaping (_ registered: Bool) -> Void)
}

// AppEngine will be used only for initial registration checks, after which registration
// checks should be stored in Firestore.
public class DefaultUserRegistrationService: UserRegistrationService {

  static let endpoint = URL(string: Configuration.sharedInstance.registrationEndpoint)!

  private let urlSession: URLSession

  init(urlSession: URLSession = URLSession.shared) {
    self.urlSession = urlSession
  }

  /// Returns asynchronously whether or not the user is registered. This value does not change, and
  /// can be stored in the app without worrying about invalidation (except on auth changes).
  /// Note: The idToken parameter is the user's ID Token, not their uid.
  public func isUserRegistered(idToken: String, completion: @escaping (_ registered: Bool) -> Void) {
    var request = URLRequest(url: DefaultUserRegistrationService.endpoint)
    request.httpMethod = "GET"
    request.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

    let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
      if let error = error {
        print("Error fetching registration state for ID token \(idToken): \(error)")
      }
      if let response = response as? HTTPURLResponse {
        if response.statusCode != 200 {
          print("Fetching registration state finished with non-200 status code: \(response.statusCode)")
        }
      }
      guard let data = data else {
        completion(false)
        return
      }
      let isRegistered: Bool
      do {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = jsonObject as? [String: Bool] else {
          print("Fetching registration state returned unexpected object type: \(jsonObject)")
          completion(false)
          return
        }
        isRegistered = dict["registered"] ?? false
      } catch let jsonError {
        print("Fetching registration state failed to serialize: \(jsonError)")
        completion(false)
        return
      }

      completion(isRegistered)
    }
    dataTask.resume()
  }
}
