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

import Firebase

class TravelRCDataSource {

  private let remoteConfig = RemoteConfig.remoteConfig()

  func refreshConfig() {
    remoteConfig.fetch { (_, error) in
      guard error == nil else { return }
      // Using the singleton instance here so I don't have to worry about
      // closure retaining self.
      RemoteConfig.remoteConfig().activateFetched()
    }
  }

  func detail(forIndex index: Int) -> InfoDetail {
    let travelDetails = InfoDetail.travelDetails
    switch index {
    case 0 ..< travelDetails.count:
      let detail = travelDetails[index]
      guard let key = TravelRCDataSource.key(forDetail: detail) else { return detail }
      guard let detailText = remoteConfig[key].stringValue else { return detail }
      guard !detailText.isEmpty else { return detail }
      return InfoDetail(title: detail.title, detail: detailText)

    case _:
      fatalError("index out of bounds: \(index)")
    }
  }

  static func key(forDetail detail: InfoDetail) -> String? {
    switch detail {
    case InfoDetail.shuttleService:
      return "info_travel_shuttle"
    case InfoDetail.carpool:
      return "info_travel_parking"
    case InfoDetail.publicTransportation:
      return "info_travel_public_transportation"
    case InfoDetail.biking:
      return "info_travel_biking"
    case InfoDetail.rideShare:
      return "info_travel_ridesharing"

    case _:
      return nil
    }
  }

}
