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

import Firebase
import MaterialComponents
import AlamofireImage
import GoogleSignIn

class MyIOViewController: ScheduleViewController {

  private enum MyIOLayoutConstants {
    static let placeholderImageName = "ic_account_circle"
    static let userImageDimension = 72
    static let avatarImageWidth = 24
    static let avatarImageSize = CGSize(width: MyIOLayoutConstants.avatarImageWidth,
                                        height: MyIOLayoutConstants.avatarImageWidth)
  }

  fileprivate lazy var accountButton: UIBarButtonItem = self.setupAccountButton(tint: true)

  override func performViewUpdate(indexPath: IndexPath?) {
    self.refreshUI()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    registerForAccountUpdates()
  }

  override func registerForAccountUpdates() {
    // update avatar first ...
    self.updateAvatarImage()

    // ... then register for subsequent updates
    SignIn.sharedInstance
      .onSignIn {
        self.updateAvatarImage()
      }
      .onSignOut {
        self.updateAvatarImage()
      }
  }

  override func updateAvatarImage() {
    if let user = GIDSignIn.sharedInstance().currentUser {
      if let url = user.profile.imageURL(withDimension: UInt(MyIOLayoutConstants.userImageDimension)) {
        self.downloadAvatarImage(url)
      }
    }
    else {
      if let placeholderImage = self.myIOPlaceholderImage {
        self.myIOAccountImage = placeholderImage
      }
      self.updateAccountButton(tint: true)
    }
  }

  let myIOPlaceholderImage = UIImage(named: MyIOLayoutConstants.placeholderImageName)?.withRenderingMode(.alwaysTemplate)
  lazy var myIOAccountImage: UIImage? = self.placeholderImage

  lazy var myIOImageDownloader: ImageDownloader = ImageDownloader()
  lazy var myIOAvatarFilter = AspectScaledToFillSizeCircleFilter(size: MyIOLayoutConstants.avatarImageSize)

  override func downloadAvatarImage(_ url: URL) {
    let urlRequest = URLRequest(url: url)

    myIOImageDownloader.download(urlRequest, filter: myIOAvatarFilter) { response in
      if let image = response.result.value {
        self.myIOAccountImage = image
        self.updateAccountButton(tint: false)
      }
    }
  }

// MARK: - View setup

  private enum Constants {
    static let title = NSLocalizedString("My Events", comment: "Title for My Events screen")
  }

  override func setupViews() {
    super.setupViews()

    self.title = Constants.title
  }

  @objc override func setupCollectionView() {
    super.setupCollectionView()
  }

  @objc override func setupNavigationBarActions() {
    self.navigationItem.rightBarButtonItem = accountButton
  }

  override func updateAccountButton(tint: Bool) {
    self.accountButton = setupAccountButton(tint: tint)
    setupNavigationBarActions()
  }

  override func setupAccountButton(tint: Bool) -> UIBarButtonItem {
    let image = self.myIOAccountImage
    let button = UIBarButtonItem.init(image: image,
                                      style: .plain,
                                      target: self,
                                      action: #selector(accountAction))
    if tint {
      button.tintColor = headerForegroundColor
    }
    button.accessibilityLabel = NSLocalizedString("User account information",
                                                  comment: "Accessibility label for user account button")
    return button
  }

// MARK: - Analytics

  override var screenName: String? {
    return AnalyticsParameters.myEvents
  }

}

// MARK: - Actions
extension MyIOViewController {
  @objc override func accountAction() {
    if let viewModel = currentViewModel as? MyIOComposedViewModel {
      viewModel.myIOAccountSelected()
    }
  }
}
