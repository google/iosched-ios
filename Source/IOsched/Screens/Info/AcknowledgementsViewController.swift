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

import UIKit

class AcknowledgementsViewController: UIViewController {

  fileprivate let textView = UITextView()

  fileprivate var htmlString: String?

  let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: "Done button"),
                                   style: .done,
                                   target: self,
                                   action: #selector(doneButtonPressed(_:)))

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

    title = NSLocalizedString("Licenses", comment: "Title of Acknowledgements section, where all our open source licenses are displayed")
    doneButton.target = self
    navigationItem.rightBarButtonItem = doneButton
  }

  @objc func doneButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(textView)
    setupTextView()
    setupConstraints()
    textView.isScrollEnabled = false

    navigationController?.navigationBar.titleTextAttributes = [
      NSAttributedString.Key.foregroundColor: InfoViewController.Constants.titleColor,
      NSAttributedString.Key.font: InfoViewController.Constants.titleFont
    ]
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    textView.isScrollEnabled = true
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(didChangePreferredContentSize(_:)),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self)
  }

  private func setupTextView() {
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.isScrollEnabled = true
    textView.isEditable = false

    let bundleURL = Bundle.main.url(forResource: "acknowledgements", withExtension: "html")!
    // swiftlint:disable force_try
    let htmlString = try! String(contentsOf: bundleURL)
    // swiftling:enable force_try
    populate(HTMLString: htmlString)

    textView.textContainer.lineFragmentPadding = 0
    textView.textContainerInset = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
  }

  func populate(HTMLString html: String) {
    textView.attributedText = InfoDetailView.attributedText(forDetailText: html)
    htmlString = html
  }

  private func setupConstraints() {
    var constraints: [NSLayoutConstraint] = []

    // text view top
    constraints.append(NSLayoutConstraint(item: textView,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: topLayoutGuide,
                                          attribute: .bottom,
                                          multiplier: 1,
                                          constant: 0))
    // text view left
    constraints.append(NSLayoutConstraint(item: textView,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: view,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 0))
    // text view right
    constraints.append(NSLayoutConstraint(item: textView,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: view,
                                          attribute: .right,
                                          multiplier: 1,
                                          constant: 0))
    // text view bottom
    constraints.append(NSLayoutConstraint(item: textView,
                                          attribute: .bottom,
                                          relatedBy: .equal,
                                          toItem: view,
                                          attribute: .bottom,
                                          multiplier: 1,
                                          constant: 0))

    view.addConstraints(constraints)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}

// MARK: - Dynamic type

extension AcknowledgementsViewController {

  @objc func didChangePreferredContentSize(_ notification: Notification) {
    if let html = htmlString {
      populate(HTMLString: html)
    }
  }

}
