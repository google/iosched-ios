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

import Firebase
import MaterialComponents

class SessionDetailsCollectionViewMainInfoCell: MDCCollectionViewCell {

  private enum Constants {
    static let titleColor = "#424242"
    static let descriptionColor = "#747474"

    static let titleFont = ProductSans.regular.style(.title2)
    static let buttonColor = UIColor.white
    static let rateButtonTitle =
      NSLocalizedString("Rate session",
                        comment: "Button title that will launch session rating.")

    static let processingText = NSLocalizedString(
      "Processing, please wait",
      comment: "Text to show on the reservation button while it's still processing"
    )
    static let rateButtonTitleColor = UIColor(hex: "#5565FD")
    static let rateButtonBorderColor = UIColor(hex: "#DADCE0")
  }

  private lazy var textColor: UIColor = {
    let color = UIColor(hex: Constants.titleColor)
    return color
  }()

  private lazy var titleLabel: UILabel = self.setupTitleLabel()
  private lazy var dateAndTimeLabel: UILabel = self.setupDateAndTimeLabel()
  private lazy var locationLabel: UILabel = self.setupLocationLabel()
  private lazy var detailsLabel: UILabel = self.setupDetailsLabel()
  private lazy var tagContainer: SessionDetailsTagContainerView = self.setupTagContainer()
  private lazy var rateButton: MDCButton = self.setupRateButton()
  private lazy var stackContainer: UIStackView = self.setupStackContainer()
  private lazy var reserveButton: MDCButton = self.setupReserveButton()
  private lazy var reserveButtonConstraints = [NSLayoutConstraint]()
  private lazy var reserveButtonConstraintCollapsed = [NSLayoutConstraint]()

  var viewModel: SessionDetailsViewModel? {
    didSet {
      updateFromViewModel()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - View setup

  private func setupTitleLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = Constants.titleFont
    label.textColor = textColor
    label.numberOfLines = 0

    label.setContentCompressionResistancePriority(.required, for: .vertical)
    label.setContentCompressionResistancePriority(.required, for: .horizontal)

    return label
  }

  private func setupDateAndTimeLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.mdc_preferredFont(forMaterialTextStyle: .body1)
    label.enableAdjustFontForContentSizeCategory()
    label.textColor = textColor
    label.numberOfLines = 0
    return label
  }

  private func setupLocationLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.mdc_preferredFont(forMaterialTextStyle: .body1)
    label.enableAdjustFontForContentSizeCategory()
    label.textColor = textColor
    label.numberOfLines = 0
    return label
  }

  private func setupDetailsLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.mdc_preferredFont(forMaterialTextStyle: .body1)
    label.enableAdjustFontForContentSizeCategory()
    label.textColor = UIColor(hex: Constants.descriptionColor)
    label.numberOfLines = 0
    return label
  }

  private func setupTagContainer() -> SessionDetailsTagContainerView {
    let tagContainer = SessionDetailsTagContainerView()
    tagContainer.translatesAutoresizingMaskIntoConstraints = false
    tagContainer.preferredMaxLayoutWidth = contentView.frame.size.width - 32
    return tagContainer
  }

  private func setupRateButton() -> MDCButton {
    let rateButton = MDCButton()
    rateButton.translatesAutoresizingMaskIntoConstraints = false
    rateButton.setTitle(Constants.rateButtonTitle, for: .normal)
    rateButton.setTitleColor(Constants.rateButtonTitleColor, for: .normal)
    rateButton.isUppercaseTitle = false
    rateButton.setBackgroundColor(Constants.buttonColor, for: .normal)
    rateButton.setBorderColor(Constants.rateButtonBorderColor, for: .normal)
    rateButton.setBorderWidth(1, for: .normal)
    rateButton.sizeToFit()
    rateButton.addTarget(self, action: #selector(rateButtonTapped), for: .touchUpInside)
    return rateButton
  }

  private func setupStackContainer() -> UIStackView {
    let stackContainer = UIStackView(arrangedSubviews: [tagContainer, rateButton])
    stackContainer.translatesAutoresizingMaskIntoConstraints = false
    stackContainer.alignment = .leading
    stackContainer.axis = .vertical
    stackContainer.spacing = 16
    return stackContainer
  }

  private func setupReserveButton() -> MDCRaisedButton {
    let reserveButton = MDCRaisedButton()
    reserveButton.translatesAutoresizingMaskIntoConstraints = false
    reserveButton.sizeToFit()
    reserveButton.isUppercaseTitle = false
    reserveButton.isUserInteractionEnabled = true
    reserveButton.addTarget(self, action: #selector(reserveButtonTapped), for: .touchUpInside)
    return reserveButton
  }

  private func setupViews() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(dateAndTimeLabel)
    contentView.addSubview(locationLabel)
    contentView.addSubview(detailsLabel)
    contentView.addSubview(stackContainer)
    contentView.addSubview(reserveButton)

    let views = [
      "titleLabel": titleLabel,
      "dateAndTimeLabel": dateAndTimeLabel,
      "locationLabel": locationLabel,
      "detailsLabel": detailsLabel,
      "rateButton": rateButton,
      "stackContainer": stackContainer,
      "reserveButton": reserveButton
      ] as [String: Any]

    let metrics = [
      "topMargin": 20,
      "bottomMargin": 16,
      "leftMargin": 16,
      "rightMargin": 16,
      "tagContainerWidth": 300,
      "tagContainerPrio": 750
    ]

    var constraints =
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[titleLabel]-(rightMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)
    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[dateAndTimeLabel]-(rightMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[locationLabel]-(rightMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    constraints +=
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
      NSLayoutConstraint.constraints(withVisualFormat: "V:[rateButton(30)]",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "V:|-(topMargin)-[titleLabel]-16-[dateAndTimeLabel]-[locationLabel]-16-[detailsLabel]-24-[stackContainer]-28-[reserveButton]-(bottomMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    reserveButtonConstraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "V:[reserveButton(56)]",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    reserveButtonConstraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[reserveButton]-(rightMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    reserveButtonConstraintCollapsed +=
      [NSLayoutConstraint(item: reserveButton, attribute: .height, relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)]

    reserveButtonConstraintCollapsed +=
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[reserveButton]-(rightMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    NSLayoutConstraint.activate(constraints)
  }

  // MARK: - Model handling

  private func updateFromViewModel() {
    if let eventViewModel = viewModel?.scheduleEventDetailsViewModel, let processing = viewModel?.processing {
      titleLabel.text = eventViewModel.title
      dateAndTimeLabel.text = eventViewModel.time
      locationLabel.text = eventViewModel.location

      detailsLabel.text = eventViewModel.detail
      detailsLabel.setLineHeightMultiple(1.4)

      tagContainer.viewModel = eventViewModel.tags
      if eventViewModel.canShowRateSessionButton {
        rateButton.sizeToFit()
        rateButton.isHidden = false
      } else {
        rateButton.frame = CGRect.zero
        rateButton.isHidden = true
      }

      if eventViewModel.isReservable && !eventViewModel.reservationTimeCutoffHasPassed {
        NSLayoutConstraint.deactivate(reserveButtonConstraintCollapsed)
        NSLayoutConstraint.activate(reserveButtonConstraints)

        reserveButton.setBackgroundColor(eventViewModel.reserveButtonBackgroundColor, for: .normal)
        reserveButton.setImage(eventViewModel.reserveButtonImage, for: .normal)
        reserveButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 32)
        reserveButton.setTitleColor(eventViewModel.reserveButtonFontColor, for: .normal)

        if processing {
          reserveButton.setTitle(Constants.processingText, for: .normal)
          reserveButton.isUserInteractionEnabled = false
        } else {
          reserveButton.setTitle(eventViewModel.reserveButtonLabel, for: .normal)
          reserveButton.isUserInteractionEnabled = true
        }
      }
      else {
        NSLayoutConstraint.deactivate(reserveButtonConstraints)
        NSLayoutConstraint.activate(reserveButtonConstraintCollapsed)
      }

      invalidateIntrinsicContentSize()
      setNeedsLayout()
      layoutIfNeeded()
    }
  }

  // MARK: - Actions

  @objc func rateButtonTapped() {
    viewModel?.rateSession()
  }

  @objc func reserveButtonTapped() {
    viewModel?.toggleReservation()
    logReservation()
  }

}

// MARK: - Analytics

extension SessionDetailsCollectionViewMainInfoCell {

  fileprivate func logReservation() {
    Application.sharedInstance.analytics.logEvent(AnalyticsEventSelectContent, parameters: [
      AnalyticsParameterItemID: AnalyticsParameters.sessionReserved,
      AnalyticsParameterContentType: AnalyticsParameters.uiEvent,
      AnalyticsParameters.uiAction: AnalyticsParameters.reservation
    ])
  }

}
