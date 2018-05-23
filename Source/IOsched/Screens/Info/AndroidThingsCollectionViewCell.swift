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

class AndroidThingsCollectionViewCell: MDCCollectionViewCell {

  static var scavengerHuntURL = URL(string: "https://g.co/iosearch")!

  private static var titleColor: UIColor {
    return UIColor(red: 74 / 255, green: 74 / 255, blue: 74 / 255, alpha: 1)
  }

  private var bodyTextColor: UIColor {
    return UIColor(red: 20 / 255, green: 21 / 255, blue: 24 / 255, alpha: 1)
  }

  private static var linkColor: UIColor {
    return UIColor(red: 61 / 255, green: 90 / 255, blue: 254 / 255, alpha: 1)
  }

  public static func heightForContents(maxWidth: CGFloat) -> CGFloat {
    let titleBoundingSize = CGSize(width: maxWidth - 32, height: .greatestFiniteMagnitude)
    let titleAttributes: [NSAttributedStringKey: Any] = [
      .font: titleFont()
    ]
    let titleHeight = (titleText as NSString)
        .boundingRect(with: titleBoundingSize,
                      options: [.usesLineFragmentOrigin, .usesFontLeading],
                      attributes: titleAttributes,
                      context: nil).height
    print(titleHeight)

    let bodyBoundingSize = CGSize(width: maxWidth - 120, height: .greatestFiniteMagnitude)
    let bodyHeight = bodyText.boundingRect(with: bodyBoundingSize,
                                           options: [.usesLineFragmentOrigin, .usesFontLeading],
                                           context: nil).height
    print(bodyHeight)
    return [12, titleHeight, 12, bodyHeight, 12].reduce(0, +)
  }

  private lazy var titleLabel: UILabel = self.setupTitleLabel()
  private lazy var bodyTextView: UITextView = self.setupBodyTextView()
  private lazy var imageView: UIImageView = self.setupImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(titleLabel)
    contentView.addSubview(bodyTextView)
    contentView.addSubview(imageView)

    contentView.addConstraints(titleLabelConstraints)
    contentView.addConstraints(bodyTextViewConstraints)
    contentView.addConstraints(imageViewConstraints)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  private static func titleFont() -> UIFont {
    let size = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1).pointSize + 2
    return UIFont(name: "Product Sans", size: size)!
  }

  private func titleFont() -> UIFont {
    return AndroidThingsCollectionViewCell.titleFont()
  }

  private static var titleText: String {
    return NSLocalizedString("Take part in the I/O Android Things Scavenger Hunt!",
                             comment: "Headline for the Android Things Scavenger Hunt info cell")
  }

  private static var bodyText: NSAttributedString {
    let url = "g.co/iosearch"
    let text = NSLocalizedString("Get started at \(url)\n(Hint: you may learn that there's an Android Things Developer Kit in your future!)",
      comment: "Body text for the Android Things scavenger hunt info cell")
    let attributedText = NSMutableAttributedString(string: text)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 1.5
    let fullRange = NSMakeRange(0, attributedText.length)
    attributedText.addAttributes([
      .font: bodyFont(),
      .paragraphStyle: paragraphStyle
    ], range: fullRange)

    let linkRange = (attributedText.string as NSString).range(of: url)
    attributedText.addAttributes([
      .link: "https://\(url)",
      .foregroundColor: linkColor,
    ], range: linkRange)

    return attributedText
  }

  private static func bodyFont() -> UIFont {
    let size = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1).pointSize
    return UIFont(name: "Product Sans", size: size)!
  }

  func setupTitleLabel() -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0
    label.font = titleFont()
    label.textColor = AndroidThingsCollectionViewCell.titleColor
    label.text = AndroidThingsCollectionViewCell.titleText
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }

  func setupBodyTextView() -> UITextView {
    let textView = UITextView()
    textView.allowsEditingTextAttributes = false
    textView.inputView = nil
    textView.isScrollEnabled = false
    textView.isEditable = false
    textView.textContainer.lineFragmentPadding = 0
    textView.textContainerInset = .zero
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.font = AndroidThingsCollectionViewCell.bodyFont()
    textView.attributedText = AndroidThingsCollectionViewCell.bodyText
    textView.textColor = bodyTextColor
    return textView
  }

  func setupImageView() -> UIImageView {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "android_things_flowers")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    return imageView
  }

  private var titleLabelConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: titleLabel, attribute: .top,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .top,
                         multiplier: 1, constant: 12),
      NSLayoutConstraint(item: titleLabel, attribute: .leading,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .leading,
                         multiplier: 1, constant: 16),
      NSLayoutConstraint(item: contentView, attribute: .trailing,
                         relatedBy: .equal,
                         toItem: titleLabel, attribute: .trailing,
                         multiplier: 1, constant: -16),
    ]
  }

  private var bodyTextViewConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: bodyTextView, attribute: .top,
                         relatedBy: .equal,
                         toItem: titleLabel, attribute: .bottom,
                         multiplier: 1, constant: 12),
      NSLayoutConstraint(item: bodyTextView, attribute: .left,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .left,
                         multiplier: 1, constant: 16),
      NSLayoutConstraint(item: contentView, attribute: .right,
                         relatedBy: .equal,
                         toItem: bodyTextView, attribute: .right,
                         multiplier: 1, constant: 104),
    ]
  }

  private var imageViewConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: imageView, attribute: .bottom,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .bottom,
                         multiplier: 1, constant: -8),
      NSLayoutConstraint(item: imageView, attribute: .width,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1, constant: 64),
      NSLayoutConstraint(item: imageView, attribute: .height,
                         relatedBy: .equal,
                         toItem: nil, attribute: .notAnAttribute,
                         multiplier: 1, constant: 57),
      NSLayoutConstraint(item: imageView, attribute: .trailing,
                         relatedBy: .equal,
                         toItem: contentView, attribute: .trailing,
                         multiplier: 1, constant: -24),
    ]
  }

  // MARK: - UIAccessibility

  override var isAccessibilityElement: Bool {
    get { return true }
    set {}
  }

  override var accessibilityLabel: String? {
    get {
      return NSLocalizedString("Take part in the Android Things Scavenger Hunt! Double-tap to open in Safari.",
                             comment: "Accessible cell for users. Double-tapping the cell will open the Android Things Scavenger Hunt url in Safari")
    }
    set {}
  }

}
