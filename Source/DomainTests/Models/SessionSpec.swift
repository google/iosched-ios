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

@testable import IOsched

class SessionSpec: QuickSpec {

  private enum Times {
    static let startTime1 = "17-05-2016 15:00"
    static let endTime1 = "17-05-2016 16:00"
    static let startTime2 = "18-05-2016 9:00"
    static let endTime2 = "18-05-2016 10:00"

  }

  override func spec() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"

    describe("A Session") {
      it("is equal to another session if their ids match") {
        let startTime1 = dateFormatter.date(from: Times.startTime1)!
        let endTime1 = dateFormatter.date(from: Times.endTime1)!
        let startTime2 = dateFormatter.date(from: Times.startTime2)!
        let endTime2 = dateFormatter.date(from: Times.endTime2)!

        let session1 = Session(
          id: "DEADBEEF-17",
          url: URL(string: "http://events.google.com/io2017")!,
          title: "Speechless",
          detail: "Speechless is back at I/O for the third year in a row!",
          startTimestamp: startTime1,
          endTimestamp: endTime1,
          youtubeURL: nil,
          tags: [EventTag.sessions, EventTag.misc],
          mainTopic: nil,
          roomId: "20d7a6c1-c208-e611-a517-00155d5066d7",
          roomName: "",
          speakers: [])

        let session2 = Session(
          id: "DEADBEEF-17",
          url: URL(string: "http://events.google.com/io2017")!,
          title: "Speechless",
          detail: "Speechless is back at I/O for the third year in a row!",
          startTimestamp: startTime1,
          endTimestamp: endTime1,
          youtubeURL: nil,
          tags: [EventTag.sessions, EventTag.misc],
          mainTopic: nil,
          roomId: "20d7a6c1-c208-e611-a517-00155d5066d7",
          roomName: "",
          speakers: [])

        let session3 = Session(
          id: "DEADBEEF-19",
          url: URL(string: "http://events.google.com/io2017")!,
          title: "Speechless",
          detail: "Speechless is back at I/O for the third year in a row!",
          startTimestamp: startTime2,
          endTimestamp: endTime2,
          youtubeURL: nil,
          tags: [EventTag.sessions, EventTag.misc],
          mainTopic: nil,
          roomId: "20d7a6c1-c208-e611-a517-00155d5066d7",
          roomName: "",
          speakers: [])

        expect(session1) == session2
        expect(session1) != session3
      }
    }
  }

}
