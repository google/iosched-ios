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
@testable import IOsched
import FirebaseFirestore

class RemoteBookmarkDataSourceTests: XCTestCase {

  var notificationHandler: (() -> Void)!
  var dataSource: RemoteBookmarkDataSource!

  var signIn: TestSignIn!
  var firestore: Firestore!

  var observerHandle: Any?

  override func setUp() {
    firestore = Firestore.firestore()
    firestore.disableNetwork { (error) in
      if let error = error {
        fatalError("Failed to disable network in FirestoreTypesTest: \(error)")
      }
    }

    signIn = TestSignIn()
    signIn.signIn { (_, _) in }

    dataSource = RemoteBookmarkDataSource(firestore: firestore, signIn: signIn)
  }

  override func tearDown() {
    if let handle = observerHandle {
      NotificationCenter.default.removeObserver(handle)
    }
  }

  func testItFetchesBookmarksFromFirestore() {
    let callbackInvokedWithBookmarks =
        XCTestExpectation(description: "Callback was invoked with bookmarks")

    signIn.signInSilently { (_, _) in }

    let session1 = "\(type(of: self))_session1"
    let session2 = "\(type(of: self))_session2"

    firestore.userEvents(for: signIn.currentUpgradableUser!).document(session1).setData([
      "eventId": session1,
      "isStarred": true
    ])
    firestore.userEvents(for: signIn.currentUpgradableUser!).document(session2).setData([
      "eventId": session2,
      "isStarred": false
    ])

    dataSource.syncBookmarks { [weak self] (bookmarks) in
      guard let self = self else { return }
      guard bookmarks.count == 1 else { return }
      XCTAssertEqual(bookmarks.first?.id, session1)

      callbackInvokedWithBookmarks.fulfill()

      let dataSource = self.dataSource!
      XCTAssertTrue(dataSource.isBookmarked(sessionID: session1))
      XCTAssertFalse(dataSource.isBookmarked(sessionID: session2))
      XCTAssertFalse(dataSource.isBookmarked(sessionID: "session3"))
    }

    wait(for: [callbackInvokedWithBookmarks], timeout: 2)
  }

  func testItRestartsFirestoreQueryOnReauth() {
    let callbackInvokedOnReauth = XCTestExpectation(description: "Callback invoked on reauth")

    signIn.signInSilently { (_, _) in }

    dataSource.syncBookmarks { _ in
      callbackInvokedOnReauth.fulfill()
    }

    signIn.signOut()
    signIn.signIn { (_, _) in }

    wait(for: [callbackInvokedOnReauth], timeout: 2)
  }

  func testItDoesNotRestartFirestoreQueryOnReauthIfStopObservingHasBeenCalled() {
    let callbackThatShouldNotBeInvoked =
      XCTestExpectation(description: "Callback invoked on initial observe and reauth")
    callbackThatShouldNotBeInvoked.isInverted = true // fail if this is invoked at all.

    signIn.signInSilently { (_, _) in }

    dataSource.syncBookmarks { _ in
      callbackThatShouldNotBeInvoked.fulfill()
    }
    dataSource.stopSyncingBookmarks()

    signIn.signOut()
    signIn.signIn { (_, _) in }

    wait(for: [callbackThatShouldNotBeInvoked], timeout: 2)
  }

  func testItPostsNotificationOnUpdate() {
    let expectation = XCTestExpectation(description: "Update notification")
    observerHandle = NotificationCenter.default
      .addObserver(forName: .bookmarkUpdate, object: nil, queue: nil) { _ in
        expectation.fulfill()
    }

    dataSource.syncBookmarks { [unowned self] (_) in
      self.dataSource.stopSyncingBookmarks()
    }

    wait(for: [expectation], timeout: 2)
  }

}
