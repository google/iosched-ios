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
import MaterialComponents
import Platform

// TODO(morganchen): Add support for dynamic type accessibility
class SessionFeedbackViewController: BaseCollectionViewController {

  let viewModel: SessionFeedbackViewModel

  let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: "Submit button"),
                                     style: .done,
                                     target: self,
                                     action: #selector(submitButtonPressed(_:)))

  let cancelButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: "Cancel button"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(cancelButtonPressed(_:)))

  fileprivate var survey = FeedbackSurvey()

  convenience init(sessionID: String, title: String, userState: WritableUserState) {
    let viewModel = SessionFeedbackViewModel(sessionID: sessionID,
                                             title: title,
                                             userState: userState)
    self.init(viewModel: viewModel)
  }

  required init(viewModel: SessionFeedbackViewModel) {
    self.viewModel = viewModel
    super.init(collectionViewLayout: MDCCollectionViewFlowLayout())
  }

  @objc override func setupViews() {
    super.setupViews()
    collectionView?.register(SessionFeedbackCollectionViewCell.self,
                             forCellWithReuseIdentifier: SessionFeedbackCollectionViewCell.reuseIdentifier())
    collectionView?.register(FeedbackHeader.self,
                             forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                             withReuseIdentifier: FeedbackHeader.identifier)

    self.title = NSLocalizedString("Feedback", comment: "Feedback screen title")

    navigationItem.leftBarButtonItem = cancelButton
    navigationItem.rightBarButtonItem = submitButton
    submitButton.isEnabled = false
  }

  @objc override func setupAppBar() -> MDCAppBar {
    let bar = super.setupAppBar()
    let statusBarHeight = UIApplication.shared.statusBarFrame.height
    bar.headerViewController.headerView.minimumHeight = statusBarHeight + 40
    bar.headerViewController.headerView.maximumHeight = statusBarHeight + 60
    return bar
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("NSCoding not supported for controller of type \(SessionFeedbackViewController.self)")
  }

}

// MARK: - Submitting feedback

extension SessionFeedbackViewController: SessionFeedbackRatingDelegate {

  @objc func cancelButtonPressed(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }

  @objc func submitButtonPressed(_ sender: Any) {
    viewModel.submitFeedback(survey, presentingController: self)
  }

  func cell(_ cell: SessionFeedbackCollectionViewCell,
            didChangeRating rating: Int?,
            for feedbackQuestion: FeedbackQuestion) {
    survey.answers[feedbackQuestion] = rating
    submitButton.isEnabled = canSubmitFeedback
  }

  var canSubmitFeedback: Bool {
    return survey.isComplete
  }

}

// MARK: - UICollectionViewDataSource

extension SessionFeedbackViewController {

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return survey.questions.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let reuseIdentifier = SessionFeedbackCollectionViewCell.reuseIdentifier()
    // swiftlint:disable force_cast
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                  for: indexPath) as! SessionFeedbackCollectionViewCell
    // swiftlint:enable force_cast

    let question = survey.questions[indexPath.row]
    let rating = survey.answers[question]
    cell.populate(question: question,
                  rating: rating,
                  delegate: self,
                  didSubmitFeedback: viewModel.didSubmitFeedback)
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
    // swiftlint:disable force_cast
    let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                               withReuseIdentifier: FeedbackHeader.identifier,
                                                               for: indexPath) as! FeedbackHeader
    // swiftlint:enable force_cast
    view.populate(title: viewModel.sessionTitle, feedbackSubmitted: viewModel.didSubmitFeedback)
    return view
  }

}

// MARK: - UICollectionViewDelegateFlowLayout

extension SessionFeedbackViewController {

  override func collectionView(_ collectionView: UICollectionView,
                               cellHeightAt indexPath: IndexPath) -> CGFloat {
    let question = survey.questions[indexPath.row]
    return SessionFeedbackCollectionViewCell.heightForCell(withTitle: question.body,
                                                           maxWidth: view.frame.width)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    let width = self.view.frame.width
    let height = FeedbackHeader.height(withTitle: viewModel.sessionTitle,
                                       maxWidth: width,
                                       submittedFeedback: viewModel.didSubmitFeedback)
    return CGSize(width: width, height: height)
  }

}
