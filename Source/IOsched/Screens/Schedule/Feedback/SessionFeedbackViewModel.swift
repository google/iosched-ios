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

import MaterialComponents

final class SessionFeedbackViewModel {

  let sessionID: String
  let sessionTitle: String
  let userState: PersistentUserState

  private let feedbackService: FeedbackService

  init(sessionID: String, title: String, userState: PersistentUserState) {
    self.sessionID = sessionID
    sessionTitle = title
    self.userState = userState
    feedbackService = FeedbackService(userState: userState)
  }

  var didSubmitFeedback: Bool {
    return userState.didSubmitFeedback(forSessionWithID: sessionID)
  }

  func submitFeedback(_ survey: FeedbackSurvey, presentingController: UIViewController?) {
    let submittingMessage = MDCSnackbarMessage()
    submittingMessage.text = NSLocalizedString("Submitting feedback...", comment: "Text shown when user has submitted feedback but the request hasn't succeeded or errored yet")
    MDCSnackbarManager.show(submittingMessage)

    // Callback is guaranteed to execute on the main thread by the client library.
    feedbackService.submitFeedback(survey, forSessionWithID: sessionID) { (error) in
      let resultMessage = MDCSnackbarMessage()

      var shouldPopController = false

      if let error = error {

        switch error {

        case .alreadySubmitted:
          resultMessage.text = NSLocalizedString("Feedback already submitted",
              comment: "Text shown when user tries to submit feedback on the same session more than once")
          shouldPopController = true

        case .formNotComplete:
          resultMessage.text = NSLocalizedString("Feedback incomplete",
              comment: "Text shown when user tries to submit feedback before fully filling out the feedback form")

        case .userNotSignedIn:
          // This should be removed once the client supports feedback for signed-out users.
          resultMessage.text = NSLocalizedString("Not signed-in",
              comment: "Text shown when user tries to submit feedback but is signed-out")

        case .apiError:
          // Ignoring the error's contents here since it's mostly debug info not informative to the user.
          // Don't pop the controller here since a retry will probably succeed. Errors like timeout
          // and network change will fall into this category.
          resultMessage.text = NSLocalizedString("Error submitting feedback",
              comment: "Text shown when user feedback submission has failed due to a server error")
        }

      } else {
        shouldPopController = true
        resultMessage.text = NSLocalizedString("Feedback submitted",
            comment: "Text shown when user feedback submission has succeeded")
      }

      if shouldPopController {
        presentingController?.dismiss(animated: true, completion: nil)
      }
      MDCSnackbarManager.show(resultMessage)
    }
  }

}
