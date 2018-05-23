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

public protocol Searchable {

  var title: String { get }

  var subtext: String { get }

}

public class SearchResultsMatcher {

  private lazy var linguisticTagger: NSLinguisticTagger = {
    let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
    return tagger
  }()

  private lazy var queryTokenizer: NSLinguisticTagger = {
    let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
    return tagger
  }()

  let resultLimit = 20

  private func enumerateQueryTokens(query: String, _ closure: @escaping (String) -> Void) {
    let range = NSRange(location: 0, length: query.utf16.count)
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
    queryTokenizer.string = query

    let tagHandler: (NSLinguisticTag?, NSRange) -> Void = { tag, range in
      guard tag != nil else { return }
      let taggedString = (query as NSString).substring(with: range)
      closure(taggedString)
    }

    if #available(iOS 11, *) {
      queryTokenizer.enumerateTags(in: range,
                                   unit: .word,
                                   scheme: .tokenType,
                                   options: options) { (tag, range, _) in
        tagHandler(tag, range)
      }
    } else {
      queryTokenizer.enumerateTags(in: range,
                                   scheme: .tokenType,
                                   options: options) { (tag, tokenRange, _, _) in
        tagHandler(tag, tokenRange)
      }
    }
  }

  public func fuzzyMatch(_ query: String, in text: String) -> Double {
    var matches: Double = 0
    let lowercaseQuery = query.lowercased()
    let tagger = linguisticTagger
    let range = NSRange(location: 0, length: text.utf16.count)
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
    tagger.string = text

    let tagMatcher: (NSLinguisticTag?, NSRange) -> Void = { tag, range in
      guard let tag = tag, tag == .noun else { return }
      let taggedString = (text as NSString).substring(with: range).lowercased()

      self.enumerateQueryTokens(query: lowercaseQuery) { (queryFragment) in
        let partialMatch: Double = taggedString.contains(queryFragment) ? 1 : 0
        matches += partialMatch
      }
    }

    if #available(iOS 11.0, *) {
      tagger.enumerateTags(in: range,
                           unit: .word,
                           scheme: .lexicalClass,
                           options: options) { (tag, range, _) in
        tagMatcher(tag, range)
      }
    } else {
      tagger.enumerateTags(in: range,
                           scheme: .lexicalClass,
                           options: options) { (tag, tokenRange, _, _) in
        tagMatcher(tag, tokenRange)
      }
    }
    return matches
  }

  /// The matches for a query in an item. There may be more than one.
  public func match<T: Searchable>(query: String,
                                   in items: [T]) -> [SearchResult] {
    var fuzzyMatchResults: [(Double, T)] = []
    let threshold: Double = 1

    for item in items {
      let matches = [
        fuzzyMatch(query, in: item.title),
        fuzzyMatch(query, in: item.subtext)
      ]

      var highestMatch: Double = 0
      for match in matches where highestMatch < match {
        highestMatch = match
      }
      if highestMatch >= threshold {
        fuzzyMatchResults.append((highestMatch, item))
      }
    }

    fuzzyMatchResults.sort { (lhs, rhs) -> Bool in
      return lhs.0 > rhs.0
    }

    return fuzzyMatchResults.prefix(resultLimit).map {
      let accuracy: SearchResultMatchAccuracy = .partial
      return SearchResult(title: $0.1.title,
                          subtext: $0.1.subtext,
                          matchAccuracy: accuracy,
                          wrappedItem: $0.1)
    }
  }

}

extension InfoDetail: Searchable {

  public var subtext: String {
    return attributedDescription()?.string ?? ""
  }

}

extension Session: Searchable {

  public var subtext: String {
    return detail
  }

}

extension AgendaItem: Searchable {

  public var subtext: String {
    return displayableTimeInterval
  }

}
