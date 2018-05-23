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

import XCTest
import GoogleSignIn
import FirebaseAuth

@testable import IOsched

class SignInTests: XCTestCase {

  var anonymousAuth: TestFirebaseAuth!
  var googleSignIn: TestGoogleSignIn!
  var signIn: SignIn!

  override func setUp() {
    googleSignIn = TestGoogleSignIn()
    anonymousAuth = TestFirebaseAuth()
    signIn = SignIn(signIn: googleSignIn, anonymousAuth: anonymousAuth)
  }

  override func tearDown() {
    googleSignIn = nil
    signIn = nil
    anonymousAuth.anonymousStateListener = nil
    anonymousAuth = nil
  }

  func testItDoesntCrashWhenAccessingCurrentUser() {
    XCTAssertNil(signIn.currentUser)
  }

  func testItInvokesGIDSignInCallbacks() {
    let signInCallback = XCTestExpectation(description: "Sign in callback expectation")
    let signInSilentlyCallback =
        XCTestExpectation(description: "Sign in silently callback expectation")

    signIn.signIn { (user, error) in
      XCTAssertNil(user)
      XCTAssertNil(error)
      signInCallback.fulfill()
    }

    signIn.signInSilently { (user, error) in
      XCTAssertNil(user)
      XCTAssertNil(error)
      signInSilentlyCallback.fulfill()
    }

    wait(for: [signInCallback, signInSilentlyCallback], timeout: 1)
  }

  func testItCallsHandlersOnSignInSignOut() {
    let signInCallback = XCTestExpectation(description: "Sign in handler callback expectation")
    let signOutCallback = XCTestExpectation(description: "Sign out handler callback expectation")

    signInCallback.assertForOverFulfill = true
    signOutCallback.assertForOverFulfill = true

    let handler1 = signIn.addGoogleSignInHandler(self) {
      signInCallback.fulfill()
    }
    let handler2 = signIn.addGoogleSignOutHandler(self) {
      signOutCallback.fulfill()
    }

    signIn.signIn { (_, _) in }
    signIn.signOut()

    signIn.removeGoogleSignInHandler(handler1)
    signIn.removeGoogleSignOutHandler(handler2)

    // These calls are to make sure the expectations aren't overfulfilled.
    signIn.signIn { (_, _) in }
    signIn.signOut()

    wait(for: [signInCallback, signOutCallback], timeout: 1)
  }

  func testItCallsAnonymousHandlersOnSignInAndSignOut() {
    let expectation = XCTestExpectation(description: "Anonymous login callback invoked expectation")
    expectation.expectedFulfillmentCount = 2

    let handler = signIn.addAnonymousAuthStateHandler { user in
      expectation.fulfill()
      if self.anonymousAuth.isSignedIn {
        XCTAssertNotNil(user)
      } else {
        XCTAssertNil(user)
      }
    }

    anonymousAuth.signInAnonymously { (_, _) in
      // do nothing
    }

    try? anonymousAuth.signOutAnonymously()

    wait(for: [expectation], timeout: 1)
    anonymousAuth.removeAnonymousAuthStateListener(handler)
  }

}

class TestGoogleSignIn: GIDSignIn {

  public var hasKeychainCredentials: Bool = true

  override var currentUser: GIDGoogleUser! {
    return nil
  }

  override func signIn() {
    delegate.sign(self, didSignInFor: nil, withError: nil)
  }

  override func signInSilently() {
    delegate.sign(self, didSignInFor: nil, withError: nil)
  }

  override func hasAuthInKeychain() -> Bool {
    return hasKeychainCredentials
  }

}
