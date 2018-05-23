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

public struct MapFeature {
  public let id: String
  public let title: String
  public let subtitle: String?
  public let iconName: String?
  public let longitude: Float
  public let latitude: Float
  public let description: String?
  public let displayZoomLevel: Float?
}

extension MapFeature {

  public init?(dictionary: [String: Any]) {
    guard let id = dictionary["id"] as? String,
      let properties = dictionary["properties"] as? [String: Any],
      let title = properties["title"] as? String,
      let geometry = dictionary["geometry"] as? [String: Any],
      let coordinates = geometry["coordinates"] as? [NSNumber] else {
        return nil
    }

    guard let longitude = coordinates.first?.floatValue,
      let latitude = coordinates.last?.floatValue,
      latitude != longitude else {
        return nil
    }

    // Optional properties
    let subtitle = properties["subtitle"] as? String
    let description = properties["description"] as? String
    let iconName = properties["icon"] as? String
    let displayZoomLevel = (properties["minZoom"] as? NSNumber)?.floatValue

    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.iconName = iconName
    self.longitude = longitude
    self.latitude = latitude
    self.description = description
    self.displayZoomLevel = displayZoomLevel
  }

}
