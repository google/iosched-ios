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

public class AgendaSearchResultsProvider: SearchResultProvider {

  private let agendaItems = AgendaItem.allAgendaItems.flatMap({ return $0 })

  private lazy var fuzzyMatcher = SearchResultsMatcher()

  public var title: String {
    return NSLocalizedString(
      "Agenda",
      comment: """
               The title of the Agenda screen. May also be displayed in search results.
               Good synonyms for this screen are 'itenerary', 'schedule'.
               """
    )
  }

  public func matches(query: String) -> [SearchResult] {
    return fuzzyMatcher.match(query: query, in: agendaItems)
  }

  public func display(searchResult: SearchResult, using navigator: RootNavigator) {
    guard let agendaItem = searchResult.wrappedItem as? AgendaItem else { return }
    navigator.navigateToAgendaItem(agendaItem)
  }

}

extension AgendaSearchResultsProvider {

  public func hash(into hasher: inout Hasher) {
    title.hash(into: &hasher)
  }

}

public func == (lhs: AgendaSearchResultsProvider, rhs: AgendaSearchResultsProvider) -> Bool {
  return lhs.title == rhs.title
}
