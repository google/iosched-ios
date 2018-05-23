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

class InfoDetailView: UIView {

  private struct Constants {

    static let detailFont = { () -> UIFont in return UIFont.preferredFont(forTextStyle: .callout) }

    static let paragraphStyle: NSParagraphStyle = { () -> NSParagraphStyle in
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineHeightMultiple = 24 / 15
      return paragraphStyle
    }()

    static let contentTextColor = UIColor(red: 66 / 255, green: 66 / 255, blue: 66 / 255, alpha: 1)
    static let linkColor = UIColor(red: 61 / 255, green: 90 / 255, blue: 254 / 255, alpha: 1)
  }

  /// The attributed string generated through WebKit, plus any additional attributes used by
  /// this class specifically.
  static func attributedText(forDetailText detailText: String) -> NSAttributedString {
    let rawString = InfoDetail.attributedText(detail: detailText)?.mutableCopy()
    guard let attributed = rawString as? NSMutableAttributedString else {
      return NSAttributedString(string: "")
    }

    let range = NSRange(location: 0, length: attributed.length)
    attributed.addAttributes([
      .paragraphStyle: Constants.paragraphStyle
    ], range: range)
    return attributed
  }

  private func attributedDescription(for infoDetail: InfoDetail) -> NSAttributedString {
    return InfoDetailView.attributedText(forDetailText: infoDetail.detail)
  }

  let detailTextView = UITextView()

  var detail: InfoDetail {
    didSet {
      let text = attributedDescription(for: detail)
      detailTextView.attributedText = text
      detailTextView.linkTextAttributes = [
        NSAttributedString.Key.foregroundColor: Constants.linkColor
      ]
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
    let detail = InfoDetail.whatToBring
    self.init(frame: frame, detail: detail)
  }

  private func setupDetailTextView() {
    detailTextView.translatesAutoresizingMaskIntoConstraints = false
    detailTextView.isScrollEnabled = false
    detailTextView.isEditable = false
    detailTextView.font = Constants.detailFont()

    detailTextView.attributedText = attributedDescription(for: detail)
    detailTextView.textColor = Constants.contentTextColor
    detailTextView.textContainer.lineFragmentPadding = 0
    detailTextView.textContainerInset = .zero
  }

  var text: String? {
    return detailTextView.attributedText.string
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
    return textHeight + 16 // bottom padding
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("NSCoding not supported for view of type \(InfoDetailView.self)")
  }

}
