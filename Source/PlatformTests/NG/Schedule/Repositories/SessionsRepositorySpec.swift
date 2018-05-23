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
import Quick
import Nimble
import FirebaseFirestore

@testable import Domain
@testable import Platform

class SessionsRepositorySpec: QuickSpec {

  override func spec() {
    describe("SessionsRepository") {
      var repository: SessionsRepository!
      beforeEach {
        Firestore.firestore().disableNetwork(completion: nil)
        repository = DefaultSessionsRepository(datasource: MRUScheduleDatasource())
        print(repository.sessions)
      }

      // TODO: These tests are broken.
//      it("fetches sessions from a data source") {
//        let sessions = repository.sessions
//
//        expect(sessions.count) > 0
//      }
//
//      it("can access sessions by their ID") {
//        let sessions = repository.sessions
//        let session1 = sessions[0]
//
//        let session2 = repository[session1.id]
//        let session3 = repository.session(byId: session1.id)
//
//        expect(session1) == session2
//        expect(session1) == session3
//      }

    }
  }
}
