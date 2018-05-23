//
//  Copyright (c) 2019 Google Inc.
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

public class InfoDetailSearchProvider: SearchResultProvider {

  public func display(searchResult: SearchResult, using navigator: RootNavigator) {
    guard let info = searchResult.wrappedItem as? InfoDetail else { return }
    navigator.navigateToInfoItem(info)
  }

  private lazy var fuzzyMatcher = SearchResultsMatcher()

  public var title: String {
    return NSLocalizedString(
      "Info",
      comment: "Title of the Info screen. This may also be displayed over search results."
    )
  }

  public func matches(query: String) -> [SearchResult] {
    return fuzzyMatcher.match(query: query, in: InfoDetail.allInfoDetails)
  }

}

public extension InfoDetailSearchProvider {

  func hash(into hasher: inout Hasher) {
    title.hash(into: &hasher)
  }

}

public func == (lhs: InfoDetailSearchProvider, rhs: InfoDetailSearchProvider) -> Bool {
  return lhs.title == rhs.title
}
