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

import Foundation

public struct Moment {

  enum CTA: String {
    case viewLivestream = "LIVE_STREAM"
    case viewMap = "MAP_LOCATION"
  }

  let attendeeRequired: Bool
  let cta: CTA?
  let displayDate: String // Ignored. Using Date formatter instead.
  let startTime: Date
  let endTime: Date
  let featureID: String?
  let featureName: String?
  let imageURL: URL
  let imageURLDarkTheme: URL
  let streamURL: URL?
  let textColor: String
  let timeVisible: Bool
  let title: String

  var formattedDateInterval: String {
    return Moment.dateIntervalFormatter.string(from: startTime, to: endTime)
  }

  var accessibilityLabel: String? {
    switch self {
    case .keynote:
      return NSLocalizedString("Watch the Google I/O keynote.",
                               comment: "Accessibility label for keynote moment")
    case .developerKeynote:
      return NSLocalizedString("Watch the Google I/O developer keynote.",
                               comment: "Accessibility label for keynote moment")
    case .lunchDayOne, .lunchDayTwo, .lunchDayThree:
      return NSLocalizedString("Visit one of the EATS food stands to grab some lunch.",
                               comment: "Accessibility label for lunch moment")
    case .sessionsDayOne, .sessionsDayTwoMorning, .sessionsDayTwoAfternoon,
         .sessionsDayThreeMorning, .sessionsDayThreeAfternoon:
      return NSLocalizedString("Tune in to live sessions on the I/O livestream.",
                               comment: "Accessibility label for sessions moment")
    case .afterHoursDinner:
      return NSLocalizedString("Eat dinner after hours at the I/O venue.",
                               comment: "Accessibility label for dinner moment")
    case .dayOneWrap:
      return NSLocalizedString("Day one of Google I/O has concluded.",
                               comment: "Accessibility label for end of day 1")
    case .dayTwoMorning:
      return NSLocalizedString("Get ready for day two of Google I/O.",
                               comment: "Accessibility label for day 2 morning moment")
    case .concert:
      return NSLocalizedString("Join the I/O concert in person or remotely via livestream.",
                               comment: "Accessibility label for concert moment")
    case .dayTwoWrap:
      return NSLocalizedString("Day two of Google I/O has concluded.",
                               comment: "Accessibility label for end of day 2")
    case .dayThreeMorning:
      return NSLocalizedString("Get ready for day three of Google I/O.",
                               comment: "Accessibility label for day 3 morning moment")
    case .dayThreeWrap:
      return NSLocalizedString("This year's Google I/O has concluded. See you next year!",
                               comment: "Accessibility label for end of day 3")

    case _:
      break
    }
    return nil
  }

  var accessibilityHint: String? {
    if cta == .viewLivestream, self == .keynote || self == .developerKeynote {
      return NSLocalizedString("Double-tap to open keynote details",
                               comment: "Accessibility hint for activatable cell")
    }
    if cta == .viewLivestream {
      return NSLocalizedString("Double-tap to open livestream link",
                               comment: "Accessibility hint for activatable cell")
    }
    if cta == .viewMap {
      return NSLocalizedString("Double-tap to open in map",
                               comment: "Accessibility hint for activatable cell")
    }
    return nil
  }

  private static let dateFormatter: DateFormatter = {
    // Example date: "2019-05-07 11:30:00 -0700"
    let formatter = TimeZoneAwareDateFormatter()
    formatter.timeZone = TimeZone.userTimeZone()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
    return formatter
  }()

  private static let dateIntervalFormatter: DateIntervalFormatter = {
    let formatter = DateIntervalFormatter()
    formatter.timeZone = TimeZone.userTimeZone()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    registerForTimeZoneUpdates()
    return formatter
  }()

  private static func registerForTimeZoneUpdates() {
    _ = NotificationCenter.default.addObserver(forName: .timezoneUpdate,
                                               object: nil,
                                               queue: nil) { _ in
      dateIntervalFormatter.timeZone = TimeZone.userTimeZone()
    }
  }

  // MARK: - Moment constants

  static let keynote = Moment(
    attendeeRequired: false,
    cta: .viewLivestream,
    displayDate: "May 7th",
    startTime: dateFormatter.date(from: "2019-05-07 10:00:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-07 11:30:00 -0700")!,
    featureID: nil,
    featureName: "Watch Livestream",
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FHome-GoogleKeynote%402x.png?alt=media&token=0df80e81-5bea-4171-9016-4f1e3dcfc7f9")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-Home-GoogleKeynote%402x.png?alt=media&token=bfd169ae-f501-4cf8-94be-462682d40fd7")!,
    streamURL: URL(string: "https://youtu.be/JuMbOCQu-XM"),
    textColor: "#ffffff",
    timeVisible: true,
    title: "Keynote"
  )

  static let lunchDayOne = Moment(
    attendeeRequired: true,
    cta: .viewMap,
    displayDate: "May 7th",
    startTime: dateFormatter.date(from: "2019-05-07 11:30:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-07 12:45:00 -0700")!,
    featureID: "eats",
    featureName: "EATS",
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FSchedule-Lunch-1%402X.png?alt=media&token=0bdab2ab-b1ac-4c70-8ffb-4f3f317f5531")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-Schedule-Lunch-1%402X.png?alt=media&token=21ab538e-a791-49c5-b3d8-cc0c92b6f460")!,
    streamURL: nil,
    textColor: "#ffffff",
    timeVisible: true,
    title: "Lunch"
  )

  static let developerKeynote = Moment(
    attendeeRequired: false,
    cta: .viewLivestream,
    displayDate: "May 7th",
    startTime: dateFormatter.date(from: "2019-05-07 12:45:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-07 14:00:00 -0700")!,
    featureID: nil,
    featureName: "Watch Livestream",
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FHome-DevKeynote%402x.png?alt=media&token=d11ff5ac-0bda-46cb-b730-761494207979")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-Home-DevKeynot%402x.png?alt=media&token=069779b3-ddba-421d-86c0-090f7b3f1692")!,
    streamURL: URL(string: "https://youtu.be/lyRPyRKHO8M"),
    textColor: "#ffffff",
    timeVisible: true,
    title: "Developer keynote"
  )

  static let sessionsDayOne = Moment(
    attendeeRequired: false,
    cta: .viewLivestream,
    displayDate: "May 7th",
    startTime: dateFormatter.date(from: "2019-05-07 14:00:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-07 18:30:00 -0700")!,
    featureID: nil,
    featureName: "Watch Livestream",
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FHomeIO%402x.png?alt=media&token=0bea342d-94d4-4d1f-8adf-d61f1a3e2ea3")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-HomeIO%402x.png?alt=media&token=1e98c915-2ad5-40ef-bd90-1c56ee1f390a")!,
    streamURL: URL(string: "https://youtu.be/e0B28zBn9JE"),
    textColor: "#ffffff",
    timeVisible: true,
    title: "Live show (sessions)"
  )

  static let afterHoursDinner = Moment(
    attendeeRequired: false,
    cta: .viewMap,
    displayDate: "May 7th",
    startTime: dateFormatter.date(from: "2019-05-07 18:30:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-07 22:00:00 -0700")!,
    featureID: nil,
    featureName: "View Map",
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-Home-AfterDark-Text%402x.png?alt=media&token=f863a425-cb3b-4430-a8c6-8364d00c8363")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-Home-AfterDark-Text%402x.png?alt=media&token=f863a425-cb3b-4430-a8c6-8364d00c8363")!,
    streamURL: nil,
    textColor: "#ffffff",
    timeVisible: true,
    title: "Live show (sessions)"
  )

  static let dayOneWrap = Moment(
    attendeeRequired: false,
    cta: nil,
    displayDate: "May 7th",
    startTime: dateFormatter.date(from: "2019-05-07 22:00:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-08 06:00:00 -0700")!,
    featureID: nil,
    featureName: nil,
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FEnd%20of%20day1%402x.png?alt=media&token=173d3868-0c25-4da2-8f25-8d814490559e")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FEnd%20of%20day1-dm%402x.png?alt=media&token=abc8e4cc-463b-4685-8c4b-f1b4664f3134")!,
    streamURL: nil,
    textColor: "#ffffff",
    timeVisible: false,
    title: "Day 1: wrap"
  )

  static let dayTwoMorning = Moment(
    attendeeRequired: false,
    cta: nil,
    displayDate: "May 8th",
    startTime: dateFormatter.date(from: "2019-05-08 06:00:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-08 08:30:00 -0700")!,
    featureID: nil,
    featureName: nil,
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FAPP-day02%402x.png?alt=media&token=cc5556c0-d125-4619-b3e4-6ca39b5bb09c")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-APP-day02%402x.png?alt=media&token=136d1308-cc70-4bc4-9320-535aa196387e")!,
    streamURL: nil,
    textColor: "#ffffff",
    timeVisible: true,
    title: "Day 2: morning"
  )

  static let sessionsDayTwoMorning = Moment(
    attendeeRequired: false,
    cta: .viewLivestream,
    displayDate: "May 8th",
    startTime: dateFormatter.date(from: "2019-05-08 08:30:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-08 11:30:00 -0700")!,
    featureID: nil,
    featureName: "Watch Livestream",
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FHomeIO%402x.png?alt=media&token=0bea342d-94d4-4d1f-8adf-d61f1a3e2ea3")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-HomeIO%402x.png?alt=media&token=1e98c915-2ad5-40ef-bd90-1c56ee1f390a")!,
    streamURL: URL(string: "https://youtu.be/irpNzosHbPU"),
    textColor: "#ffffff",
    timeVisible: true,
    title: "Live show (sessions)"
  )

  static let lunchDayTwo = Moment(
    attendeeRequired: true,
    cta: .viewMap,
    displayDate: "May 8th",
    startTime: dateFormatter.date(from: "2019-05-08 11:30:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-08 14:30:00 -0700")!,
    featureID: "eats",
    featureName: "EATS",
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FSchedule-Lunch-2%402X.png?alt=media&token=8e54b7a8-f72f-4803-8d93-ddb3c78694a7")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-Schedule-Lunch-2%402X.png?alt=media&token=dba29718-437f-4d38-ae5f-93fed2f7cab2")!,
    streamURL: nil,
    textColor: "#ffffff",
    timeVisible: true,
    title: "Lunch"
  )

  static let sessionsDayTwoAfternoon = Moment(
    attendeeRequired: false,
    cta: .viewLivestream,
    displayDate: "May 8th",
    startTime: dateFormatter.date(from: "2019-05-08 14:30:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-08 19:30:00 -0700")!,
    featureID: nil,
    featureName: "Watch Livestream",
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FHomeIO%402x.png?alt=media&token=0bea342d-94d4-4d1f-8adf-d61f1a3e2ea3")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-HomeIO%402x.png?alt=media&token=1e98c915-2ad5-40ef-bd90-1c56ee1f390a")!,
    streamURL: URL(string: "https://youtu.be/irpNzosHbPU"),
    textColor: "#ffffff",
    timeVisible: true,
    title: "Live show (sessions)"
  )

  static let concert = Moment(
    attendeeRequired: false,
    cta: .viewLivestream,
    displayDate: "May 8th",
    startTime: dateFormatter.date(from: "2019-05-08 19:30:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-08 22:00:00 -0700")!,
    featureID: nil,
    featureName: "Watch Livestream",
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-Home-Concert-Text-v2.png?alt=media&token=cf913585-65b7-4fb7-958c-5e333e6ee85f")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-Home-Concert-Text-v2.png?alt=media&token=cf913585-65b7-4fb7-958c-5e333e6ee85f")!,
    streamURL: URL(string: "https://youtu.be/Z9WusLkJ01s"),
    textColor: "#ffffff",
    timeVisible: true,
    title: "Concert"
  )

  static let dayTwoWrap = Moment(
    attendeeRequired: false,
    cta: nil,
    displayDate: "May 8th",
    startTime: dateFormatter.date(from: "2019-05-08 22:00:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-09 06:00:00 -0700")!,
    featureID: nil,
    featureName: nil,
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FEnd%20of%20day2%402x.png?alt=media&token=37ac81db-b334-4c05-8448-4b1d139d711b")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FEnd%20of%20day2-dm%402x.png?alt=media&token=0a40d99f-39b1-4936-8967-0319039e05cd")!,
    streamURL: nil,
    textColor: "#ffffff",
    timeVisible: false,
    title: "Day 2: wrap"
  )

  static let dayThreeMorning = Moment(
    attendeeRequired: false,
    cta: nil,
    displayDate: "May 9th",
    startTime: dateFormatter.date(from: "2019-05-09 06:00:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-09 08:30:00 -0700")!,
    featureID: nil,
    featureName: nil,
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FAPP-day03%402x.png?alt=media&token=2a7e37e3-3138-43a2-acef-ff3ce44664a3")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-APP-day03%402x.png?alt=media&token=5527c547-ac01-40e5-ac12-f99cf5e2e110")!,
    streamURL: nil,
    textColor: "#ffffff",
    timeVisible: true,
    title: "Day 3: morning"
  )

  static let sessionsDayThreeMorning = Moment(
    attendeeRequired: false,
    cta: .viewLivestream,
    displayDate: "May 9th",
    startTime: dateFormatter.date(from: "2019-05-09 08:30:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-09 11:30:00 -0700")!,
    featureID: nil,
    featureName: "Watch Livestream",
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FHomeIO%402x.png?alt=media&token=0bea342d-94d4-4d1f-8adf-d61f1a3e2ea3")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-HomeIO%402x.png?alt=media&token=1e98c915-2ad5-40ef-bd90-1c56ee1f390a")!,
    streamURL: URL(string: "https://youtu.be/WQklcSsYdu4"),
    textColor: "#ffffff",
    timeVisible: true,
    title: "Live show (sessions)"
  )

  static let lunchDayThree = Moment(
    attendeeRequired: true,
    cta: .viewMap,
    displayDate: "May 9th",
    startTime: dateFormatter.date(from: "2019-05-09 11:30:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-09 14:30:00 -0700")!,
    featureID: "eats",
    featureName: "EATS",
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FSchedule-Lunch-3%402X.png?alt=media&token=e4079280-f497-460c-bb89-51746c4d9e13")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-Schedule-Lunch-3%402X.png?alt=media&token=2ac97cb7-2e4c-41fd-bd37-5594251158cc")!,
    streamURL: nil,
    textColor: "#ffffff",
    timeVisible: true,
    title: "Lunch"
  )

  static let sessionsDayThreeAfternoon = Moment(
    attendeeRequired: false,
    cta: .viewLivestream,
    displayDate: "May 9th",
    startTime: dateFormatter.date(from: "2019-05-09 14:30:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-09 17:00:00 -0700")!,
    featureID: nil,
    featureName: "Watch Livestream",
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FHomeIO%402x.png?alt=media&token=0bea342d-94d4-4d1f-8adf-d61f1a3e2ea3")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-HomeIO%402x.png?alt=media&token=1e98c915-2ad5-40ef-bd90-1c56ee1f390a")!,
    streamURL: URL(string: "https://youtu.be/WQklcSsYdu4"),
    textColor: "#ffffff",
    timeVisible: true,
    title: "Live show (sessions)"
  )

  static let dayThreeWrap = Moment(
    attendeeRequired: false,
    cta: nil,
    displayDate: "May 9th",
    startTime: dateFormatter.date(from: "2019-05-09 17:00:00 -0700")!,
    endTime: dateFormatter.date(from: "2019-05-09 22:00:00 -0700")!,
    featureID: nil,
    featureName: nil,
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FEnd%20of%20day3%402x.png?alt=media&token=9f7c2a81-ebe5-473b-ab05-529093a201e4")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FEnd%20of%20day3-dm%402x.png?alt=media&token=f4d4fdb6-9e13-4e96-bb0e-c6b990ceacf8")!,
    streamURL: nil,
    textColor: "#ffffff",
    timeVisible: false,
    title: "That’s a wrap…thanks!"
  )

  static let evergreenBranding = Moment(
    attendeeRequired: false,
    cta: nil,
    displayDate: "May 10th",
    startTime: dateFormatter.date(from: "2019-05-09 22:00:00 -0700")!,
    endTime: dateFormatter.date(from: "2025-01-01 09:00:00 -0800")!,
    featureID: nil,
    featureName: nil,
    imageURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FHome-Evergreen2%402x.png?alt=media&token=35c71f46-818c-41c1-b58a-94be038221a2")!,
    imageURLDarkTheme: URL(string: "https://firebasestorage.googleapis.com/v0/b/io2019-festivus/o/images%2Fhome%2FDM-Home-Evergreen2%402x.png?alt=media&token=95022ef8-0fdb-4fb5-8f4a-0acc6ea59825")!,
    streamURL: nil,
    textColor: "#ffffff",
    timeVisible: false,
    title: "Evergreen branding"
  )

  static let allMoments: [Moment] = [
    .keynote,
    .lunchDayOne,
    .developerKeynote,
    .sessionsDayOne,
    .afterHoursDinner,
    .dayOneWrap,
    .dayTwoMorning,
    .sessionsDayTwoMorning,
    .lunchDayTwo,
    .sessionsDayTwoAfternoon,
    .concert,
    .dayTwoWrap,
    .dayThreeMorning,
    .sessionsDayThreeMorning,
    .lunchDayThree,
    .sessionsDayThreeAfternoon,
    .dayThreeWrap
  ]

  static func currentMoment(for date: Date = Date()) -> Moment? {
    for moment in allMoments where moment.startTime <= date && moment.endTime > date {
      return moment
    }
    return nil
  }

}

extension Moment: Equatable {}
public func == (lhs: Moment, rhs: Moment) -> Bool {
  return lhs.title == rhs.title && lhs.cta == rhs.cta && lhs.startTime == rhs.startTime &&
      lhs.endTime == rhs.endTime && lhs.imageURL == rhs.imageURL && lhs.streamURL == rhs.streamURL
}
