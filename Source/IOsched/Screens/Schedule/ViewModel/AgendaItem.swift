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
}

public struct AgendaItem {

  var type: AgendaItemType
  var startDate: Date
  var endDate: Date

  var imageName: String {
    return imageName(for: type)
  }
  var backgroundColor: UIColor {
    return UIColor(hex: backgroundColorHex(for: type))
  }
  var textColor: UIColor {
    return UIColor(hex: textColorHex(for: type))
  }
  var title: String {
    return title(for: type)
  }
  var image: UIImage? {
    return image(for: type)
  }

  private func image(for agendaItemType: AgendaItemType) -> UIImage? {
    var icon = UIImage(named: imageName(for: agendaItemType))
    if agendaItemType == .sessions {
      icon = icon.flatMap { $0.image(withTint: UIColor(hex: "#202124")) }
    }
    return icon
  }

  private func imageName(for agendaItemType: AgendaItemType) -> String {
    switch agendaItemType {
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
  private func backgroundColorHex(for agendaItemType: AgendaItemType) -> String {
    switch agendaItemType {
    case .badgePickup, .badgeAndDevicePickup:
      return "#E6E6E6"
    case .breakfast, .lunch:
      return "#31E7B6"
    case .keynote:
      return "#FCD230"
    case .sessions:
      return "#27E5FD"
    case .codelabs, .sandbox, .officeHours:
      return "#4768FD"
    case .afterHoursParty, .concert:
      return "#202124"
    }
  }

  private func textColorHex(for agendaItemType: AgendaItemType) -> String {
    switch agendaItemType {
    case .badgePickup, .badgeAndDevicePickup, .breakfast, .lunch, .keynote, .sessions:
      return "#202124"
    case .codelabs, .sandbox, .officeHours, .concert, .afterHoursParty:
      return "#FFFFFF"
    }
  }

  private func title(for agendaItemType: AgendaItemType) -> String {
    switch agendaItemType {
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
      return NSLocalizedString("After hours party", comment: "Calendar item name")
    case .concert:
      return NSLocalizedString("Concert", comment: "Calendar item name")
    }
  }

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
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
                 startDateString: "2018-05-07 07:00:00 -0700",
                 endDateString: "2018-05-07 19:00:00 -0700")
    ],
    [
      AgendaItem(type: .badgePickup,
                 startDateString: "2018-05-08 07:00:00 -0700",
                 endDateString: "2018-05-08 19:00:00 -0700"),
      AgendaItem(type: .breakfast,
                 startDateString: "2018-05-08 07:00:00 -0700",
                 endDateString: "2018-05-08 09:30:00 -0700"),
      AgendaItem(type: .lunch,
                 startDateString: "2018-05-08 11:30:00 -0700",
                 endDateString: "2018-05-08 14:30:00 -0700"),
      AgendaItem(type: .keynote,
                 startDateString: "2018-05-08 10:00:00 -0700",
                 endDateString: "2018-05-08 11:30:00 -0700"),
      AgendaItem(type: .keynote,
                 startDateString: "2018-05-08 12:45:00 -0700",
                 endDateString: "2018-05-08 13:45:00 -0700"),
      AgendaItem(type: .sessions,
                 startDateString: "2018-05-08 14:00:00 -0700",
                 endDateString: "2018-05-08 19:00:00 -0700"),
      AgendaItem(type: .codelabs,
                 startDateString: "2018-05-08 11:30:00 -0700",
                 endDateString: "2018-05-08 12:30:00 -0700"),
      AgendaItem(type: .codelabs,
                 startDateString: "2018-05-08 14:00:00 -0700",
                 endDateString: "2018-05-08 19:30:00 -0700"),
      AgendaItem(type: .sandbox,
                 startDateString: "2018-05-08 14:00:00 -0700",
                 endDateString: "2018-05-08 19:30:00 -0700"),
      AgendaItem(type: .officeHours,
                 startDateString: "2018-05-08 11:30:00 -0700",
                 endDateString: "2018-05-08 12:30:00 -0700"),
      AgendaItem(type: .officeHours,
                 startDateString: "2018-05-08 14:00:00 -0700",
                 endDateString: "2018-05-08 19:00:00 -0700"),
      AgendaItem(type: .afterHoursParty,
                 startDateString: "2018-05-08 19:00:00 -0700",
                 endDateString: "2018-05-08 22:00:00 -0700")
    ],
    [
      AgendaItem(type: .breakfast,
                 startDateString: "2018-05-09 08:00:00 -0700",
                 endDateString: "2018-05-09 10:00:00 -0700"),
      AgendaItem(type: .lunch,
                 startDateString: "2018-05-09 11:30:00 -0700",
                 endDateString: "2018-05-09 14:30:00 -0700"),
      AgendaItem(type: .badgeAndDevicePickup,
                 startDateString: "2018-05-09 08:00:00 -0700",
                 endDateString: "2018-05-09 19:00:00 -0700"),
      AgendaItem(type: .sessions,
                 startDateString: "2018-05-09 08:30:00 -0700",
                 endDateString: "2018-05-09 19:30:00 -0700"),
      AgendaItem(type: .codelabs,
                 startDateString: "2018-05-09 08:30:00 -0700",
                 endDateString: "2018-05-09 20:00:00 -0700"),
      AgendaItem(type: .sandbox,
                 startDateString: "2018-05-09 08:30:00 -0700",
                 endDateString: "2018-05-09 20:00:00 -0700"),
      AgendaItem(type: .officeHours,
                 startDateString: "2018-05-09 08:30:00 -0700",
                 endDateString: "2018-05-09 19:30:00 -0700"),
      AgendaItem(type: .concert,
                 startDateString: "2018-05-09 19:30:00 -0700",
                 endDateString: "2018-05-09 22:00:00 -0700")
    ],
    [
      AgendaItem(type: .breakfast,
                 startDateString: "2018-05-10 08:00:00 -0700",
                 endDateString: "2018-05-10 10:00:00 -0700"),
      AgendaItem(type: .lunch,
                 startDateString: "2018-05-10 11:30:00 -0700",
                 endDateString: "2018-05-10 14:30:00 -0700"),
      AgendaItem(type: .badgeAndDevicePickup,
                 startDateString: "2018-05-10 08:00:00 -0700",
                 endDateString: "2018-05-10 16:00:00 -0700"),
      AgendaItem(type: .sessions,
                 startDateString: "2018-05-10 08:30:00 -0700",
                 endDateString: "2018-05-10 16:30:00 -0700"),
      AgendaItem(type: .codelabs,
                 startDateString: "2018-05-10 08:30:00 -0700",
                 endDateString: "2018-05-10 16:00:00 -0700"),
      AgendaItem(type: .sandbox,
                 startDateString: "2018-05-10 08:30:00 -0700",
                 endDateString: "2018-05-10 16:00:00 -0700"),
      AgendaItem(type: .officeHours,
                 startDateString: "2018-05-10 08:30:00 -0700",
                 endDateString: "2018-05-10 16:30:00 -0700")
    ],
  ]

}

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
