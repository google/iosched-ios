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
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
@testable import IOsched

class RemoteReservationDataSourceTest: XCTestCase {

  var dataSource: RemoteReservationDataSource!
  var signIn: TestSignIn!
  var firestore: Firestore!

  override func setUp() {
    signIn = TestSignIn()
    dataSource = RemoteReservationDataSource(firestore: Firestore.firestore(),
                                             signIn: signIn)
    firestore = Firestore.firestore()
  }

  override func tearDown() {
    dataSource.stopObservingUpdates()
  }

  func testItFetchesReservationsFromFirestore() {
    let callbackInvokedWithReservations =
        XCTestExpectation(description: "Callback was invoked with reservations")

    signIn.signInSilently { (_, _) in }

    let session1 = "\(type(of: self))_session1"
    let session2 = "\(type(of: self))_session2"

    firestore.userEvents(for: signIn.currentUpgradableUser!).document(session1).setData([
      "reservationStatus": "RESERVED",
      "reservationResult": ["timestamp": 9999999999]
    ])
    firestore.userEvents(for: signIn.currentUpgradableUser!).document(session2).setData([
      "reservationStatus": "NONE",
      "reservationResult": ["timestamp": 9999999999]
    ])

    dataSource.observeReservationUpdates { [weak self] (sessions, error) in
      guard let self = self else { return }
      if let error = error {
        XCTFail("Expected nonnull error: \(error)")
      }
      guard sessions.count == 2 else {
        return
      }
      XCTAssertEqual(sessions[1].id, session1)
      XCTAssertEqual(sessions[1].status, .reserved)
      XCTAssertEqual(sessions[0].id, session2)
      XCTAssertEqual(sessions[0].status, .none)

      callbackInvokedWithReservations.fulfill()

      let dataSource = self.dataSource!
      XCTAssertEqual(dataSource.reservationStatus(for: session1), .reserved)
      XCTAssertEqual(dataSource.reservationStatus(for: session2), .none)

      let reservedSession1 = ReservedSession(id: session1,
                                             status: .reserved)
      let reservedSession2 = ReservedSession(id: session2,
                                             status: .none)
      XCTAssertTrue(dataSource.reservedSessions.contains(reservedSession1))
      XCTAssertTrue(dataSource.reservedSessions.contains(reservedSession2))
    }

    wait(for: [callbackInvokedWithReservations], timeout: 2)
  }

  func testItRestartsFirestoreQueryOnReauth() {
    let callbackInvokedOnReauth = XCTestExpectation(description: "Callback invoked on reauth")

    signIn.signInSilently { (_, _) in }

    dataSource.observeReservationUpdates { (_, _) in
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

    dataSource.observeReservationUpdates { (_, _) in
      callbackThatShouldNotBeInvoked.fulfill()
    }
    dataSource.stopObservingUpdates()

    signIn.signOut()
    signIn.signIn { (_, _) in }

    wait(for: [callbackThatShouldNotBeInvoked], timeout: 2)
  }

  func testItPostsNotificationOnUpdate() {
    let expectation = XCTestExpectation(description: "Update notification")
    let observerHandle = NotificationCenter.default
      .addObserver(forName: .reservationUpdate, object: nil, queue: nil) { _ in
        expectation.fulfill()
    }

    dataSource.observeReservationUpdates { [unowned self] (_, _) in
      self.dataSource.stopObservingUpdates()
    }

    wait(for: [expectation], timeout: 2)
    NotificationCenter.default.removeObserver(observerHandle)
  }

}
