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

public enum TagType: String {
  /// 'Type' is the name used by the backend to refer to misc event types, like sandbox/after hours.
  case type
  /// The difficulty of the event (beginner, intermediate, advanced)
  case level
  /// The topic of a session, i.e. "Android"
  case topic
}

public struct EventTag {

  /// The type of the tag.
  public var type: TagType

  /// The display name of the tag.
  public var name: String

  /// The representation of the tag on the backend. This value can be used as a unique identifier.
  public var tag: String
  public var orderInCategory: Int

  /// The background color of the tag, in hex string form.
  public var colorString: String?
  /// The text color of the tag, in hex string form.
  public var fontColorString: String?

  public init?(dictionary: [String: Any]) {
    guard let type = (dictionary["category"] as? String).flatMap(TagType.init(rawValue:)),
        let name = dictionary["name"] as? String,
        let tag = dictionary["tag"] as? String,
        let order = (dictionary["order_in_category"] as? Int)  else {
            return nil
    }

    let colorString = dictionary["color"] as? String
    let fontColor = dictionary["fontColor"] as? String

    self.init(type: type,
              name: name,
              tag: tag,
              orderInCategory: order,
              colorString: colorString,
              fontColorString: fontColor)
  }

  public init(type: TagType,
              name: String,
              tag: String,
              orderInCategory: Int,
              colorString: String?,
              fontColorString: String?) {
    self.type = type
    self.name = name
    self.tag = tag
    self.orderInCategory = orderInCategory
    self.colorString = colorString
    self.fontColorString = fontColorString
  }

  public init?(name: String) {
    let filtered = EventTag.allTags.filter { $0.name == name }
    if let first = filtered.first {
      self = first
    }
    return nil
  }

  public var color: UIColor {
    if let hex = self.colorString {
      return UIColor(hex: hex)
    }
    return UIColor(hex: "#e0f2f1")
  }

}

extension EventTag: Equatable {}
public func == (lhs: EventTag, rhs: EventTag) -> Bool {
  return lhs.type == rhs.type &&
      lhs.tag == rhs.tag
}

extension EventTag {

  public static let keynote = EventTag(
    type: .topic,
    name: "Keynote",
    tag: "topic_keynote",
    orderInCategory: 0,
    colorString: "#31E7B6",
    fontColorString: "#202124"
  )

  public static let accessibility = EventTag(
    type: .topic,
    name: "Accessibility",
    tag: "topic_accessibility",
    orderInCategory: 0,
    colorString: "#4768FD",
    fontColorString: "#FFFFFF"
  )

  public static let ads = EventTag(
    type: .topic,
    name: "Ads",
    tag: "topic_ads",
    orderInCategory: 0,
    colorString: "#574DDD",
    fontColorString: "#FFFFFF"
  )

  public static let android = EventTag(
    type: .topic,
    name: "Android / Play",
    tag: "topic_android/play",
    orderInCategory: 2,
    colorString: "#8DA0FC",
    fontColorString: "#202124"
  )

  public static let assistant = EventTag(
    type: .topic,
    name: "Assistant",
    tag: "topic_assistant",
    orderInCategory: 0,
    colorString: "#27E5FD",
    fontColorString: "#202124"
  )

  public static let augmentedReality = EventTag(
    type: .topic,
    name: "Augmented Reality",
    tag: "topic_augmentedreality",
    orderInCategory: 0,
    colorString: "#94DD6B",
    fontColorString: "#202124"
  )

  public static let chromeOS = EventTag(
    type: .topic,
    name: "Chrome OS",
    tag: "topic_chromeos",
    orderInCategory: 0,
    colorString: "#FD9127",
    fontColorString: "#202124"
  )

  public static let cloud = EventTag(
    type: .topic,
    name: "Cloud",
    tag: "topic_cloud",
    orderInCategory: 0,
    colorString: "#1DB8D2",
    fontColorString: "#202124"
  )

  public static let design = EventTag(
    type: .topic,
    name: "Design",
    tag: "topic_design",
    orderInCategory: 0,
    colorString: "#069F86",
    fontColorString: "#202124"
  )

  public static let firebase = EventTag(
    type: .topic,
    name: "Firebase",
    tag: "topic_firebase",
    orderInCategory: 0,
    colorString: "#39C79D",
    fontColorString: "#202124"
  )

  public static let flutter = EventTag(
    type: .topic,
    name: "Flutter",
    tag: "topic_flutter",
    orderInCategory: 0,
    colorString: "#31E7B6",
    fontColorString: "#202124"
  )

  public static let gaming = EventTag(
    type: .topic,
    name: "Gaming",
    tag: "topic_gaming",
    orderInCategory: 0,
    colorString: "#4768FD",
    fontColorString: "#FFFFFF"
  )

  public static let iot = EventTag(
    type: .topic,
    name: "IoT",
    tag: "topic_iot",
    orderInCategory: 0,
    colorString: "#BBF5CB",
    fontColorString: "#202124"
  )

  public static let locationMaps = EventTag(
    type: .topic,
    name: "Location / Maps",
    tag: "topic_location/maps",
    orderInCategory: 0,
    colorString: "#FEEBB6",
    fontColorString: "#202124"
  )

  public static let misc = EventTag(
    type: .topic,
    name: "Misc",
    tag: "topic_misc",
    orderInCategory: 0,
    colorString: "#E8BC4F",
    fontColorString: "#202124"
  )

  public static let machineLearning = EventTag(
    type: .topic,
    name: "ML & AI",
    tag: "topic_ml/ai",
    orderInCategory: 0,
    colorString: "#FCD230",
    fontColorString: "#202124"
  )

  public static let openSource = EventTag(
    type: .topic,
    name: "Open Source",
    tag: "topic_opensource",
    orderInCategory: 0,
    colorString: "#FF6C00",
    fontColorString: "#202124"
  )

  public static let payments = EventTag(
    type: .topic,
    name: "Payments",
    tag: "topic_payments",
    orderInCategory: 0,
    colorString: "#FF9E80",
    fontColorString: "#202124"
  )

  public static let search = EventTag(
    type: .topic,
    name: "Search",
    tag: "topic_search",
    orderInCategory: 0,
    colorString: "#4768FD",
    fontColorString: "#FFFFFF"
  )

  public static let web = EventTag(
    type: .topic,
    name: "Web",
    tag: "topic_web",
    orderInCategory: 0,
    colorString: "#FABFA9",
    fontColorString: "#202124"
  )

  public static let beginner = EventTag(
    type: .level,
    name: "Beginner",
    tag: "level_beginner",
    orderInCategory: 1,
    colorString: nil,
    fontColorString: nil
  )

  public static let intermediate = EventTag(
    type: .level,
    name: "Intermediate",
    tag: "level_intermediate",
    orderInCategory: 2,
    colorString: nil,
    fontColorString: nil
  )

  public static let advanced = EventTag(
    type: .level,
    name: "Advanced",
    tag: "level_advanced",
    orderInCategory: 3,
    colorString: nil,
    fontColorString: nil
  )

  public static let afterHours = EventTag(
    type: .type,
    name: "After Dark",
    tag: "type_afterdark",
    orderInCategory: 0,
    colorString: "#999999",
    fontColorString: nil
  )

  public static let gameReviews = EventTag(
    type: .type,
    name: "Game Reviews",
    tag: "type_gamereviews",
    orderInCategory: 0,
    colorString: "#999999",
    fontColorString: nil
  )

  public static let keynotes = EventTag(
    type: .type,
    name: "Keynotes",
    tag: "type_keynotes",
    orderInCategory: 0,
    colorString: "#999999",
    fontColorString: nil
  )

  public static let meetups = EventTag(
    type: .type,
    name: "Meetups",
    tag: "type_meetups",
    orderInCategory: 0,
    colorString: "#999999",
    fontColorString: nil
  )

  public static let appReviews = EventTag(
    type: .type,
    name: "App Reviews",
    tag: "type_appreviews",
    orderInCategory: 1,
    colorString: "#999999",
    fontColorString: nil
  )

  public static let codelabs = EventTag(
    type: .type,
    name: "Codelabs",
    tag: "type_codelabs",
    orderInCategory: 2,
    colorString: "#999999",
    fontColorString: nil
  )

  public static let officeHours = EventTag(
    type: .type,
    name: "Office Hours",
    tag: "type_officehours",
    orderInCategory: 3,
    colorString: "#999999",
    fontColorString: nil
  )

  public static let sessions = EventTag(
    type: .type,
    name: "Sessions",
    tag: "type_sessions",
    orderInCategory: 5,
    colorString: "#999999",
    fontColorString: nil
  )

  public static let allTags: [EventTag] = [
    // Topics
    .keynote,
    .accessibility,
    .ads,
    .android,
    .assistant,
    .augmentedReality,
    .chromeOS,
    .cloud,
    .design,
    .firebase,
    .flutter,
    .gaming,
    .iot,
    .locationMaps,
    .misc,
    .machineLearning,
    .openSource,
    .payments,
    .search,
    .web,

    // Levels
    .beginner,
    .intermediate,
    .advanced,

    // Types
    .afterHours,
    .gameReviews,
    .keynotes,
    .meetups,
    .appReviews,
    .codelabs,
    .officeHours,
    .sessions
  ]

  public static var allTopics: [EventTag] {
    return allTags.filter { $0.type == .topic }
  }

  public static var allTypes: [EventTag] {
    return allTags.filter { $0.type == .type }
  }

  public static var allLevels: [EventTag] {
    return allTags.filter { $0.type == .level }
  }

}
