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

import Domain
import FirebaseAuth
import FirebaseFunctions

public enum FeedbackError: Error {

  case alreadySubmitted
  case formNotComplete
  case userNotSignedIn
  case feedbackNotReceived

  case apiError(Error)
}

public final class FeedbackService {

  private let userState: WritableUserState

  private lazy var firebaseFunctions = Functions.functions()

  public func submitFeedback(_ survey: FeedbackSurvey,
                             forSessionWithID sessionID: String,
                             completion: @escaping (FeedbackError?) -> Void) {

    guard survey.isComplete else {
      completion(FeedbackError.formNotComplete)
      return
    }

    guard !userState.didSubmitFeedback(forSessionWithID: sessionID) else {
      completion(FeedbackError.alreadySubmitted)
      return
    }

    let auth = Auth.auth()
    guard auth.currentUser != nil else {
      completion(FeedbackError.userNotSignedIn)
      return
    }

    self.submitRating(forSessionWithID: sessionID, survey: survey, completion: { (error) in
      if error == nil {
        self.userState.setFeedbackSubmitted(true, forSessionWithID: sessionID)
      }
      completion(error)
    })
  }

  public init(userState: WritableUserState) {
    self.userState = userState
  }

// MARK: - Private Functions

  func submitRating(forSessionWithID sessionID: String, survey: FeedbackSurvey,
                    completion: @escaping (FeedbackError?) -> Void) {
    var responses: [String: Int] = ["q1": 0, "q2": 0, "q3": 0, "q4": 0]
    for (question, answer) in survey.answers {
      let qId: String = "q" + String(question.id)
      responses[qId] = answer
    }
    let feedback: [String: Any] = ["sessionId": sessionID, "responses": responses]
    firebaseFunctions.httpsCallable("sendFeedback").call(feedback) { (_, error) in
      if let error = error as NSError? {
        if error.domain == FunctionsErrorDomain {
            let code = FunctionsErrorCode(rawValue: error.code) ?? .unknown
          let message = error.localizedDescription
          let details = error.userInfo[FunctionsErrorDetailsKey] ?? "(nil)"
          print("Error Code=\(code); message=\(message):\(details); error: \(error)")
          completion(FeedbackError.feedbackNotReceived)
          return
        }
      }
      completion(nil)
    }
  }
}
