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
import Firebase
import GoogleSignIn
import Domain
import Platform

protocol SignInInterface {
  func signInSilently(_ callback: @escaping (_ user: GIDGoogleUser?, _ error: Error?) -> Void)
  func signIn(_ callback: @escaping (_ user: GIDGoogleUser?, _ error: Error?) -> Void)
  func signOut()
  @discardableResult func onSignIn(_ callback: @escaping () -> Void) -> SignInInterface
  @discardableResult func onSignOut(_ callback: @escaping () -> Void) -> SignInInterface
}

class SignIn: NSObject, SignInInterface, GIDSignInDelegate {

  static let sharedInstance: SignInInterface = SignIn()

  override private init() {
    super.init()
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()!.options.clientID
    GIDSignIn.sharedInstance().delegate = self
    GIDSignIn.sharedInstance().uiDelegate = self
    Auth.auth().addStateDidChangeListener { (_, user) in
      if user != nil {
        self.invokeSignInSuccessCallbacks()
      } else {
        self.invokeSignOutCallbacks()
      }
    }
  }

  var currentCallback: ((_ user: GIDGoogleUser?, _ error: Error?) -> Void)?

  func signInSilently(_ callback: @escaping (_ user: GIDGoogleUser?, _ error: Error?) -> Void) {
    currentCallback = callback
    if GIDSignIn.sharedInstance().hasAuthInKeychain() {
      GIDSignIn.sharedInstance().signInSilently()
    } else {
      Auth.auth().signInAnonymously { (user, error) in
      }
    }
  }

  func signIn(_ callback: @escaping (_ user: GIDGoogleUser?, _ error: Error?) -> Void) {
    currentCallback = callback
    GIDSignIn.sharedInstance().signIn()
  }

  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
    guard error == nil else {
      print("GIDSignIn error: \(error!)")
      if let user = user {
        currentCallback?(user, error)
      }
      return
    }

    guard let user = user else { return }

    for signInSuccessCallback in signInSuccessCallbacks {
      signInSuccessCallback()
    }

    if let firebaseUser = Auth.auth().currentUser {
      let credential = GoogleAuthProvider.credential(withIDToken: user.authentication.idToken,
                                                     accessToken: user.authentication.accessToken)
      firebaseUser.link(with: credential) { _, error in
        if let error = error {
          print("Error linking credentials: \(error)")
        } else {
          print("Successfully linked Google account")
        }
      }
    }

    currentCallback?(user, error)
  }

  func signOut() {
    GIDSignIn.sharedInstance().signOut()
    invokeSignOutCallbacks()
    if Auth.auth().currentUser == nil {
      Auth.auth().signInAnonymously { (user, error) in
        print("User signed out manually. Falling back to anonymous user")
        let userDescription = user.flatMap(String.init(describing:)) ?? "nil"
        let errorDescription = error.flatMap(String.init(describing:)) ?? "nil"
        print("Anonymous login completed with user: \(userDescription), error: \(errorDescription)")
      }
    }
  }

  // MARK: - Callback handlers

  var signInSuccessCallbacks = [() -> Void]()
  func onSignIn(_ callback: @escaping () -> Void) -> SignInInterface {
    signInSuccessCallbacks.append(callback)
    return self
  }

  var signOutCallbacks = [() -> Void]()
  func onSignOut(_ callback: @escaping () -> Void) -> SignInInterface {
    signOutCallbacks.append(callback)
    return self
  }

  func invokeSignOutCallbacks() {
    for callback in signOutCallbacks {
      callback()
    }
  }

  func invokeSignInSuccessCallbacks() {
    for callback in signInSuccessCallbacks {
      callback()
    }
  }

}

extension SignIn: GIDSignInUIDelegate {
  func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
    if var topController = UIApplication.shared.keyWindow?.rootViewController {
      while let presentedViewController = topController.presentedViewController {
        topController = presentedViewController
      }
      topController.present(viewController, animated: true, completion: nil)
    }
  }

  func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
    viewController.dismiss(animated: true, completion: nil)
  }
}
