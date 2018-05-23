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
import MaterialComponents
import AlamofireImage

class SessionDetailsCollectionViewSpeakerCell: MDCCollectionViewCell {

  private enum Constants {
    static let titleHeight: CGFloat = 14.0
    static let labelHeight: CGFloat = 12.0
    static let titleFontName = "Product Sans"
    static let titleFont = UIFont(name: Constants.titleFontName, size: Constants.titleHeight)
    static let labelFont = UIFont(name: Constants.titleFontName, size: Constants.labelHeight)
    static let titleColor = "#4768fd"
    static let labelColor = "#747474"
  }

  internal lazy var nameLabel: UILabel = self.setupNameLabel()
  internal lazy var companyLabel: UILabel = self.setupCompanyLabel()
  internal lazy var thumbnailImageView: UIImageView = self.setupThumbnailImageView()

  var viewModel: ScheduleEventDetailsSpeakerViewModel? {
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

  func setupNameLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = Constants.titleFont
    label.textColor = UIColor(hex: Constants.titleColor)
    label.numberOfLines = 0
    return label
  }

  func setupCompanyLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = Constants.labelFont
    label.textColor = UIColor(hex: Constants.labelColor)
    label.numberOfLines = 0
    return label
  }

  private func setupThumbnailImageView() -> UIImageView {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.layer.cornerRadius = 28
    imageView.clipsToBounds = true
    return imageView
  }

  private enum LayoutConstants {
    static let thumbnailWidth: CGFloat = 56
    static let thumbnailDownloadWidth = LayoutConstants.thumbnailWidth * UIScreen.main.scale
    static let profilePlaceholderName = "ic_profile_placeholder"
    static let profileImageWidth: CGFloat = LayoutConstants.thumbnailWidth
    static let profileImageHeight: CGFloat = LayoutConstants.thumbnailWidth
    static let profileImageRadius = profileImageHeight / 2.0
    static let transitionDuration: TimeInterval = 0.2
  }

  internal func setupViews() {
    contentView.addSubview(nameLabel)
    contentView.addSubview(companyLabel)
    contentView.addSubview(thumbnailImageView)

    // make cell tappable
    isUserInteractionEnabled = true

    let views = [
      "nameLabel": nameLabel,
      "companyLabel": companyLabel,
      "thumbnailImageView": thumbnailImageView
    ] as [String: Any]

    let metrics = [
      "topMargin": 20,
      "bottomMargin": 20,
      "leftMargin": 16,
      "rightMargin": 16,
      "thumbnailWidth": LayoutConstants.thumbnailWidth
    ]

    var constraints =
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[thumbnailImageView(==thumbnailWidth)]-18-[nameLabel]-(rightMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)
    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[thumbnailImageView]-18-[companyLabel]-(rightMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "V:|-(topMargin)-[thumbnailImageView(==thumbnailWidth)]-(>=bottomMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    constraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "V:|-(topMargin)-[nameLabel][companyLabel]-(>=bottomMargin)-|",
                                     options: [],
                                     metrics: metrics,
                                     views: views)

    NSLayoutConstraint.activate(constraints)
  }

  // MARK: - Model handling

  private func updateFromViewModel() {
    if let viewModel = viewModel {
      nameLabel.text = viewModel.name
      companyLabel.text = viewModel.company

      let placeholder = UIImage(named: LayoutConstants.profilePlaceholderName)
      if let url = viewModel.thumbnailURL {
        let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
          size: CGSize(width: LayoutConstants.profileImageWidth,
                       height: LayoutConstants.profileImageHeight),
          radius: LayoutConstants.profileImageRadius
        )

        let sizeAdjustedURL = url.appendWidth(width: LayoutConstants.thumbnailDownloadWidth)
        thumbnailImageView.af_setImage(withURL: sizeAdjustedURL,
                                       placeholderImage: placeholder,
                                       filter: filter,
                                       imageTransition: .crossDissolve(LayoutConstants.transitionDuration))
      }
      else {
        thumbnailImageView.image = placeholder
      }

      setNeedsLayout()
      invalidateIntrinsicContentSize()
    }
  }

}
