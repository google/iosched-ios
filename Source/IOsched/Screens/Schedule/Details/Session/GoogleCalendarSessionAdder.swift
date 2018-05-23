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

import Contacts
import GoogleAPIClientForREST
import GoogleSignIn

class GoogleCalendarSessionAdder {

  static let errorDomain = "com.google.iosched.calendar.errorDomain"

  static let failureMessage =
    NSLocalizedString("Could not add event to calendar: Insufficient permissions.",
                        comment: "Localized failure reason when attempting to write to the user's calendar")

  private static var shorelineAmphitheatre: String {
    // iOS provides no utilities for formatting/localizing addresses outside of
    // address book / contacts, but those are undesirable because they add
    // newlines instead of commas.
    return "Shoreline Amphitheatre, Mountain View, CA 94043"
  }

  private static let calendarService: GTLRCalendarService = {
    let service = GTLRCalendarService()
    service.shouldFetchNextPages = true
    service.isRetryEnabled = true
    return service
  }()

  private static func eventFromSession(_ session: Session) -> GTLRCalendar_Event {
    let event = GTLRCalendar_Event()

    let startTime = GTLRDateTime(date: session.startTimestamp)
    let endTime = GTLRDateTime(date: session.endTimestamp)
    event.start = GTLRCalendar_EventDateTime()
    event.end = GTLRCalendar_EventDateTime()
    event.start?.dateTime = startTime
    event.end?.dateTime = endTime
    event.location = shorelineAmphitheatre

    event.summary = session.title
    let compositeDescription = session.roomName + "\n\n" + session.detail
    event.descriptionProperty = compositeDescription
    return event
  }

  static func addSessionToCalendar(_ session: Session, completion: @escaping (Error?) -> Void) {
    let event = eventFromSession(session)

    let query = GTLRCalendarQuery_CalendarListList.query()
    query.minAccessRole = kGTLRCalendarMinAccessRoleWriter

    func nsError(failureReason: String) -> NSError {
      return NSError(domain: errorDomain,
                     code: -999,
                     userInfo: [NSLocalizedDescriptionKey: failureReason])
    }

    guard let user = GIDSignIn.sharedInstance()?.currentUser,
      let authorizor = user.authentication else {
        let error = nsError(failureReason: failureMessage)
        completion(error)
        return
    }

    calendarService.authorizer = authorizor.fetcherAuthorizer()

    guard let calendarID = user.email else {
      let error = nsError(failureReason: failureMessage)
      completion(error)
      return
    }

    let insertQuery = GTLRCalendarQuery_EventsInsert.query(withObject: event,
                                                           calendarId: calendarID)

    calendarService.executeQuery(insertQuery, completionHandler: { (_, _, error) in
      guard error == nil else {
        completion(error)
        return
      }
      completion(nil)
    })
  }

}
