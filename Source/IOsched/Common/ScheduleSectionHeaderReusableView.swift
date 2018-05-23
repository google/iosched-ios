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

class ScheduleSectionHeaderReusableView: UICollectionReusableView {

  private enum Constants {
    static let titleFont = "Product Sans"
    static let titleHeight: CGFloat = 18.0
  }

  private static let dateFormatter: DateFormatter = {
    let formatter = TimeZoneAwareDateFormatter()
    formatter.dateStyle = .none
    formatter.locale = Locale.autoupdatingCurrent
    formatter.timeZone = TimeZone.userTimeZone()
    formatter.setLocalizedDateFormatFromTemplate("hh:mm")
    return formatter
  }()

  let timeLabel = UILabel()
  let ampmLabel = UILabel()
  public var date: Date? {
    didSet {
      setDate()
    }
  }

  fileprivate var timeLabelFont: UIFont {
    let size = UIFont.preferredFont(forTextStyle: .headline).pointSize
    let font = UIFont(name: Constants.titleFont, size: size)
    if let font = font {
      return font
    } else {
      return UIFont.mdc_preferredFont(forMaterialTextStyle: .subheadline)
    }
  }

  fileprivate var ampmLabelFont: UIFont {
    return UIFont.preferredFont(forTextStyle: .callout)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(timeLabel)
    addSubview(ampmLabel)
    timeLabel.font = timeLabelFont

    timeLabel.textColor = UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
    timeLabel.textAlignment = .center
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    timeLabel.lineBreakMode = .byClipping

    ampmLabel.textColor = UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
    ampmLabel.font = ampmLabelFont
    ampmLabel.textAlignment = .center
    ampmLabel.translatesAutoresizingMaskIntoConstraints = false
    ampmLabel.lineBreakMode = .byClipping
    addConstraints(timeLabelConstraints)
    addConstraints(ampmLabelConstraints)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    date = nil
  }

  var timeLabelConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: timeLabel, attribute: .left,
                         relatedBy: .equal,
                         toItem: self, attribute: .left,
                         multiplier: 1, constant: 4),
      NSLayoutConstraint(item: timeLabel, attribute: .right,
                         relatedBy: .equal,
                         toItem: self, attribute: .right,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: timeLabel, attribute: .top,
                         relatedBy: .equal,
                         toItem: self, attribute: .top,
                         multiplier: 1, constant: 22)
    ]
  }

  var ampmLabelConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: ampmLabel, attribute: .left,
                         relatedBy: .equal,
                         toItem: self, attribute: .left,
                         multiplier: 1, constant: 4),
      NSLayoutConstraint(item: ampmLabel, attribute: .right,
                         relatedBy: .equal,
                         toItem: self, attribute: .right,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: ampmLabel, attribute: .top,
                         relatedBy: .equal,
                         toItem: timeLabel, attribute: .bottom,
                         multiplier: 1, constant: 2)
    ]
  }

  private func setDate() {
    guard let date = date else {
      removeText()
      return
    }
    let dateFormatter = ScheduleSectionHeaderReusableView.dateFormatter
    var text = dateFormatter.string(from: date)

    // the ranges must not both be nil or empty.
    let amRange = text.range(of: dateFormatter.amSymbol)
    let pmRange = text.range(of: dateFormatter.pmSymbol)
    if amRange == nil && pmRange == nil { return }
    if amRange?.isEmpty ?? true && pmRange?.isEmpty ?? true {
      timeLabel.text = text
      return
    }

    let currentSymbol = { () -> String in
      if amRange == nil {
        return dateFormatter.pmSymbol
      } else {
        return dateFormatter.amSymbol
      }
    }()

    let currentSymbolRange = { () -> Range<String.Index> in
      if let amRange = amRange {
        return amRange
      } else {
        return pmRange!
      }
    }()

    text.removeSubrange(currentSymbolRange)

    timeLabel.text = text
    ampmLabel.text = currentSymbol

    registerForDynamicTypeUpdates()
  }

  private func removeText() {
    timeLabel.text = ""
    ampmLabel.text = ""
    NotificationCenter.default.removeObserver(self)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - UIAccessibility

  override var isAccessibilityElement: Bool {
    get { return true }
    set {}
  }

  override var accessibilityLabel: String? {
    get {
      guard let date = date else { return nil }
      return ScheduleSectionHeaderReusableView.dateFormatter.string(from: date)
    } set {}
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

}

// MARK: - Dynamic type

extension ScheduleSectionHeaderReusableView {

  func registerForDynamicTypeUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(dynamicTypeTextSizeDidChange(_:)),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
  }

  @objc func dynamicTypeTextSizeDidChange(_ sender: Any) {
    timeLabel.font = timeLabelFont
    ampmLabel.font = ampmLabelFont
    setNeedsLayout()
  }

}
