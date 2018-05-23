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
import DTCoreText

class InfoDetailView: UIView {

  private struct Constants {

    static let detailFont = { () -> UIFont in return UIFont.preferredFont(forTextStyle: .body) }

    static let paragraphStyle: NSParagraphStyle = { () -> NSParagraphStyle in
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineHeightMultiple = 24 / 15 // 24pt line
      return paragraphStyle
    }()

    static let contentTextColor = UIColor(red: 66 / 255, green: 66 / 255, blue: 66 / 255, alpha: 1)
    static let linkColor = UIColor(red: 61 / 255, green: 90 / 255, blue: 254 / 255, alpha: 1)
  }

  /// The attributed string generated through DTCoreText.
  static func attributedText(forDetailText detailText: String) -> NSAttributedString {
    let data = detailText.data(using: .utf8)
    let attributedText = NSAttributedString(htmlData: data,
                                            options: Content.options(),
                                            documentAttributes: nil)!

    return attributedText
  }

  struct Content {
    static let css = "a {" +
      "font-weight: bold; " +
      "text-decoration: none;" +
    "}"

    static func options() -> [String: Any] {
      // This is a func and not a let so it'll correctly propogate changes
      // if the detail font changes.
      return [
        DTDefaultFontName: Constants.detailFont().fontName,
        DTDefaultFontFamily: Constants.detailFont().familyName,
        DTDefaultFontSize: Constants.detailFont().pointSize,
        DTUseiOS6Attributes: true,
        DTDefaultTextColor: Constants.contentTextColor,
        DTDefaultLinkColor: Constants.linkColor,
        DTDefaultLinkHighlightColor: Constants.linkColor,
        DTDefaultLineHeightMultiplier: Constants.paragraphStyle.lineHeightMultiple,
        DTDefaultStyleSheet: DTCSSStylesheet(styleBlock: Content.css)
      ]
    }
  }

  let detailTextView = UITextView()

  var detail: InfoDetail {
    didSet {
      let text = InfoDetailView.attributedText(forDetailText: detail.detail)
      detailTextView.attributedText = text
      detailTextView.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: Constants.linkColor]
      setNeedsLayout()
    }
  }

  required init(frame: CGRect, detail: InfoDetail) {
    self.detail = detail
    super.init(frame: frame)

    addSubview(detailTextView)
    setupDetailTextView()
    setupConstraints()
  }

  override convenience init(frame: CGRect) {
    let detail = InfoDetail.shuttleService
    self.init(frame: frame, detail: detail)
  }

  private func setupDetailTextView() {
    detailTextView.translatesAutoresizingMaskIntoConstraints = false
    detailTextView.isScrollEnabled = false
    detailTextView.isEditable = false

    detailTextView.attributedText = InfoDetailView.attributedText(forDetailText: detail.detail)
    detailTextView.textColor = Constants.contentTextColor
    detailTextView.textContainer.lineFragmentPadding = 0
    detailTextView.textContainerInset = .zero
  }

  private func setupConstraints() {
    var constraints: [NSLayoutConstraint] = []

    // detail text view top
    constraints.append(NSLayoutConstraint(item: detailTextView,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .top,
                                          multiplier: 1,
                                          constant: 0))
    // detail text view left
    constraints.append(NSLayoutConstraint(item: detailTextView,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 0))
    // detail text view right
    constraints.append(NSLayoutConstraint(item: detailTextView,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: 0))
    // detail text view bottom
    constraints.append(NSLayoutConstraint(item: detailTextView,
                                          attribute: .bottom,
                                          relatedBy: .equal,
                                          toItem: self,
                                          attribute: .bottom,
                                          multiplier: 1,
                                          constant: 0))
    addConstraints(constraints)
  }

  class func height(forDetailText detailText: String, maxWidth: CGFloat) -> CGFloat {
    let attributed = attributedText(forDetailText: detailText)
    let textHeight = attributed.boundingRect(with: CGSize(width: maxWidth,
                                                          height: CGFloat.greatestFiniteMagnitude),
                                             options: [.usesLineFragmentOrigin],
                                             context: nil).size.height
    return textHeight
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    // Since the string is attributed text generated from HTML, we need to regenerate the
    // whole string.
    let attributedText = InfoDetailView.attributedText(forDetailText: detail.detail)
    detailTextView.attributedText = attributedText
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("NSCoding not supported for view of type \(InfoDetailView.self)")
  }

}
