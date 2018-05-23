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
@testable import IOsched

class FirestoreReservationServiceTest: XCTestCase {

  let sessionID = "\(type(of: self))_sessionID"

  var store: Firestore!
  var reservationService: FirestoreReservationService!
  var currentUserProvider: TestAnonymousAuth!

  override func setUp() {
    store = Firestore.firestore()
    store.disableNetwork { (error) in
      if let error = error {
        fatalError("Failed to disable network in FirestoreTypesTest: \(error)")
      }
    }

    currentUserProvider = TestAnonymousAuth()
    reservationService = FirestoreReservationService(sessionID: sessionID,
                                                     currentUserProvider: currentUserProvider)
  }

  override func tearDown() {
    reservationService = nil
  }

  func testItDefaultsToNoReservationWhenInitialized() {
    XCTAssert(reservationService.reservationStatus == .none)
    XCTAssert(reservationService.seatsAvailable == false)
  }

  func testItUpdatesWithSeatAvailabilityFromFirestore() {
    let seatsRef = store.scheduleDetail(scheduleID: sessionID)

    let callbackInvoked = XCTestExpectation(description: "callback invoked")
    _ = reservationService.onSeatAvailabilityUpdate { [weak self] (status) in
      guard let self = self else {
        XCTFail("self was unexpectedly nil"); return
      }
      callbackInvoked.fulfill()
      XCTAssertFalse(status)
      XCTAssertEqual(self.reservationService.seatsAvailable, status)
    }

    seatsRef.setData(["sessionFull": true])
    wait(for: [callbackInvoked], timeout: 2)
  }

  func testItUpdatesWithReservationStatusFromFirestore() {
    guard let user = currentUserProvider.currentUserInfo else {
      XCTFail("Unable to get userID"); return
    }

    let userEventRef = store.userEvent(for: user, withSessionID: self.sessionID)

    let callbackInvoked = XCTestExpectation(description: "callback invoked")
    _ = reservationService.onReservationStatusUpdate { [weak self] (status) in
      callbackInvoked.fulfill()
      guard let self = self else {
        XCTFail("self was unexpectedly nil"); return
      }
      XCTAssertEqual(status, .none)
      XCTAssertEqual(status, self.reservationService.reservationStatus)
    }

    userEventRef.setData(["reservationStatus": "RESERVED"])
    wait(for: [callbackInvoked], timeout: 2)
  }

  func testItUpdatesWithReservationResultFromFirestore() {
    guard let user = currentUserProvider.currentUserInfo else {
      XCTFail("Unable to get userID"); return
    }

    let userEventRef = store.userEvent(for: user, withSessionID: self.sessionID)

    let callbackInvoked = XCTestExpectation(description: "callback invoked")
    _ = reservationService.onReservationResultUpdate { (result) in
      callbackInvoked.fulfill()
      XCTAssertEqual(result, .waitlisted)
    }

    userEventRef.setData(
      [
        "reservationResult": [
          "requestResult": "RESERVE_WAITLISTED"
        ]
      ]
    )

    wait(for: [callbackInvoked], timeout: 2)
  }

}

class TestAnonymousAuth: CurrentUserProvider {

  private(set) lazy var currentUserInfo: UserInfo? = {
    return TestUserInfo()
  }()

}
