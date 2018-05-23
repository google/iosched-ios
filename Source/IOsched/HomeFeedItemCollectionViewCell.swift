//
//  Copyright (c) 2019 Google Inc.
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

class HomeFeedItemCollectionViewCell: MDCCollectionViewCell {

  private enum Fonts {
    static func titleFont() -> UIFont {
      return ProductSans.regular.style(.body)
    }

    static func messageFont() -> UIFont {
      return UIFont.preferredFont(forTextStyle: .callout)
    }
  }

  private let titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.font = Fonts.titleFont()
    label.setContentHuggingPriority(.required, for: .vertical)
    return label
  }()

  private let messageTextView: UITextView = {
    let textView = UITextView()
    textView.isScrollEnabled = false
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    textView.font = Fonts.messageFont()
    textView.isEditable = false
    textView.dataDetectorTypes = .link
    textView.setContentHuggingPriority(.defaultLow, for: .vertical)
    return textView
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(titleLabel)
    contentView.addSubview(messageTextView)

    setupConstraints()

    contentView.layer.cornerRadius = 8
    contentView.layer.borderColor = UIColor(hex: 0xdadce0).cgColor
    contentView.layer.borderWidth = 1
  }

  func populate(feedItem: HomeFeedItem) {
    titleLabel.text = feedItem.title
    messageTextView.text = feedItem.message

    registerForDynamicTypeUpdates()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    NotificationCenter.default.removeObserver(self)
  }

  static func sizeForContents(_ feedItem: HomeFeedItem, maxWidth: CGFloat) -> CGSize {
    return sizeForContents(title: feedItem.title,
                           message: feedItem.message,
                           maxWidth: maxWidth)
  }

  private static func sizeForContents(title: String?,
                                      message: String?,
                                      maxWidth: CGFloat) -> CGSize {
    let boundingSize = CGSize(width: maxWidth - 32, height: .greatestFiniteMagnitude)
    let options: NSStringDrawingOptions =
        [.usesFontLeading, .usesDeviceMetrics, .usesLineFragmentOrigin]
    let titleAttributes = [NSAttributedString.Key.font: Fonts.titleFont()]
    let messageAttributes = [NSAttributedString.Key.font: Fonts.messageFont()]
    let titleSize = title?.boundingRect(with: boundingSize,
                                        options: options,
                                        attributes: titleAttributes,
                                        context: nil) ?? .zero

    let messageSize = message?.boundingRect(with: boundingSize,
                                            options: options,
                                            attributes: messageAttributes,
                                            context: nil) ?? .zero

    let height = titleSize.height + messageSize.height + 52
    let paddedWidth = maxWidth + 32
    return CGSize(width: paddedWidth, height: height)
  }

  override var intrinsicContentSize: CGSize {
    let title = titleLabel.text
    let message = messageTextView.text
    let maxWidth = bounds.size.width - 32
    return HomeFeedItemCollectionViewCell.sizeForContents(title: title,
                                                          message: message,
                                                          maxWidth: maxWidth)
  }

  override var frame: CGRect {
    get {
      return super.frame
    }
    set {
      if newValue.size.width != super.frame.size.width {
        invalidateIntrinsicContentSize()
      }
      super.frame = newValue
    }
  }

  // MARK: - Constraints

  private func setupConstraints() {
    let constraints = [
      NSLayoutConstraint(item: titleLabel,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .top,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .leading,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .leading,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .trailing,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: messageTextView,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: titleLabel,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: messageTextView,
                         attribute: .leading,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .leading,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: messageTextView,
                         attribute: .trailing,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .trailing,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: messageTextView,
                         attribute: .bottom,
                         relatedBy: .lessThanOrEqual,
                         toItem: contentView,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: -16)
    ]

    contentView.addConstraints(constraints)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func registerForDynamicTypeUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(dynamicTypeTextSizeDidChange(_:)),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
  }

  @objc func dynamicTypeTextSizeDidChange(_ sender: Any) {
    titleLabel.font = Fonts.titleFont()
    messageTextView.font = Fonts.messageFont()
    setNeedsLayout()
  }

}
