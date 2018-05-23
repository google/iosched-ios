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

// swiftlint:disable all

import Foundation
import MapKit
import UIKit

class MapViewModel {

  private enum Constants {
    static let stagesTitle =
        NSLocalizedString("Stages", comment: "Title for stages section header in map filters.")
    static let sandboxesTitle =
        NSLocalizedString("Sandboxes", comment: "Title for sandboxes section header in map filters.")
    static let servicesTitle =
        NSLocalizedString("Services", comment: "Title for services section header in map filters.")
  }

  var mapItems = [MapItemViewModel]()

  init() {}

  func update(for variant: MapViewController.MapVariant) {
    mapItems = markers(for: variant)
  }

  private func markers(for variant: MapViewController.MapVariant) -> [MapItemViewModel] {
    let fileName = "markers_\(variant.rawValue)"

    guard let markersFileURL = Bundle.main.url(forResource: fileName,
                                               withExtension: "json") else {
      print("Unable to find map markers json in bundle.")
      return []
    }
    guard let jsonData = try? Data(contentsOf: markersFileURL) else {
      print("Malformed map marker JSON at url: \(markersFileURL)")
      return []
    }
    guard let jsonResult = (try? JSONSerialization.jsonObject(with: jsonData,
                                                             options: [])) as? [String: Any] else {
      print("Unable to serialize json at url: \(markersFileURL)")
      return []
    }
    guard let featureList = jsonResult["features"] as? [[String: Any]] else {
      print("Map markers json missing features key: \(jsonResult.keys)")
      return []
    }

    var features: [MapFeature] = []
    for item in featureList {
      if let feature = MapFeature(dictionary: item) {
        features.append(feature)
      }
    }
    return features.map(MapItemViewModel.init(feature:))
  }

}

class MapItemViewModel {
  let iconName: String?
  let id: String
  let title: String
  let subtitle: String?
  let longitude: CLLocationDegrees
  let latitude: CLLocationDegrees
  let displayZoomLevel: Float?
  let description: String?
  var selected: Bool

  init(feature: MapFeature) {
    id = feature.id
    iconName = feature.iconName
    title = feature.title
    subtitle = feature.subtitle
    description = feature.description
    longitude = CLLocationDegrees(feature.longitude)
    latitude = CLLocationDegrees(feature.latitude)
    selected = false
    displayZoomLevel = feature.displayZoomLevel
  }

}

class FilterSectionViewModel {
  let name: String
  let items: [MapItemViewModel]
  var expanded: Bool

  init(name: String, items: [MapItemViewModel]) {
    self.name = name
    self.items = items
    expanded = false
  }
}

// swiftlint:enable all
