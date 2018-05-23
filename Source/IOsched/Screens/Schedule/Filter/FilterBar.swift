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

class FilterBar: UIView {

  private enum Constants {
    static let filterHeader = NSLocalizedString("Filters:", comment: "Header for a list of filters")
    static let filterHeaderColor = UIColor(red: 66 / 255, green: 66 / 255, blue: 66 / 255, alpha: 1)
    static let filterTextColor = UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
    static let resetButtonTitle =
        NSLocalizedString("Reset", comment: "Title for button that resets filters.")
    static let resetButtonColor = UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
    static let backgroundColor = UIColor(hex: 0xf8f9fa)
    static let filterTextLeftMargin: CGFloat = 24.0
    static let filterTextRightMargin: CGFloat = 20.0
    static let filterTextTopMargin: CGFloat = 14.0
    static let filterTextBottomMargin: CGFloat = 10.0
    static let resetButtonRightMargin: CGFloat = 2.0
  }

  var isFilterVisible = false {
    didSet {
      self.isHidden = !isFilterVisible
    }
  }
  let scheduleViewModel: SessionListViewModel

  var onReset: (() -> Void)?
  var onTapped: (() -> Void)?

  private lazy var resetButton: MDCButton = self.setupButton()
  private lazy var filterLabel: UILabel = self.setupLabel()

  var filterText: String {
    didSet {
      let filter = Constants.filterHeader
      let filterHeading = NSMutableAttributedString(string: filter, attributes: [NSAttributedString.Key.foregroundColor: Constants.filterHeaderColor])
      let filterValue = NSMutableAttributedString(string: filterText, attributes: [NSAttributedString.Key.foregroundColor: Constants.filterTextColor])
      filterHeading.append(NSAttributedString(string: " "))
      filterHeading.append(filterValue)
      filterLabel.attributedText = filterHeading
    }
  }

  init(frame: CGRect, viewModel: SessionListViewModel) {
    filterText = ""
    scheduleViewModel = viewModel
    super.init(frame: frame)
    setupViews()
    registerForDynamicTypeUpdates()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    let height: CGFloat = isFilterVisible ? 56 : 0
    return CGSize(width: size.width, height: height)
  }

  private func setupViews() {
    self.backgroundColor = Constants.backgroundColor
    addSubview(resetButton)
    addSubview(filterLabel)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    resetButton.sizeToFit()
    let resetButtonSize = resetButton.frame.size
    resetButton.frame = CGRect(x: bounds.width -  resetButtonSize.width - Constants.resetButtonRightMargin,
                               y: 0,
                               width: resetButtonSize.width,
                               height: bounds.height)
    filterLabel.frame = CGRect(x: Constants.filterTextLeftMargin,
                               y: Constants.filterTextTopMargin,
                               width: resetButton.frame.minX - Constants.filterTextLeftMargin - Constants.filterTextRightMargin,
                               height: bounds.height - Constants.filterTextTopMargin - Constants.filterTextBottomMargin)
  }

  private func setupButton() -> MDCButton {
    let button = MDCFlatButton()
    button.isUppercaseTitle = false
    button.setTitleColor(Constants.resetButtonColor, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(Constants.resetButtonTitle, for: .normal)
    button.isUppercaseTitle = false
    button.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
    return button
  }

  private func setupLabel() -> UILabel {
    let label = UILabel()
    label.font = UIFont.mdc_preferredFont(forMaterialTextStyle: .caption)
    label.enableAdjustFontForContentSizeCategory()
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
    addGestureRecognizer(tapRecognizer)
    return label
  }

  @objc func resetTapped() {
    scheduleViewModel.filterViewModel.reset()
    filterText = ""
    isFilterVisible = false
    scheduleViewModel.updateView()
  }

  @objc func labelTapped(sender: UITapGestureRecognizer) {
    scheduleViewModel.didSelectFilter()
  }
}

// MARK: - Dynamic type

extension FilterBar {

  func registerForDynamicTypeUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(dynamicTypeTextSizeDidChange(_:)),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
  }

  @objc func dynamicTypeTextSizeDidChange(_ sender: Any) {
    filterLabel.font = UIFont.mdc_preferredFont(forMaterialTextStyle: .caption)
    setNeedsLayout()
  }

}
