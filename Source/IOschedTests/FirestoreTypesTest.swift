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
import FirebaseFirestore
import FirebaseAuth

/// The tests in this class are all kind of true-by-definition, but that's just a
/// consequence of testing one-liner functions more than anything else. The tests
/// check for typos, that's all. Firestore is responsible for actually downloading
/// data, and that code is itself tested, though not in this repo.
class FirestoreTypesTest: XCTestCase {

  let rootPath = "google_io_events/2019"

  var store: Firestore!

  override func setUp() {
    store = Firestore.firestore()
    store.disableNetwork { (error) in
      if let error = error {
        fatalError("Failed to disable network in FirestoreTypesTest: \(error)")
      }
    }
  }

  override func tearDown() {
  }

  func testItFetchesCorrectCollections() {
    var collection = store.users
    XCTAssertEqual(collection.path, "\(rootPath)/users")
    collection = store.scheduleSummaries
    XCTAssertEqual(collection.path, "\(rootPath)/scheduleSummary")
    collection = store.scheduleDetails
    XCTAssertEqual(collection.path, "\(rootPath)/scheduleDetail")
    collection = store.events
    XCTAssertEqual(collection.path, "\(rootPath)/events")
  }

  func testItFetchesScheduleDetails() {
    let detail = store.scheduleDetail(scheduleID: "10")
    XCTAssertEqual(detail.documentID, "10")
  }

  func testItFetchesUserData() {
    let userInfo = TestUserInfo()
    let user = store.userDocument(for: userInfo)
    XCTAssertEqual(user.documentID, userInfo.uid)
  }

  func testItSetsLastVisitedDate() {
    let closureInvoked = XCTestExpectation(description: "callback invoked")
    let userInfo = TestUserInfo()
    store.setLastVisitedDate(for: userInfo)
    store.userDocument(for: userInfo).getDocument { (snapshot, error) in
      closureInvoked.fulfill()
      if let error = error {
        XCTFail("Error fetching last visit date: \(error)")
      }
      guard let snapshot = snapshot else {
        XCTFail("Snapshot was unexpectedly nil")
        return
      }
      let timestamp = snapshot.get("lastUsage", serverTimestampBehavior: .estimate)
      XCTAssertNotNil(timestamp) // Timestamp correctness is not something this test
                                 // is responsible for.
    }
  }

  func testItReturnsTheCorrectQueuePerUser() {
    let userInfo = TestUserInfo()
    let queue = store.reservationQueue(for: userInfo)
    XCTAssertEqual(queue.path, "\(rootPath)/queue/\(userInfo.uid)")
  }

  func testItWritesTheFCMTokenAtTheCorrectPath() {
    let closuresInvoked = XCTestExpectation(description: "callbacks invoked")
    let userInfo = TestUserInfo()
    let fakeFCMToken = "fcmToken_aaaaaa"
    store.setToken(fakeFCMToken, for: userInfo)

    let expectedPath = "\(rootPath)/users/\(userInfo.uid)/fcmTokens/\(fakeFCMToken)"
    store.document(expectedPath).getDocument { (snapshot, error) in
      if let error = error {
        XCTFail("Error fetching last visit date: \(error)")
      }
      guard let snapshot = snapshot else {
        XCTFail("Snapshot was unexpectedly nil")
        return
      }
      let value = snapshot["lastVisit"]
      guard let millis = value as? Int else {
        XCTFail("Expected nonnull value of integer type, instead got \(String(describing: value))")
        return
      }
      XCTAssert(millis > 0) // value correctness isn't important

      self.store.removeToken(fakeFCMToken, for: userInfo)
      self.store.document(expectedPath).getDocument { (snapshot, _) in
        closuresInvoked.fulfill()
        XCTAssertNil(snapshot)
      }
    }
    wait(for: [closuresInvoked], timeout: 4)
  }

}
