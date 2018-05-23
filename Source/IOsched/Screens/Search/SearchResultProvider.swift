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

public struct SearchResult: Equatable {

  /// A title for the given search result. For example, if the result is a session,
  /// this string should be the session title.
  var title: String

  /// A description for the given search result. May be truncated via trailing ellipses.
  var subtext: String

  /// How closely the result fits the search string.
  var matchAccuracy: SearchResultMatchAccuracy

  /// The original item that was returned as a search result.
  var wrappedItem: Any

}

public func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
  return lhs.title == rhs.title && lhs.subtext == rhs.subtext
}

public enum SearchResultMatchAccuracy {
  case exact
  case partial
}

/// A type responsible for surfacing search results.
public protocol SearchResultProvider: Hashable {

  /// A localized string displayed above the section containing this provider's search results.
  var title: String { get }

  /// Search results for a given query.
  func matches(query: String) -> [SearchResult]

  /// This method is called when the user taps on a search result.
  func display(searchResult: SearchResult, using navigator: RootNavigator)

}

private struct ConcreteSearchResultProvider<T: SearchResultProvider>: SearchResultProvider {

  private let provider: T

  public init(provider: T) {
    self.provider = provider
  }

  public var title: String {
    return provider.title
  }

  public func matches(query: String) -> [SearchResult] {
    return provider.matches(query: query)
  }

  public func display(searchResult: SearchResult, using navigator: RootNavigator) {
    provider.display(searchResult: searchResult, using: navigator)
  }

}

/// A provider that wraps SearchResultProvider and performs its searches asynchronously.
public class AsyncSearchResultProvider: Hashable {

  private static let searchOperationQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.name = "com.google.iosched.search"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()

  private let _title: String
  private let _matches: (String) -> [SearchResult]
  private let _display: (SearchResult, RootNavigator) -> Void

  public init<T>(_ provider: T) where T: SearchResultProvider {
    let concreteProvider = ConcreteSearchResultProvider<T>(provider: provider)
    _title = concreteProvider.title
    _matches = { value in return provider.matches(query: value) }
    _display = { result, navigator in provider.display(searchResult: result, using: navigator) }
  }

  public var title: String {
    return _title
  }

  private var pendingOperation: BlockOperation?

  public func matches(query: String, completion: @escaping ([SearchResult]) -> Void) {
    if let operation = pendingOperation {
      operation.cancel()
    }
    let match = _matches

    let operation = BlockOperation {
      let matches = match(query)
      OperationQueue.main.addOperation {
        completion(matches)
      }
    }
    pendingOperation = operation
    AsyncSearchResultProvider.searchOperationQueue.addOperation(operation)
  }

  public func display(searchResult: SearchResult, using navigator: RootNavigator) {
    _display(searchResult, navigator)
  }

  public func hash(into hasher: inout Hasher) {
    title.hash(into: &hasher)
  }

}

public func == (lhs: AsyncSearchResultProvider, rhs: AsyncSearchResultProvider) -> Bool {
  return lhs.title == rhs.title
}
