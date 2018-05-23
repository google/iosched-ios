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

import UIKit

public enum AgendaItemType {

  case badgePickup
  case badgeAndDevicePickup
  case breakfast
  case lunch
  case keynote
  case sessions
  case codelabs
  case sandbox
  case officeHours
  case afterHoursParty
  case concert

  fileprivate var imageName: String {
    switch self {
    case .badgePickup, .badgeAndDevicePickup:
      return "ic_badge_pickup"
    case .breakfast, .lunch:
      return "ic_meal"
    case .keynote:
      return "ic_keynote"
    case .sessions:
      return "ic_sessions"
    case .codelabs:
      return "ic_codelabs_agenda"
    case .sandbox:
      return "ic_sandbox_agenda"
    case .officeHours:
      return "ic_office_hours_agenda"
    case .afterHoursParty:
      return "ic_after_hours_party"
    case .concert:
      return "ic_concert"
    }
  }

  // Taken from the website.
  fileprivate var backgroundColor: UIColor {
    switch self {
    case .badgePickup, .badgeAndDevicePickup:
      return UIColor(red: 232 / 255, green: 234 / 255, blue: 237 / 255, alpha: 1)
    case .breakfast, .lunch:
      return UIColor(red: 250 / 255, green: 210 / 255, blue: 207 / 255, alpha: 1)
    case .keynote:
      return UIColor(red: 251 / 255, green: 188 / 255, blue: 4 / 255, alpha: 1)
    case .sessions:
      return UIColor(red: 91 / 255, green: 185 / 255, blue: 116 / 255, alpha: 1)
    case .codelabs, .sandbox, .officeHours:
      return UIColor(hex: 0x4285f4) // Taken from website
    case .afterHoursParty, .concert:
      return UIColor(red: 23 / 255, green: 71 / 255, blue: 166 / 255, alpha: 1)
    }
  }

  fileprivate var textColorHex: String {
    switch self {
    case .badgePickup, .badgeAndDevicePickup, .breakfast, .lunch, .keynote:
      return "#323336"
    case .codelabs, .sandbox, .officeHours, .concert, .afterHoursParty, .sessions:
      return "#FFFFFF"
    }
  }

  fileprivate var title: String {
    switch self {
    case .badgePickup:
      return NSLocalizedString("Badge pickup", comment: "Calendar event name")
    case .badgeAndDevicePickup:
      return NSLocalizedString("Badge & device pickup", comment: "Calendar event name")
    case .breakfast:
      return NSLocalizedString("Breakfast", comment: "Calendar event name")
    case .lunch:
      return NSLocalizedString("Lunch", comment: "Calendar event name")
    case .keynote:
      return NSLocalizedString("Keynote", comment: "Calendar event name")
    case .sessions:
      return NSLocalizedString("Sessions", comment: "Calendar event name")
    case .codelabs:
      return NSLocalizedString("Codelabs", comment: "Calendar event name")
    case .sandbox:
      return NSLocalizedString("Sandbox", comment: "Calendar event name")
    case .officeHours:
      return NSLocalizedString("Office hours & app reviews", comment: "Calendar item name")
    case .afterHoursParty:
      return NSLocalizedString("After Dark", comment: "Calendar item name")
    case .concert:
      return NSLocalizedString("Concert", comment: "Calendar item name")
    }
  }

}

public struct AgendaItem {

  public var type: AgendaItemType
  public var startDate: Date
  public var endDate: Date

  public var imageName: String {
    return type.imageName
  }
  public var backgroundColor: UIColor {
    return type.backgroundColor
  }
  public var textColor: UIColor {
    return UIColor(hex: type.textColorHex)
  }
  public var title: String {
    return type.title
  }
  public var image: UIImage? {
    return image(for: type)
  }
  public var displayableTimeInterval: String {
    return AgendaItem.dateIntervalFormatter.string(from: startDate,
                                                   to: endDate)
  }

  private func image(for agendaItemType: AgendaItemType) -> UIImage? {
    var icon = UIImage(named: agendaItemType.imageName)
    if agendaItemType == .afterHoursParty {
      icon = icon.flatMap { $0.image(withTint: UIColor(hex: "#FFFFFF")) }
    }
    return icon
  }

  private static var notificationListener: Any?

  private static func registerForTimeZoneChanges() {
    if notificationListener != nil { return }
    notificationListener = NotificationCenter.default.addObserver(forName: .timezoneUpdate, object: nil, queue: nil, using: { _ in
      self.dateFormatter.timeZone = TimeZone.userTimeZone()
      self.dateIntervalFormatter.timeZone = TimeZone.userTimeZone()
    })
  }

  private static let dateIntervalFormatter: DateIntervalFormatter = {
    registerForTimeZoneChanges()
    let formatter = DateIntervalFormatter()
    formatter.timeZone = TimeZone.userTimeZone()
    formatter.dateTemplate = "hh:mm"
    return formatter
  }()

  private static let dateFormatter: DateFormatter = {
    registerForTimeZoneChanges()
    let formatter = TimeZoneAwareDateFormatter()
    formatter.timeZone = TimeZone.userTimeZone()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
    return formatter
  }()

  private init(type: AgendaItemType, startDateString: String, endDateString: String) {
    self.type = type
    self.startDate = AgendaItem.dateFormatter.date(from: startDateString)!
    self.endDate = AgendaItem.dateFormatter.date(from: endDateString)!
  }

  public static let allAgendaItems: [[AgendaItem]] = [
    [
      AgendaItem(type: .badgePickup,
                 startDateString: "2019-05-06 07:00:00 -0700",
                 endDateString: "2019-05-06 19:00:00 -0700")
    ],
    [
      AgendaItem(type: .badgePickup,
                 startDateString: "2019-05-07 07:00:00 -0700",
                 endDateString: "2019-05-07 19:00:00 -0700"),
      AgendaItem(type: .breakfast,
                 startDateString: "2019-05-07 07:00:00 -0700",
                 endDateString: "2019-05-07 09:30:00 -0700"),
      AgendaItem(type: .lunch,
                 startDateString: "2019-05-07 11:30:00 -0700",
                 endDateString: "2019-05-07 13:00:00 -0700"),
      AgendaItem(type: .keynote,
                 startDateString: "2019-05-07 10:00:00 -0700",
                 endDateString: "2019-05-07 11:30:00 -0700"),
      AgendaItem(type: .keynote,
                 startDateString: "2019-05-07 12:45:00 -0700",
                 endDateString: "2019-05-07 13:45:00 -0700"),
      AgendaItem(type: .sessions,
                 startDateString: "2019-05-07 14:00:00 -0700",
                 endDateString: "2019-05-07 19:00:00 -0700"),
      AgendaItem(type: .codelabs,
                 startDateString: "2019-05-07 14:00:00 -0700",
                 endDateString: "2019-05-07 19:00:00 -0700"),
      AgendaItem(type: .sandbox,
                 startDateString: "2019-05-07 14:00:00 -0700",
                 endDateString: "2019-05-07 19:00:00 -0700"),
      AgendaItem(type: .officeHours,
                 startDateString: "2019-05-07 14:00:00 -0700",
                 endDateString: "2019-05-07 19:00:00 -0700"),
      AgendaItem(type: .afterHoursParty,
                 startDateString: "2019-05-07 18:30:00 -0700",
                 endDateString: "2019-05-07 22:00:00 -0700")
    ],
    [
      AgendaItem(type: .breakfast,
                 startDateString: "2019-05-08 08:00:00 -0700",
                 endDateString: "2019-05-08 10:00:00 -0700"),
      AgendaItem(type: .lunch,
                 startDateString: "2019-05-08 11:30:00 -0700",
                 endDateString: "2019-05-08 14:30:00 -0700"),
      AgendaItem(type: .badgePickup,
                 startDateString: "2019-05-08 08:00:00 -0700",
                 endDateString: "2019-05-08 19:00:00 -0700"),
      AgendaItem(type: .sessions,
                 startDateString: "2019-05-08 08:30:00 -0700",
                 endDateString: "2019-05-08 19:30:00 -0700"),
      AgendaItem(type: .codelabs,
                 startDateString: "2019-05-08 08:30:00 -0700",
                 endDateString: "2019-05-08 19:00:00 -0700"),
      AgendaItem(type: .sandbox,
                 startDateString: "2019-05-08 08:30:00 -0700",
                 endDateString: "2019-05-08 19:00:00 -0700"),
      AgendaItem(type: .officeHours,
                 startDateString: "2019-05-08 08:30:00 -0700",
                 endDateString: "2019-05-08 19:00:00 -0700"),
      AgendaItem(type: .concert,
                 startDateString: "2019-05-08 20:00:00 -0700",
                 endDateString: "2019-05-08 22:00:00 -0700")
    ],
    [
      AgendaItem(type: .breakfast,
                 startDateString: "2019-05-09 08:00:00 -0700",
                 endDateString: "2019-05-09 10:00:00 -0700"),
      AgendaItem(type: .lunch,
                 startDateString: "2019-05-09 11:30:00 -0700",
                 endDateString: "2019-05-09 14:30:00 -0700"),
      AgendaItem(type: .badgePickup,
                 startDateString: "2019-05-09 08:00:00 -0700",
                 endDateString: "2019-05-09 16:00:00 -0700"),
      AgendaItem(type: .sessions,
                 startDateString: "2019-05-09 08:30:00 -0700",
                 endDateString: "2019-05-09 16:30:00 -0700"),
      AgendaItem(type: .codelabs,
                 startDateString: "2019-05-09 08:30:00 -0700",
                 endDateString: "2019-05-09 16:00:00 -0700"),
      AgendaItem(type: .sandbox,
                 startDateString: "2019-05-09 08:30:00 -0700",
                 endDateString: "2019-05-09 16:00:00 -0700"),
      AgendaItem(type: .officeHours,
                 startDateString: "2019-05-09 08:30:00 -0700",
                 endDateString: "2019-05-09 16:30:00 -0700")
    ]
  ]

}

extension AgendaItem: Equatable {}

// This category exists because one of our assets was the wrong color.
extension UIImage {
  fileprivate func image(withTint tintColor: UIColor) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    tintColor.setFill()
    context.translateBy(x: 0, y: self.size.height)
    context.scaleBy(x: 1, y: -1)
    context.clip(to: CGRect(origin: .zero, size: self.size), mask: self.cgImage!)
    context.fill(CGRect(origin: .zero, size: self.size))

    let coloredImg = UIGraphicsGetImageFromCurrentImageContext()

    UIGraphicsEndImageContext()
    return coloredImg
  }
}
