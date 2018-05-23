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

/// A data type representing a session speaker.
public struct Speaker {

  /// A unique ID assigned to each speaker.
  public let id: String

  /// The speaker's full name.
  public let name: String

  /// A short paragraph describing the speaker.
  public let bio: String

  /// The company the speaker works at.
  public let company: String

  /// The speaker's photo URL, if provided.
  public let thumbnailURL: URL?

  /// A link to the speaker's twitter profile.
  public let twitterURL: URL?

  /// A link to the speaker's linkedin profile.
  public let linkedinURL: URL?

  /// A link to the speaker's GitHub profile.
  public let githubURL: URL?

  /// A link to the speaker's personal website.
  public let websiteURL: URL?

  public init(id: String,
              name: String,
              bio: String,
              company: String,
              thumbnailURL: URL?,
              twitterURL: URL?,
              linkedinURL: URL?,
              githubURL: URL?,
              websiteURL: URL?) {
    self.id = id
    self.name = name
    self.bio = bio
    self.company = company
    self.thumbnailURL = thumbnailURL
    self.twitterURL = twitterURL
    self.linkedinURL = linkedinURL
    self.githubURL = githubURL
    self.websiteURL = websiteURL
  }
}

extension Speaker: Equatable { }

public func == (lhs: Speaker, rhs: Speaker) -> Bool {
  return lhs.id == rhs.id
    && lhs.name == rhs.name
}

extension Speaker: Hashable {}
