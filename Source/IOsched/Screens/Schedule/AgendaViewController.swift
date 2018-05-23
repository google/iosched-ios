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

class AgendaViewController: BaseCollectionViewController {

  private let dataSource = AgendaDataSource()
  private let layout: MDCCollectionViewFlowLayout

  public init() {
    layout = MDCCollectionViewFlowLayout()
    layout.minimumLineSpacing = 12
    super.init(collectionViewLayout: layout)

    let title = NSLocalizedString(
      "Agenda",
      comment: "Title of the agenda view, which displays an overview of the conference schedule"
    )
    tabBarItem = UITabBarItem(title: title, image: UIImage(named: "ic_schedule"), tag: 0)
    self.title = title
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.backgroundColor = .white
    collectionView.dataSource = dataSource
    collectionView.register(AgendaCollectionViewCell.self,
                            forCellWithReuseIdentifier: AgendaCollectionViewCell.reuseIdentifier())
    collectionView.register(AgendaSectionHeaderReusableView.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: AgendaSectionHeaderReusableView.reuseIdentifier())

    registerForDynamicTypeUpdates()
    registerForTimeZoneChanges()
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellHeightAt indexPath: IndexPath) -> CGFloat {
    let agendaItem = dataSource.item(at: indexPath)
    let height = AgendaCollectionViewCell.fullHeightForContents(
      agendaItem: agendaItem,
      maxWidth: collectionView.frame.size.width
    )
    return height
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(width: view.frame.size.width,
                  height: AgendaSectionHeaderReusableView.heightForContents)
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
  }

  override var minHeaderHeight: CGFloat {
    return 56 + UIApplication.shared.statusBarFrame.height
  }

  func showAgendaItem(_ agendaItem: AgendaItem, animated: Bool = true) {
    guard let indexPath = dataSource.indexPathForItem(agendaItem) else { return }
    collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
  }

}

extension AgendaViewController {

  func registerForDynamicTypeUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(dynamicTypeTextSizeDidChange(_:)),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
  }

  @objc private func dynamicTypeTextSizeDidChange(_ sender: Any) {
    collectionView?.collectionViewLayout.invalidateLayout()
    collectionView?.reloadData()
  }

  func registerForTimeZoneChanges() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(timeZoneDidChange(_:)),
                                           name: .timezoneUpdate,
                                           object: nil)
  }

  @objc private func timeZoneDidChange(_ notification: Any) {
    collectionView.reloadData()
  }

}
