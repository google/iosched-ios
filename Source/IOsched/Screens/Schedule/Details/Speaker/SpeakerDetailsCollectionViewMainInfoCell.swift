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
import SafariServices

class SpeakerDetailsCollectionViewMainInfoCell: MDCCollectionViewCell {

  private lazy var detailsLabel: UILabel = self.setupDetailsLabel()
  private lazy var twitterButton: MDCButton = self.setupTwitterButton()
  private lazy var stackContainer: UIStackView = self.setupStackContainer()
  private lazy var spacerView: UIView = self.setupSpacerView()

  var viewModel: SpeakerDetailsMainInfoViewModel? {
    didSet {
      updateFromViewModel()
    }
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  // MARK: - View setup

  private func setupViews() {
    contentView.addSubview(detailsLabel)
    contentView.addSubview(stackContainer)

    let views = [
      "detailsLabel": detailsLabel,
      "stackContainer": stackContainer
      ] as [String: Any]

    let metrics = [
      "topMargin": 20,
      "bottomMargin": 20,
      "leftMargin": 16,
      "rightMargin": 16
    ]

    var constraints =
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[detailsLabel]-(rightMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[stackContainer]-(rightMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "V:|-(topMargin)-[detailsLabel]-[stackContainer]-(bottomMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    NSLayoutConstraint.activate(constraints)
  }

  private func setupStackContainer() -> UIStackView {
    let stackContainer = UIStackView()
    stackContainer.addArrangedSubview(spacerView)
    stackContainer.translatesAutoresizingMaskIntoConstraints = false
    stackContainer.distribution = .fill
    stackContainer.axis = .horizontal
    stackContainer.spacing = 24
    stackContainer.isUserInteractionEnabled = true
    return stackContainer
  }

  private func setupSpacerView() -> UIView {
    let spacerView = UIView()
    spacerView.translatesAutoresizingMaskIntoConstraints = false
    spacerView.backgroundColor = UIColor.clear
    return spacerView
  }

  private func setupTwitterButton() -> MDCButton {
    let twitterButton = MDCFlatButton()
    twitterButton.isUppercaseTitle = false
    twitterButton.translatesAutoresizingMaskIntoConstraints = false
    twitterButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    twitterButton.addTarget(self, action: #selector(twitterTapped), for: .touchUpInside)
    twitterButton.setImage(UIImage(named: "ic_twitter"), for: .normal)
    twitterButton.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
    return twitterButton
  }

  @objc func twitterTapped() {
    viewModel?.twitterTapped()
  }

  private func setupDetailsLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.mdc_preferredFont(forMaterialTextStyle: .body1)
    label.enableAdjustFontForContentSizeCategory()
    label.textColor = MDCPalette.grey.tint800
    label.numberOfLines = 0
    return label
  }

  // MARK: - Model handling

  private func updateFromViewModel() {
    if let viewModel = viewModel {
      detailsLabel.text = viewModel.bio
      detailsLabel.setLineHeightMultiple(1.4)

      if viewModel.twitterURL != nil {
        stackContainer.insertArrangedSubview(twitterButton, at: 0)
      }

      // make cell tappable for the twitter and plus url buttons
      isUserInteractionEnabled = true

      setNeedsLayout()
      layoutIfNeeded()
      invalidateIntrinsicContentSize()
    }
  }
}
