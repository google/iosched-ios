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

public class SearchCollectionViewCell: MDCCollectionViewCell {

  private let titleLabel = UILabel()
  private let detailLabel = UILabel()

  private lazy var linguisticTagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)

  override init(frame: CGRect) {
    super.init(frame: frame)

    setupTitleLabel()
    contentView.addSubview(titleLabel)
    setupDetailLabel()
    contentView.addSubview(detailLabel)
    setupConstraints()
  }

  public func populate(searchResult: SearchResult, query: String) {
    titleLabel.text = searchResult.title
    detailLabel.text = searchResult.subtext

    setAttributedTitleText(searchResult.title, query: query)
    setAttributedSubtext(searchResult.subtext, query: query)

    registerForDynamicTypeUpdates()
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.text = ""
    detailLabel.text = ""
    NotificationCenter.default.removeObserver(self)
  }

  private func setupTitleLabel() {
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.setContentHuggingPriority(.required, for: .vertical)
    titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
    titleLabel.enableAdjustFontForContentSizeCategory()
  }

  private func setupDetailLabel() {
    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
    detailLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    detailLabel.numberOfLines = 4
    detailLabel.font = UIFont.preferredFont(forTextStyle: .callout)
    detailLabel.enableAdjustFontForContentSizeCategory()
  }

  private func setAttributedTitleText(_ title: String, query: String) {
    setAttributedText(title, query: query, for: titleLabel)
  }

  private func setAttributedSubtext(_ subtext: String, query: String) {
    setAttributedText(subtext, query: query, for: detailLabel)
  }

  private func setAttributedText(_ text: String, query: String, for label: UILabel) {
    let matchableTokens = firstSeveralTokensFromQuery(query)
    var cumulativeMatchRanges: [NSRange] = []
    guard !matchableTokens.isEmpty else { return }

    for token in matchableTokens {
      let matchRanges = text.ranges(of: token).map { return NSRange($0, in: text) }
      cumulativeMatchRanges += matchRanges
    }

    let highlightColor = UIColor(red: 252 / 255, green: 210 / 255, blue: 48 / 255, alpha: 0.3)
    let attributedText = NSMutableAttributedString(string: text)
    let highlightAttributes = [
      NSAttributedString.Key.backgroundColor: highlightColor
    ]

    for range in cumulativeMatchRanges {
      attributedText.addAttributes(highlightAttributes, range: range)
    }

    label.text = nil
    label.attributedText = attributedText
  }

  private func firstSeveralTokensFromQuery(_ query: String) -> [String] {
    let nsQuery = query as NSString
    let range = NSRange(location: 0, length: nsQuery.length)
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
    var tokens: [String] = []

    // 4 is a lot of characters for English words but may not be many
    // for languages with shorter words. This function runs every time
    // the text in the saerch bar changes, so a lower cap is better for
    // performance.
    let maxNumberOfTokens = 4

    func tagHandler(tag: NSLinguisticTag?, range: NSRange, stopPointer: UnsafeMutablePointer<ObjCBool>) {
      guard tag != nil else { return }
      let taggedString = nsQuery.substring(with: range)
      tokens.append(taggedString)
      if tokens.count >= maxNumberOfTokens {
        stopPointer.pointee = true
      }
    }

    linguisticTagger.string = query

    if #available(iOS 11, *) {
      linguisticTagger.enumerateTags(in: range,
                                     unit: .word,
                                     scheme: .tokenType,
                                     options: options) { (tag, range, stopPointer) in
        tagHandler(tag: tag, range: range, stopPointer: stopPointer)
      }
    } else {
      linguisticTagger.enumerateTags(in: range,
                                     scheme: .tokenType,
                                     options: options) { (tag, tokenRange, _, stopPointer) in
        tagHandler(tag: tag, range: tokenRange, stopPointer: stopPointer)
      }
    }

    return tokens
  }

  static func cellHeight() -> CGFloat {
    return UIFont.preferredFont(forTextStyle: .callout).lineHeight * 4 +
      UIFont.preferredFont(forTextStyle: .body).lineHeight + 48
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    let maxWidth = contentView.frame.size.width - 32
    titleLabel.preferredMaxLayoutWidth = maxWidth
    detailLabel.preferredMaxLayoutWidth = maxWidth
    super.layoutSubviews()
  }

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
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .left,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: titleLabel,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .right,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: detailLabel,
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .left,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: detailLabel,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .right,
                         multiplier: 1,
                         constant: -16),
      NSLayoutConstraint(item: detailLabel,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: titleLabel,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: 16),
      NSLayoutConstraint(item: detailLabel,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: -16)
    ]
    constraints.last?.priority = .defaultLow

    contentView.addConstraints(constraints)
  }

  // MARK: - Accessibility

  public override var isAccessibilityElement: Bool {
    set {}
    get { return true }
  }

  public override var accessibilityLabel: String? {
    set {}
    get {
      if let title = titleLabel.text, let detail = detailLabel.text {
        return title + "\n" + detail
      }
      if let title = titleLabel.text {
        return title
      }
      if let detail = detailLabel.text {
        return detail
      }
      return nil
    }
  }

  @available (*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}

// Taken from https://stackoverflow.com/questions/36865443/get-all-ranges-of-a-substring-in-a-string-in-swift
extension String {
  func ranges(of substring: String, options: CompareOptions = .caseInsensitive, locale: Locale? = nil) -> [Range<Index>] {
    var ranges: [Range<Index>] = []
    while ranges.last.map({ $0.upperBound < self.endIndex }) ?? true,
      let range = self.range(of: substring, options: options, range: (ranges.last?.upperBound ?? self.startIndex)..<self.endIndex, locale: locale) {
      ranges.append(range)
    }
    return ranges
  }
}

extension SearchCollectionViewCell {

  func registerForDynamicTypeUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(dynamicTypeTextSizeDidChange(_:)),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
  }

  @objc func dynamicTypeTextSizeDidChange(_ sender: Any) {
    titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
    detailLabel.font = UIFont.preferredFont(forTextStyle: .callout)
  }

}
