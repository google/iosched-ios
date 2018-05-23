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

public struct Speaker {
  public let id: String
  public let name: String
  public let bio: String
  public let company: String
  public let thumbnailUrl: URL?
  public let plusOneUrl: URL?
  public let twitterUrl: URL?
  public let linkedinUrl: URL?
  public let githubUrl: URL?
  public let websiteUrl: URL?

  public init(id: String,
              name: String,
              bio: String,
              company: String,
              thumbnailUrl: URL?,
              plusOneUrl: URL?,
              twitterUrl: URL?,
              linkedinUrl: URL?,
              githubUrl: URL?,
              websiteUrl: URL?) {
    self.id = id
    self.name = name
    self.bio = bio
    self.company = company
    self.thumbnailUrl = thumbnailUrl
    self.plusOneUrl = plusOneUrl
    self.twitterUrl = twitterUrl
    self.linkedinUrl = linkedinUrl
    self.githubUrl = githubUrl
    self.websiteUrl = websiteUrl
  }
}

extension Speaker: Equatable { }

public func == (lhs: Speaker, rhs: Speaker) -> Bool {
  return lhs.id == rhs.id
    && lhs.name == rhs.name
}
