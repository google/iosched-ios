//
//  Copyright (c) 2019 Google Inc.
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

@testable import IOsched
import FirebaseAuth
import GoogleSignIn

private func generateSpeaker(fromConstant constant: Int) -> Speaker {
  return Speaker(
    id: "\(constant)",
    name: "Speaker \(constant)",
    bio: "The \(constant)th speaker",
    company: "Alphabats",
    thumbnailURL: nil,
    twitterURL: nil,
    linkedinURL: nil,
    githubURL: nil,
    websiteURL: nil
  )
}

private func generateSession(fromConstant constant: Int) -> Session {
  func randomSpeakers() -> [Speaker] {
    let size = Int.random(in: 0 ..< TestData.speakers.count)
    let maxIndex = TestData.speakers.count - size
    let startIndex = Int.random(in: 0 ... maxIndex)
    let endIndex = startIndex + size
    return Array(TestData.speakers[startIndex ..< endIndex])
  }
  func randomTags() -> [EventTag] {
    let difficulty = EventTag.allLevels.randomElement()!
    let topic = EventTag.allTopics.randomElement()!
    let type = EventTag.allTypes.randomElement()!
    return [difficulty, topic, type]
  }

  return Session(id: "session\(constant)",
                 url: URL(string: "https://localhost:8000/\(constant)")!,
                 title: "Session \(constant)",
                 detail: "Welcome to session \(constant)!",
                 startTimestamp: Date(),
                 endTimestamp: Date(timeIntervalSinceNow: 3600),
                 youtubeURL: nil,
                 tags: randomTags(),
                 mainTopic: nil,
                 roomId: "room\(constant)",
                 roomName: "Room \(constant)",
                 speakers: randomSpeakers())
}

enum TestData {

  static let speakers: [Speaker] = {
    return (0 ..< 20).map(generateSpeaker(fromConstant:))
  }()

  static let sessions: [Session] = {
    return (0 ..< 100).map(generateSession(fromConstant:))
  }()

}

class TestSessionsDataSource: LazyReadonlySessionsDataSource {

  var sessions: [Session] {
    return TestData.sessions
  }

  private let sessionsMap: [String: Session]

  init() {
    var map = [String: Session]()
    for session in TestData.sessions {
      map[session.id] = session
    }
    self.sessionsMap = map
  }

  subscript(id: String) -> Session? {
    return sessionsMap[id]
  }

  func randomSessionId() -> String? {
    return sessions.randomElement()?.id
  }

  func update() {
    // do nothing
  }

}

class InMemoryUserState: PersistentUserState {

  var isUserRegistered: Bool = true

  var shouldDisplayOnboarding: Bool = false

  func isOnboardingCompleted() -> Bool {
    return !shouldDisplayOnboarding
  }

  func setOnboardingCompleted(_ completed: Bool) {
    shouldDisplayOnboarding = !completed
  }

  var isUserSignedIn: Bool = false

  var signedInUser: IOsched.User?

  func signOut() {
    // do nothing
  }

  var shouldDisplayEventsInPDT: Bool = false

  var isNotificationsEnabled: Bool = true

  var isAnalyticsEnabled: Bool = true

  func setShouldDisplayEventsInPDT(_ value: Bool) {
    shouldDisplayEventsInPDT = value
  }

  func setNotificationsEnabled(_ value: Bool) {
    isNotificationsEnabled = value
  }

  func setAnalyticsEnabled(_ value: Bool) {
    isAnalyticsEnabled = value
  }

  func registerForFCM() {
    // do nothing
  }

  func updateUserRegistrationStatus() {
    // do nothing
  }

  private var feedbackMap: [String: Bool] = [:]

  func didSubmitFeedback(forSessionWithID id: String) -> Bool {
    return feedbackMap[id] ?? false
  }

  func setFeedbackSubmitted(_ submitted: Bool, forSessionWithID id: String) {
    feedbackMap[id] = submitted
  }

}

class TestFirebaseAuth: UpgradableUserUpdateProvider {

  var isSignedIn: Bool = false {
    didSet {
      if isSignedIn != oldValue {
        anonymousStateListener?(currentUpgradableUser)
      }
    }
  }

  private var testUser = TestUpgradableUser()

  var anonymousStateListener: ((UserInfo?) -> Void)?

  var currentUpgradableUser: UpgradableUser? {
    return isSignedIn ? testUser : nil
  }

  func signIn(_ completion: @escaping (UpgradableUser?, Error?) -> Void) {
    isSignedIn = true
    completion(currentUpgradableUser, nil)
  }

  func addAnonymousAuthStateListener(_ listener: @escaping (UserInfo?) -> Void) -> Any {
    self.anonymousStateListener = listener
    return self
  }

  func removeAnonymousAuthStateListener(_ handle: Any) {
    self.anonymousStateListener = nil
  }

  func signIn(withGoogleCredential credential: AuthCredential) {
    isSignedIn = true
  }

  func signInAnonymously(_ callback: @escaping (UpgradableUser?, Error?) -> Void) {
    isSignedIn = true
  }

  func signOutAnonymously() throws {
    isSignedIn = false
  }

}

class TestUpgradableUser: NSObject, UpgradableUser {

  private let user = TestUserInfo()

  var isAnonymous: Bool = true

  func link(with credential: AuthCredential, completion: @escaping (AuthDataResult?, Error?) -> Void) {
    completion(nil, nil)
  }

  func fetchIDToken(_ completion: @escaping (String?, Error?) -> Void) {
    completion("idToken", nil)
  }

  var providerID: String {
    return "Test"
  }

  var uid: String {
    return user.uid
  }

  var displayName: String? {
    return user.displayName
  }

  var photoURL: URL? {
    return user.photoURL
  }

  var email: String? {
    return user.email
  }

  var phoneNumber: String? {
    return user.phoneNumber
  }

}

@objc class TestUserInfo: NSObject, UserInfo {

  public override init() {
    super.init()
  }

  var providerID: String {
    return "providerID"
  }

  let uid: String = "\(Int.random(in: 0 ..< 99999999))"

  var displayName: String? {
    return "displayName"
  }

  var photoURL: URL? {
    return nil
  }

  var email: String? {
    return "test@example.com"
  }

  var phoneNumber: String? {
    return nil
  }

}

class TestSignIn: SignInInterface {

  var currentUpgradableUser: UpgradableUser? {
    return loggedIn ? upgradableUser : nil
  }

  private let user = TestUserInfo()
  private let upgradableUser = TestUpgradableUser()

  var loggedIn = true

  var currentUser: UserInfo? {
    return loggedIn ? user : nil
  }

  func signInSilently(_ callback: @escaping (GIDGoogleUser?, Error?) -> Void) {
    loggedIn = true
    anonymousLoginHandler?(currentUser)
    loginHandler?()
    callback(nil, nil)
  }

  func signIn(_ callback: @escaping (GIDGoogleUser?, Error?) -> Void) {
    loggedIn = true
    anonymousLoginHandler?(currentUser)
    loginHandler?()
    callback(nil, nil)
  }

  func signOut() {
    loggedIn = false
    anonymousLoginHandler?(currentUser)
    logoutHandler?()
  }

  var loginHandler: (() -> Void)?
  var logoutHandler: (() -> Void)?
  var anonymousLoginHandler: ((UserInfo?) -> Void)?

  func addGoogleSignInHandler(_ obj: AnyObject, handler: @escaping () -> Void) -> AnyObject {
    loginHandler = handler
    return self
  }

  func removeGoogleSignInHandler(_ obj: Any) {
    loginHandler = nil
  }

  func addGoogleSignOutHandler(_ obj: AnyObject, handler: @escaping () -> Void) -> AnyObject {
    logoutHandler = handler
    return self
  }

  func removeGoogleSignOutHandler(_ obj: Any) {
    logoutHandler = nil
  }

  func addAnonymousAuthStateHandler(_ handler: @escaping (UserInfo?) -> Void) -> Any {
    anonymousLoginHandler = handler
    return self
  }

  func removeAnonymousAuthStateHandler(_ handler: Any) {
    anonymousLoginHandler = nil
  }

}
