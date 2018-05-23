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
import AlamofireImage

/// This class implements a right drawer menu on top of a regular
/// tab bar controller, because UITabBarController's overflow menu
/// isn't customizable.
public class BottomSheetContainerViewController: UIViewController,
    BottomSheetViewControllerDelegate, UITabBarControllerDelegate {

  private(set) var expanded = false
  let bottomSheetController: BottomSheetViewController

  let rootTabBarController: UITabBarController

  /// The nav controller displays controllers in the overflow menu
  /// by pushing them onto the navigation controller of the currently
  /// selected tab bar items, so all tab bar items must be instances
  /// of UINavigationController.
  public init(rootTabBarController: UITabBarController,
              viewControllers: [UIViewController]) {
    let rightDrawerItems = Array(viewControllers.suffix(from: 4))
    self.rootTabBarController = rootTabBarController
    self.bottomSheetController = BottomSheetViewController(drawerItems: rightDrawerItems)
    super.init(nibName: nil, bundle: nil)
    let tabBarControllers = Array(viewControllers.prefix(4)) + [placeholderViewController]
    rootTabBarController.viewControllers = tabBarControllers
    rootTabBarController.delegate = self
    self.bottomSheetController.delegate = self
  }

  public override var shouldAutomaticallyForwardAppearanceMethods: Bool {
    return false
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    addChild(rootTabBarController)
    rootTabBarController.view.frame = view.bounds
    view.insertSubview(rootTabBarController.view, at: 0)
    rootTabBarController.didMove(toParent: self)

    addChild(bottomSheetController)
    bottomSheetController.view.frame = view.bounds.offsetBy(dx: 0, dy: view.frame.size.height)
    view.addSubview(bottomSheetController.view)
    bottomSheetController.didMove(toParent: self)
    bottomSheetController.view.isHidden = true
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    rootTabBarController.beginAppearanceTransition(true, animated: animated)
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    rootTabBarController.endAppearanceTransition()
  }

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    rootTabBarController.beginAppearanceTransition(false, animated: animated)
  }

  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    rootTabBarController.endAppearanceTransition()
  }

  private let offset: CGFloat = 60

  public func toggleBottomSheet(duration: TimeInterval = 0.25, animated: Bool = true) {
    let endingOriginY: CGFloat
    bottomSheetController.loadViewIfNeeded()
    let contentHeight = bottomSheetController.collectionView.contentSize.height
    if expanded {
      endingOriginY = view.frame.size.height
    } else {
      endingOriginY = view.frame.size.height - contentHeight - bottomLayoutGuide.length
    }

    expanded = !expanded
    bottomSheetController.beginAppearanceTransition(expanded, animated: animated)

    let preAnimation = {
      if self.expanded {
        self.bottomSheetController.view.isHidden = false
        self.rootTabBarController.view.addSubview(self.overlayView)
        self.overlayView.alpha = 0
      }
    }
    let viewUpdates = {
      self.bottomSheetController.view.frame.origin.y = endingOriginY
      self.overlayView.alpha = self.expanded ? 1 : 0
    }
    let completion = {
      self.bottomSheetController.endAppearanceTransition()
      self.bottomSheetController.view.isHidden = !self.expanded
      if !self.expanded {
        self.overlayView.removeFromSuperview()
      }
    }

    preAnimation()
    if animated {
      UIView.animate(withDuration: duration,
                     delay: 0,
                     options: .curveEaseOut,
                     animations: viewUpdates) { _ in
        completion()
      }
    } else {
      viewUpdates()
      completion()
    }
  }

  public func bottomSheetController(_ controller: BottomSheetViewController,
                                    didSelect selectedViewController: UIViewController) {
    if let currentNavigationController = rootTabBarController.selectedViewController as?
        UINavigationController {
      if currentNavigationController.viewControllers.contains(selectedViewController) {
        currentNavigationController.popToViewController(selectedViewController, animated: true)
      } else {
        currentNavigationController.pushViewController(selectedViewController, animated: true)
      }
      toggleBottomSheet()
    }
  }

  private lazy var overlayView: UIView = {
    let overlay = UIControl()
    overlay.frame = view.bounds
    let backgroundColor = UIColor(r: 0, g: 0, b: 0, a: 0.3)
    overlay.backgroundColor = backgroundColor
    overlay.addTarget(self, action: #selector(overlayViewWasTapped(_:)), for: .touchUpInside)
    return overlay
  }()

  @objc func overlayViewWasTapped(_ sender: Any) {
    toggleBottomSheet()
  }

  // MARK: - UITabBarControllerDelegate

  public func tabBarController(_ tabBarController: UITabBarController,
                               shouldSelect viewController: UIViewController) -> Bool {
    guard viewController == placeholderViewController else { return true }
    toggleBottomSheet()
    return false
  }

  private lazy var placeholderViewController: UIViewController = {
    let controller = UIViewController()
    let image = UIImage(named: "ic_more")
    let moreTitle = NSLocalizedString("More", comment: "Button title for overflow navigation sheet")
    let tabItem = UITabBarItem(title: moreTitle, image: image, tag: 0)
    controller.tabBarItem = tabItem
    return controller
  }()

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}

public extension UIViewController {

  var sideNavigationController: BottomSheetContainerViewController? {
    var controller = self
    while let parent = controller.parent {
      if let sideNav = parent as? BottomSheetContainerViewController {
        return sideNav
      }
      controller = parent
    }
    return nil
  }

}
