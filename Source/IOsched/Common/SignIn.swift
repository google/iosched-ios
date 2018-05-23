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

import FirebaseAuth
import FirebaseCore
import GoogleSignIn

/// An interface describing a class that authenticates and returns a user or an error.
/// - SeeAlso: SignIn
public protocol SignInInterface {

  /// The currently authenticated Google user, if available. If the user is only signed in
  /// anonymously, this will return nil.
  var currentUser: UserInfo? { get }

  /// The current upgradable anonymous user session, if available. If the user is also signed
  /// into a Google account, this user will automatically be linked to the sign-in Google
  /// account. Otherwise, this user is an anonymous user with no sign in methods. In either
  /// case this property will return a nonnull user. On signout, this property will return nil
  /// until another anonymous session is created.
  var currentUpgradableUser: UpgradableUser? { get }

  /// Authenticates the user silently via stored Keychain credentials, if they have already
  /// previously logged in to the app.
  func signInSilently(_ callback: @escaping (_ user: GIDGoogleUser?, _ error: Error?) -> Void)

  /// Presents an OAuth flow for logging in the user and returns the user in the callback.
  func signIn(_ callback: @escaping (_ user: GIDGoogleUser?, _ error: Error?) -> Void)

  /// Signs out the current user, creating a new anonymous authentication session immediately
  /// after.
  func signOut()

  /// Registers a handler that is invoked on successful google sign in an unlimited number
  /// of times until it is deregistered. The object passed in is weakly retained by the receiver,
  /// and the handler will be removed automatically if obj ever becomes nil. The handler, however,
  /// is strongly retained.
  /// - SeeAlso: removeGoogleSignInHandler(_:)
  /// - Returns: An object that can be used later to remove the handler callback.
  func addGoogleSignInHandler(_ obj: AnyObject, handler: @escaping () -> Void) -> AnyObject

  /// Removes the callback associated with the object passed in.
  func removeGoogleSignInHandler(_ obj: Any)

  /// Registers a handler that is invoked on successful google sign out an unlimited number
  /// of times until it is deregistered. The object passed in is weakly retained by the receiver,
  /// and the handler will be removed automatically if obj ever becomes nil. The handler, however,
  /// is strongly retained.
  /// - SeeAlso: removeGoogleSignOutHandler(_:)
  /// - Returns: An object that can be used later to remove the handler callback.
  func addGoogleSignOutHandler(_ obj: AnyObject, handler: @escaping () -> Void) -> AnyObject

  /// Removes the callback associated with the object passed in.
  func removeGoogleSignOutHandler(_ obj: Any)

  /// Adds a closure that is invoked whenever the current anonymous user changes. The
  /// anonymous user may change whenever the user is logged out of their Google account, or
  /// on a fresh app launch.
  func addAnonymousAuthStateHandler(_ handler: @escaping (UserInfo?) -> Void) -> Any

  /// Removes an anonymous auth state change handler.
  func removeAnonymousAuthStateHandler(_ handler: Any)
}

public class SignIn: NSObject, SignInInterface, GIDSignInDelegate {

  public static let sharedInstance: SignInInterface = SignIn()

  private let googleSignIn: GIDSignIn
  private let anonymousAuth: UpgradableUserUpdateProvider

  public override convenience init() {
    self.init(signIn: GIDSignIn.sharedInstance(), anonymousAuth: Auth.auth())
  }

  public init(signIn: GIDSignIn, anonymousAuth: UpgradableUserUpdateProvider) {
    googleSignIn = signIn
    self.anonymousAuth = anonymousAuth
    super.init()
    googleSignIn.clientID = FirebaseApp.app()!.options.clientID
    googleSignIn.delegate = self
    googleSignIn.uiDelegate = self
    googleSignIn.scopes = [
      "https://www.googleapis.com/auth/calendar.events",
      "https://www.googleapis.com/auth/userinfo.profile",
      "https://www.googleapis.com/auth/userinfo.email"
    ]
  }

  public var currentUser: UserInfo? {
    // googleSignIn.currentUser user is an implicitly unwrapped optional, so some care should be
    // taken to avoid crashes.
    if googleSignIn.currentUser != nil {
      return googleSignIn.currentUser
    }
    return nil
  }

  public var currentUpgradableUser: UpgradableUser? {
    return anonymousAuth.currentUpgradableUser
  }

  /// Used to keep track of callbacks that should be invoked when sign(_:didSignInFor:withError:)
  /// is called. This seems like it would run into race conditions, but since GIDSignIn is a global,
  /// it's ok (when a callback is invoked, we don't care whose `signIn` invocation triggered the
  /// callback).
  private var userErrorCallbacks: [((_ user: GIDGoogleUser?, _ error: Error?) -> Void)] = []

  private func invokeUserErrorCallbacks(user: GIDGoogleUser?, error: Error?) {
    userErrorCallbacks.forEach { $0(user, error) }
    userErrorCallbacks.removeAll()
  }

  public func signInSilently(_ callback: @escaping (_ user: GIDGoogleUser?, _ error: Error?) -> Void) {
    if googleSignIn.hasAuthInKeychain() {
      userErrorCallbacks.append(callback)
      googleSignIn.signInSilently()
    } else {
      anonymousAuth.signInAnonymously { (_, error) in
        callback(nil, error)
      }
    }
  }

  public func signIn(_ callback: @escaping (_ user: GIDGoogleUser?, _ error: Error?) -> Void) {
    userErrorCallbacks.append(callback)
    googleSignIn.signIn()
  }

  public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
    defer {
      invokeUserErrorCallbacks(user: user, error: error)
    }
    guard error == nil else {
      // In the case of GIDSignIn failure, fall back to an anonymous user.
      anonymousAuth.signInAnonymously { (user, error) in
        if let error = error {
          print("Auth Error: Anonymous Sign-in failed. The app is not usable if anonymous login doesn't succeed. \(error)")
        } else {
          let description = user.flatMap(String.init(describing:)) ?? "(null)"
          print("Signed in anonymously with user: \(description)")
        }
      }
      return
    }

    invokeSignInSuccessCallbacks()

    guard let newUser = user else {
      return
    }

    let anonymousUser = anonymousAuth.currentUpgradableUser.flatMap { $0.isAnonymous ? $0 : nil }
    let credential = GoogleAuthProvider.credential(withIDToken: newUser.authentication.idToken,
                                                   accessToken: newUser.authentication.accessToken)

    anonymousAuth.signIn(withGoogleCredential: credential)

    // Link the anonymous user to the Google user.
    if let firebaseUser = anonymousUser,
      firebaseUser.providerID != GoogleAuthProviderID {
      firebaseUser.link(with: credential) { _, error in
        if let error = error {
          print("Error linking credentials: \(error)")
        } else {
          print("Successfully linked Google account")
        }
      }
    }
  }

  public func signOut() {
    googleSignIn.signOut()
    do {
      try anonymousAuth.signOutAnonymously()
    } catch let error {
      print("Error signing out: \(error)")
    }
    invokeSignOutCallbacks()
    if anonymousAuth.currentUpgradableUser == nil {
      anonymousAuth.signInAnonymously { (user, error) in
        print("User signed out manually. Falling back to anonymous user")
        let userDescription = user.flatMap(String.init(describing:)) ?? "nil"
        let errorDescription = error.flatMap(String.init(describing:)) ?? "nil"
        print("Anonymous login completed with user: \(userDescription), error: \(errorDescription)")
      }
    }
  }

  // MARK: - Callback handlers

  private class _VoidCallbackWrapper {
    /// The stored callback.
    let callback: () -> Void
    /// A weak pointer to the object associated with this callback.
    /// If the pointer becomes nil, the callback can be removed.
    weak var obj: AnyObject?

    init(_ obj: AnyObject, callback: @escaping () -> Void) {
      self.callback = callback
      self.obj = obj
    }
  }

  // These are NSMapTables only because we don't need Dictionary's copy-on-write or
  // hashable/equatable requirements, all we care about is pointer equality.
  private lazy var signInCallbackMap: NSMapTable = {
    return NSMapTable<_VoidCallbackWrapper, NSNumber>.strongToStrongObjects()
  }()
  private lazy var signOutCallbackMap: NSMapTable = {
    return NSMapTable<_VoidCallbackWrapper, NSNumber>.strongToStrongObjects()
  }()

  public func addGoogleSignInHandler(_ obj: AnyObject, handler: @escaping () -> Void) -> AnyObject {
    let wrapper = _VoidCallbackWrapper(obj, callback: handler)
    signInCallbackMap.setObject(true, forKey: wrapper)
    return wrapper
  }

  public func removeGoogleSignInHandler(_ obj: Any) {
    guard let wrapper = obj as? _VoidCallbackWrapper else { return }
    signInCallbackMap.removeObject(forKey: wrapper)
  }

  public func addGoogleSignOutHandler(_ obj: AnyObject, handler: @escaping () -> Void) -> AnyObject {
    let wrapper = _VoidCallbackWrapper(obj, callback: handler)
    signOutCallbackMap.setObject(true, forKey: wrapper)
    return wrapper
  }

  public func removeGoogleSignOutHandler(_ obj: Any) {
    guard let wrapper = obj as? _VoidCallbackWrapper else { return }
    signOutCallbackMap.removeObject(forKey: wrapper)
  }

  func invokeSignOutCallbacks() {
    var callbacksToRemove = [AnyObject]()
    for key in signOutCallbackMap.keyEnumerator() {
      guard let wrapper = key as? _VoidCallbackWrapper else { continue }
      if wrapper.obj == nil {
        callbacksToRemove.append(wrapper)
      } else {
        wrapper.callback()
      }
    }
    callbacksToRemove.forEach { self.removeGoogleSignOutHandler($0) }
  }

  func invokeSignInSuccessCallbacks() {
    var callbacksToRemove = [AnyObject]()
    for key in signInCallbackMap.keyEnumerator() {
      guard let wrapper = key as? _VoidCallbackWrapper else { continue }
      if wrapper.obj == nil {
        callbacksToRemove.append(wrapper)
      } else {
        wrapper.callback()
      }
    }
    callbacksToRemove.forEach { self.removeGoogleSignInHandler($0) }
  }

  private let anonymousAuthCallbacks =
      NSMapTable<_UserInfoCallbackWrapper, NSNumber>.strongToStrongObjects()

  private class _UserInfoCallbackWrapper {
    let callback: (UserInfo?) -> Void

    init(_ callback: @escaping (UserInfo?) -> Void) {
      self.callback = callback
    }
  }

  public func addAnonymousAuthStateHandler(_ handler: @escaping (UserInfo?) -> Void) -> Any {
    let wrapper = _UserInfoCallbackWrapper(handler)
    anonymousAuthCallbacks.setObject(true as NSNumber, forKey: wrapper)
    observeAnonymousAuthChangesIfNecessary()
    return wrapper
  }

  public func removeAnonymousAuthStateHandler(_ handler: Any) {
    guard let handler = handler as? _UserInfoCallbackWrapper else { return }
    anonymousAuthCallbacks.removeObject(forKey: handler)
    stopObservingAnonymousAuthChangesIfNecessary()
  }

  private func invokeAnonymousAuthStateHandlers(user: UserInfo?) {
    for key in anonymousAuthCallbacks.keyEnumerator() {
      guard let wrapper = key as? _UserInfoCallbackWrapper else { continue }
      wrapper.callback(user)
    }
  }

  private var anonymousAuthStateHandle: Any?

  private func observeAnonymousAuthChangesIfNecessary() {
    guard anonymousAuthStateHandle == nil else { return }
    guard anonymousAuthCallbacks.count > 0 else { return }
    let handle = anonymousAuth.addAnonymousAuthStateListener { [weak self] user in
      guard let self = self else { return }
      self.invokeAnonymousAuthStateHandlers(user: user)
    }
    anonymousAuthStateHandle = handle
  }

  private func stopObservingAnonymousAuthChangesIfNecessary() {
    guard anonymousAuthCallbacks.count == 0 else { return }
    guard let handle = anonymousAuthStateHandle else { return }
    anonymousAuth.removeAnonymousAuthStateListener(handle)
  }

}

extension SignIn: GIDSignInUIDelegate {
  @objc public func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
    if var topController = UIApplication.shared.keyWindow?.rootViewController {
      while let presentedViewController = topController.presentedViewController {
        topController = presentedViewController
      }
      topController.present(viewController, animated: true, completion: nil)
    }
  }

  @objc public func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
    viewController.dismiss(animated: true, completion: nil)
  }
}

extension GIDGoogleUser: UserInfo {

  public var providerID: String {
    return "google.com"
  }

  public var uid: String {
    return userID
  }

  public var displayName: String? {
    return profile?.name
  }

  public var photoURL: URL? {
    return profile?.imageURL(withDimension: 72)
  }

  public var email: String? {
    return profile?.email
  }

  public var phoneNumber: String? {
    return nil
  }

}

// MARK: - Huge wall around FirebaseAuth so we can test our code without other effects

/// Any type that returns the current user. This type exists to minimize our
/// dependency on FirebaseAuth, which is difficult to stub and likes to execute
/// code in the background.
public protocol CurrentUserProvider {

  var currentUserInfo: UserInfo? { get }

}

public protocol UpgradableUser: UserInfo {

  var isAnonymous: Bool { get }

  func link(with credential: AuthCredential,
            completion: @escaping (AuthDataResult?, Error?) -> Void)

  func fetchIDToken(_ completion: @escaping (String?, Error?) -> Void)

}

public protocol UpgradableUserUpdateProvider {

  var currentUpgradableUser: UpgradableUser? { get }

  func signIn(_ completion: @escaping (UpgradableUser?, Error?) -> Void)

  func addAnonymousAuthStateListener(_ listener: @escaping (UserInfo?) -> Void) -> Any

  func removeAnonymousAuthStateListener(_ handle: Any)

  func signIn(withGoogleCredential credential: AuthCredential)

  func signInAnonymously(_ callback: @escaping (UpgradableUser?, Error?) -> Void)

  func signOutAnonymously() throws

}

extension FirebaseAuth.Auth: CurrentUserProvider {
  public var currentUserInfo: UserInfo? {
    return currentUser
  }
}

extension FirebaseAuth.Auth: UpgradableUserUpdateProvider {

  public var currentUpgradableUser: UpgradableUser? {
    return currentUser
  }

  public func signIn(_ completion: @escaping (UpgradableUser?, Error?) -> Void) {
    signInAnonymously { (result, error) in
      completion(result?.user, error)
    }
  }

  public func addAnonymousAuthStateListener(_ listener: @escaping (UserInfo?) -> Void) -> Any {
    return addStateDidChangeListener { (_, user) in
      listener(user)
    }
  }

  public func removeAnonymousAuthStateListener(_ handle: Any) {
    guard let handle = handle as? AuthStateDidChangeListenerHandle else { return }
    removeStateDidChangeListener(handle)
  }

  public func signIn(withGoogleCredential credential: AuthCredential) {
    signInAndRetrieveData(with: credential) { (_, error) in
      if let error = error {
        print("Failed to authenticate with Firebase using Google credential: \(error)")
      } else {
        print("Authenticated with Firebase via Google")
      }
    }
  }

  public func signInAnonymously(_ callback: @escaping (UpgradableUser?, Error?) -> Void) {
    signInAnonymously(completion: { (dataResult, error) in
      callback(dataResult?.user, error)
    })
  }

  public func signOutAnonymously() throws {
    try signOut()
  }

}

extension FirebaseAuth.User: UpgradableUser {

  public func link(with credential: AuthCredential,
                   completion: @escaping (AuthDataResult?, Error?) -> Void) {
    linkAndRetrieveData(with: credential, completion: completion)
  }

  public func fetchIDToken(_ completion: @escaping (String?, Error?) -> Void) {
    getIDToken(completion: completion)
  }

}
