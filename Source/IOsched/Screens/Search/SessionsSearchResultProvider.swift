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

public class SessionSearchResultProvider: SearchResultProvider {

  private let sessionsDataSource: LazyReadonlySessionsDataSource
  private lazy var fuzzyMatcher = SearchResultsMatcher()
  private weak var navigationController: UINavigationController?

  public init(sessions: LazyReadonlySessionsDataSource,
              navigationController: UINavigationController?) {
    sessionsDataSource = sessions
    self.navigationController = navigationController
  }

  public var title: String {
    return NSLocalizedString(
      "Sessions",
      comment: "Category header for sessions in search results."
    )
  }

  public var allEvents: [Session] {
    return sessionsDataSource.sessions
  }

  public var relevantEvents: [Session] {
    return sessionsDataSource.sessions.filter { $0.type == .sessions }
  }

  public func matches(query: String) -> [SearchResult] {
    return fuzzyMatcher.match(query: query, in: relevantEvents)
  }

  public func display(searchResult: SearchResult, using navigator: RootNavigator) {
    guard let session = searchResult.wrappedItem as? Session else { return }
    navigator.navigateInSearchResults(to: session)
  }

}

extension SessionSearchResultProvider: Hashable {

  public func hash(into hasher: inout Hasher) {
    title.hash(into: &hasher)
  }

}

public func == (lhs: SessionSearchResultProvider, rhs: SessionSearchResultProvider) -> Bool {
  return lhs.title == rhs.title
}
