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

public class Configuration {

  public static let sharedInstance = Configuration()
  private init() {
    configurationFilePath = Bundle.main.path(forResource: Constants.configFileName,
                                             ofType: Constants.configFileExtension)
    if let configurationFilePath = configurationFilePath {
      configuration = NSDictionary(contentsOfFile: configurationFilePath)
    }
  }

  private lazy var googleServiceInfo: [String: Any] = {
    let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
    if let plist = path.flatMap(NSDictionary.init(contentsOfFile:)) {
      return plist as? [String: Any] ?? [:]
    }
    fatalError("Unable to locate GoogleService-Info.plist")
  }()

  private enum Constants {
    static let configFileName = "configuration"
    static let configFileExtension = "plist"

    /// Google Maps API key
    static let mapsKey = "GOOGLE_MAPS_KEY"

    /// Base URL of the Google Cloud Storage bucket containing the conference schedule data
    static let scheduleDataBaseUrl = "SCHEDULE_DATA_BASE_URL"

    static let registrationEndpointKey = ""
  }

  private var configurationFilePath: String?
  private var configuration: NSDictionary?

  public lazy var googleMapsApiKey: String = {
    let apiKey = self.configuration?[Constants.mapsKey] as? String
    assert(apiKey != "" && apiKey != nil, "Google maps API key not available. Check configuration.plist.")
    return apiKey ?? ""
  }()

  public lazy var registrationEndpoint: String = {
    guard let projectID = googleServiceInfo["PROJECT_ID"] as? String else {
      fatalError("GoogleService-Info.plist does not contain a valid project ID")
    }

    return "https://\(projectID).appspot.com/_ah/api/registration/v1/register"
  }()

}
