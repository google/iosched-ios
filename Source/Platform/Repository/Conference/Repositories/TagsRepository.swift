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
import Domain

protocol TagsRepository: UpdatableRepository {

  var allTopics: [EventTag] { get }

  var allTypes: [EventTag] { get }

  var allLevels: [EventTag] { get }
}

class DefaultTagsRepository: TagsRepository {
  private var datasource: ConferenceData

  lazy private var allTags: [EventTag] = {
    EventTag.allTags
  }()

  init(datasource: ConferenceData) {
    self.datasource = datasource
  }

  func update() {
    // TODO(morganchen): remove this
  }

// MARK: - Accessing elements

  lazy var allTopics: [EventTag] = {
    return allTags.filter { $0.type == .topic }
  }()

  lazy var allTypes: [EventTag] = {
    return allTags.filter { $0.type == .type }
  }()

  lazy var allLevels: [EventTag] = {
    return allTags.filter { $0.type == .level }
  }()

}
