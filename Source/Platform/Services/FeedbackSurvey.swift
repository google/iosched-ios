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

public struct FeedbackSurvey {

  public let questions = FeedbackQuestion.defaultQuestions

  /// Ratings from 1-5.
  public var answers: [FeedbackQuestion: Int] = [:]

  public var isComplete: Bool {
    return questions.reduce(true) { (aggregate, next) -> Bool in
      return aggregate && answers[next] != nil
    }
  }

  public init() {}

}

public struct FeedbackQuestion {

  /// A number used to identify the question when submitting.
  public let id: Int

  /// A localized string representing the question body.
  public let body: String

  public static let defaultQuestions = [
    // IDs are from marketing.
    FeedbackQuestion(
      id: 1,
      body: NSLocalizedString("Session rating:",
                              comment: "Localized feedback survey question")
    ),
    FeedbackQuestion(
      id: 2,
      body: NSLocalizedString("Relevancy of session to your projects:",
                              comment: "Localized feedback survey question")
    ),
    FeedbackQuestion(
      id: 3,
      body: NSLocalizedString("Content quality based on your expectations/session description:",
                              comment: "Localized feedback survey question")
    ),
    FeedbackQuestion(
      id: 4,
      body: NSLocalizedString("Speaker quality:", comment: "Localized feedback survey question")
    )
  ]

}

extension FeedbackQuestion: Equatable {}
public func == (lhs: FeedbackQuestion, rhs: FeedbackQuestion) -> Bool {
  return lhs.body == rhs.body && lhs.id == rhs.id
}

extension FeedbackQuestion: Hashable {
  public var hashValue: Int {
    return body.hashValue
  }
}
