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

  public init?(dictionary: [String: String]) {
    guard let type = dictionary["category"].flatMap(TagType.init(rawValue:)),
        let name = dictionary["name"],
        let tag = dictionary["tag"],
        let order = dictionary["order_in_category"]
          .flatMap({ str -> Int? in return Int(str) }) else {
            return nil
    }

    let colorString = dictionary["color"]
    let fontColor = dictionary["fontColor"]

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

}

extension EventTag {

  public static let keynote = EventTag(
    type: .topic,
    name: "Keynote",
    tag: "topic_keynote",
    orderInCategory: 11,
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

  public static let ARVR = EventTag(
    type: .topic,
    name: "AR & VR",
    tag: "topic_ar&vr",
    orderInCategory: 0,
    colorString: "#ABD0F2",
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

  public static let identity = EventTag(
    type: .topic,
    name: "Identity",
    tag: "topic_identity",
    orderInCategory: 0,
    colorString: "#94DD6B",
    fontColorString: "#202124"
  )

  public static let machineLearning = EventTag(
    type: .topic,
    name: "Machine Learning & AI",
    tag: "topic_machinelearning&ai",
    orderInCategory: 0,
    colorString: "#FCD230",
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

  public static let payments = EventTag(
    type: .topic,
    name: "Payments",
    tag: "topic_payments",
    orderInCategory: 0,
    colorString: "#FF9E80",
    fontColorString: "#202124"
  )

  public static let android = EventTag(
    type: .topic,
    name: "Android & Play",
    tag: "topic_android&play",
    orderInCategory: 2,
    colorString: "#8DA0FC",
    fontColorString: "#202124"
  )

  public static let nest = EventTag(
    type: .topic,
    name: "Nest",
    tag: "topic_nest",
    orderInCategory: 3,
    colorString: "#FD9127",
    fontColorString: "#202124"
  )

  public static let cloud = EventTag(
    type: .topic,
    name: "Cloud",
    tag: "topic_cloud",
    orderInCategory: 4,
    colorString: "#1DB8D2",
    fontColorString: "#202124"
  )

  public static let design = EventTag(
    type: .topic,
    name: "Design",
    tag: "topic_design",
    orderInCategory: 5,
    colorString: "#069F86",
    fontColorString: "#202124"
  )

  public static let iot = EventTag(
    type: .topic,
    name: "IoT",
    tag: "topic_iot",
    orderInCategory: 8,
    colorString: "#BBF5CB",
    fontColorString: "#202124"
  )

  public static let locationMaps = EventTag(
    type: .topic,
    name: "Location & Maps",
    tag: "topic_location&maps",
    orderInCategory: 9,
    colorString: "#FEEBB6",
    fontColorString: "#202124"
  )

  public static let openSource = EventTag(
    type: .topic,
    name: "Open Source",
    tag: "topic_opensource",
    orderInCategory: 10,
    colorString: "#FF6C00",
    fontColorString: "#202124"
  )

  public static let web = EventTag(
    type: .topic,
    name: "Web",
    tag: "topic_web",
    orderInCategory: 11,
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
    name: "After Hours",
    tag: "type_afterhours",
    orderInCategory: 0,
    colorString: nil,
    fontColorString: nil
  )

  public static let appReviews = EventTag(
    type: .type,
    name: "App Reviews",
    tag: "type_appreviews",
    orderInCategory: 0,
    colorString: nil,
    fontColorString: nil
  )

  public static let codelabs = EventTag(
    type: .type,
    name: "Codelabs",
    tag: "type_codelabs",
    orderInCategory: 0,
    colorString: nil,
    fontColorString: nil
  )

  public static let officeHours = EventTag(
    type: .type,
    name: "Office Hours",
    tag: "type_officehours",
    orderInCategory: 0,
    colorString: nil,
    fontColorString: nil
  )

  public static let sandbox = EventTag(
    type: .type,
    name: "Sandbox Demos",
    tag: "type_sandboxdemos",
    orderInCategory: 0,
    colorString: nil,
    fontColorString: nil
  )

  public static let sessions = EventTag(
    type: .type,
    name: "Sessions",
    tag: "type_sessions",
    orderInCategory: 1,
    colorString: nil,
    fontColorString: nil
  )

  public static let allTags: [EventTag] = [
    .keynote,
    .accessibility,
    .ads,
    .ARVR,
    .assistant,
    .firebase,
    .flutter,
    .identity,
    .machineLearning,
    .misc,
    .payments,
    .android,
    .nest,
    .cloud,
    .design,
    .iot,
    .locationMaps,
    .openSource,
    .web,
    .beginner,
    .intermediate,
    .advanced,
    .afterHours,
    .appReviews,
    .codelabs,
    .officeHours,
    .sandbox,
    .sessions
  ]

}
