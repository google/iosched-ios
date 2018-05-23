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

class SpeakerDetailsCollectionViewSpeakerCell: SessionDetailsCollectionViewSpeakerCell {

  private enum LayoutConstants {
    static let thumbnailWidth: CGFloat = 56
    static let profilePlaceholderName = "ic_profile_placeholder"
    static let profileImageWidth: CGFloat = LayoutConstants.thumbnailWidth
    static let profileImageHeight: CGFloat = LayoutConstants.thumbnailWidth
    static let profileImageRadius = profileImageHeight / 2.0
    static let transitionDuration: TimeInterval = 0.2

    static let titleColor = "#4768fd"
    static let labelColor = "#747474"

    static let titleHeight: CGFloat = 14.0
    static let titleFontName = "Product Sans"
    static let titleFont = UIFont(name: LayoutConstants.titleFontName, size: LayoutConstants.titleHeight)

    static let priorityHigherThanHigh: Float = 751.0
  }

  override func setupNameLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = LayoutConstants.titleFont
    label.textColor = UIColor(hex: LayoutConstants.titleColor)
    label.numberOfLines = 0
    return label
  }

  override func setupCompanyLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.mdc_preferredFont(forMaterialTextStyle: .caption)
    label.enableAdjustFontForContentSizeCategory()
    label.textColor = UIColor(hex: LayoutConstants.labelColor)
    label.numberOfLines = 0
    return label
  }

  internal override func setupViews() {
    super.setupViews()
    isUserInteractionEnabled = false
    contentView.backgroundColor = UIColor.clear
  }
}
