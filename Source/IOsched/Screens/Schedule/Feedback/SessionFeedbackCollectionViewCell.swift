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
import Platform

protocol SessionFeedbackRatingDelegate: NSObjectProtocol {

  func cell(_ cell: SessionFeedbackCollectionViewCell,
            didChangeRating rating: Int?,
            `for` feedbackQuestion: FeedbackQuestion)

}

class SessionFeedbackCollectionViewCell: MDCCollectionViewCell {

  private enum Constants {
    static let padding: CGFloat = 16

    static let bodyFont = UIFont.preferredFont(forTextStyle: .body)

    static let contentTextColor = UIColor(red: 66 / 255, green: 66 / 255, blue: 66 / 255, alpha: 1)
  }

  let titleLabel = UILabel()

  let ratingView = RatingView()

  private var feedbackQuestion: FeedbackQuestion?

  weak var delegate: SessionFeedbackRatingDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(titleLabel)
    contentView.addSubview(ratingView)

    setupTitleLabel()
    setupRatingView()
    setupConstraints()
  }

  func setupTitleLabel() {
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.numberOfLines = 0
    titleLabel.lineBreakMode = .byWordWrapping
    titleLabel.font = Constants.bodyFont
    titleLabel.textColor = Constants.contentTextColor
  }

  func setupRatingView() {
    ratingView.translatesAutoresizingMaskIntoConstraints = false
    ratingView.addTarget(self, action: #selector(ratingDidChange(_:)), for: .valueChanged)
  }

  func setupConstraints() {
    var constraints: [NSLayoutConstraint] = []

    // title label top
    constraints.append(NSLayoutConstraint(item: titleLabel,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .top,
                                          multiplier: 1,
                                          constant: Constants.padding))
    // title label left
    constraints.append(NSLayoutConstraint(item: titleLabel,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: Constants.padding))
    // title label right
    constraints.append(NSLayoutConstraint(item: titleLabel,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: -Constants.padding))
    // rating view top
    constraints.append(NSLayoutConstraint(item: ratingView,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: titleLabel,
                                          attribute: .bottom,
                                          multiplier: 1,
                                          constant: Constants.padding))
    // rating view center
    constraints.append(NSLayoutConstraint(item: ratingView,
                                          attribute: .centerX,
                                          relatedBy: .equal,
                                          toItem: contentView,
                                          attribute: .centerX,
                                          multiplier: 1,
                                          constant: 0))

    contentView.addConstraints(constraints)
  }

  func populate(question: FeedbackQuestion,
                rating: Int?,
                delegate: SessionFeedbackRatingDelegate?,
                didSubmitFeedback: Bool = false) {
    feedbackQuestion = question
    titleLabel.text = question.body
    ratingView.accessibilityLabel = question.body
    ratingView.rating = rating
    self.delegate = delegate

    if didSubmitFeedback {
      isUserInteractionEnabled = false
    } else {
      isUserInteractionEnabled = true
    }
  }

  @objc private func ratingDidChange(_ sender: Any) {
    guard let view = sender as? RatingView else { return }
    guard view === ratingView else { return }
    delegate?.cell(self, didChangeRating: ratingView.rating, for: feedbackQuestion!)
  }

  override func prepareForReuse() {
    delegate = nil
    feedbackQuestion = nil
  }

  static func heightForCell(withTitle title: String, maxWidth: CGFloat) -> CGFloat {
    let titleHeight = title.boundingRect(with: CGSize(width: maxWidth - 2 * Constants.padding,
                                                      height: .greatestFiniteMagnitude),
                                         options: [.usesLineFragmentOrigin],
                                         attributes: [NSAttributedStringKey.font: Constants.bodyFont],
                                         context: nil).height
    return titleHeight + Constants.padding * 3 + /* rating view height */ 50
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("NSCoding not supported for cell of type: \(SessionFeedbackCollectionViewCell.self)")
  }

}

// TODO(morganchen): Add support for dynamic type
class FeedbackHeader: UICollectionReusableView {

  private enum Constants {
    static let font = UIFont.preferredFont(forTextStyle: .title2)
    static let textColor = UIColor(red: 66 / 255, green: 66 / 255, blue: 66 / 255, alpha: 1)

    static let padding: CGFloat = 16

    static let submittedFont = UIFont.preferredFont(forTextStyle: .callout)
    static let submittedBackgroundColor = UIColor(red: 28 / 255, green: 232 / 255, blue: 181 / 255, alpha: 1)

    static let submittedText = NSLocalizedString("You've already submitted feedback for this session.", comment: "Describing a session the user has already reviewed")
  }

  static let identifier = "FeedbackHeader"

  private let label = UILabel()

  private var didSubmitFeedback: Bool {
    didSet {
      removeSubmittedLabel()
      if didSubmitFeedback {
        addSubmittedLabel()
        setNeedsLayout()
      }
    }
  }

  private let submittedLabel = UILabel()
  private let submittedLabelContainer = UIView()

  override init(frame: CGRect) {
    didSubmitFeedback = false
    super.init(frame: frame)

    backgroundColor = .white
    addSubview(label)
    addSubview(submittedLabelContainer)

    setupLabel()
    setupSubmittedLabelContainer()
    setupSubmittedLabel()
    setupConstraints()
  }

  private func setupLabel() {
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.textColor = Constants.textColor
    label.font = Constants.font
  }

  private func setupConstraints() {
    var constraints: [NSLayoutConstraint] = []

    // label top
    constraints.append(NSLayoutConstraint(item: label,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .top,
                                          multiplier: 1,
                                          constant: Constants.padding))
    // label left
    constraints.append(NSLayoutConstraint(item: label,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: Constants.padding))
    // label right
    constraints.append(NSLayoutConstraint(item: label,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: -Constants.padding))
    // submitted container view top
    constraints.append(NSLayoutConstraint(item: submittedLabelContainer,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: label,
                                          attribute: .bottom,
                                          multiplier: 1,
                                          constant: Constants.padding))
    // submitted container view left
    constraints.append(NSLayoutConstraint(item: submittedLabelContainer,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 0))
    // submitted container view right
    constraints.append(NSLayoutConstraint(item: submittedLabelContainer,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: 0))
    // submitted container view bottom
    constraints.append(NSLayoutConstraint(item: submittedLabelContainer,
                                          attribute: .bottom,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .bottom,
                                          multiplier: 1,
                                          constant: 0))

    addConstraints(constraints)
  }

  private func addSubmittedLabel(withText text: String = Constants.submittedText) {
    submittedLabel.text = text
    submittedLabelContainer.addSubview(submittedLabel)

    var constraints: [NSLayoutConstraint] = []

    // submitted label top
    constraints.append(NSLayoutConstraint(item: submittedLabel,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: submittedLabelContainer,
                                          attribute: .top,
                                          multiplier: 1,
                                          constant: Constants.padding))
    // submitted label left
    constraints.append(NSLayoutConstraint(item: submittedLabel,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: submittedLabelContainer,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: Constants.padding))
    // submitted label right
    constraints.append(NSLayoutConstraint(item: submittedLabel,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: submittedLabelContainer,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: -Constants.padding))

    submittedLabelContainer.addConstraints(constraints)
  }

  private func removeSubmittedLabel() {
    submittedLabelContainer.removeConstraints(submittedLabelContainer.constraints)
    submittedLabelContainer.subviews.forEach {
      $0.removeFromSuperview()
    }
  }

  private static func submittedLabelHeight(withText text: String = Constants.submittedText,
                                           maxWidth: CGFloat) -> CGFloat {
    let textHeight = text.boundingRect(with: CGSize(width: maxWidth - Constants.padding * 2,
                                                    height: .greatestFiniteMagnitude),
                                       options: [.usesLineFragmentOrigin],
                                       attributes: [NSAttributedStringKey.font: Constants.submittedFont],
                                       context: nil).size.height
    return textHeight + 2 * Constants.padding
  }

  private func setupSubmittedLabelContainer() {
    submittedLabelContainer.translatesAutoresizingMaskIntoConstraints = false
    submittedLabelContainer.backgroundColor = Constants.submittedBackgroundColor
  }

  private func setupSubmittedLabel() {
    submittedLabel.translatesAutoresizingMaskIntoConstraints = false
    submittedLabel.font = Constants.submittedFont
    submittedLabel.textColor = Constants.textColor
    submittedLabel.numberOfLines = 0
  }

  func populate(title: String, feedbackSubmitted: Bool) {
    label.text = title
    didSubmitFeedback = feedbackSubmitted
  }

  static func height(withTitle title: String,
                     maxWidth: CGFloat,
                     submittedFeedback: Bool) -> CGFloat {
    let submittedHeight = submittedFeedback ? submittedLabelHeight(maxWidth: maxWidth) : 0
    let textHeight = title.boundingRect(with: CGSize(width: maxWidth - Constants.padding * 2,
                                                     height: .greatestFiniteMagnitude),
                                        options: [.usesLineFragmentOrigin],
                                        attributes: [NSAttributedStringKey.font: Constants.font],
                                        context: nil).size.height
    return textHeight + 2 * Constants.padding + submittedHeight
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
