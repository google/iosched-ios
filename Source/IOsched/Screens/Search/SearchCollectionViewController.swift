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

class SearchCollectionViewController: BaseCollectionViewController {

  private lazy var textField: UITextField = self.setupTextField()

  private lazy var viewModel: SearchViewModel =
      SearchViewModel(navigator: rootNavigator,
                      sessions: sessionsDataSource,
                      navigationController: navigationController)

  private let rootNavigator: RootNavigator
  private let serviceLocator: ServiceLocator
  private var sessionsDataSource: LazyReadonlySessionsDataSource {
    return serviceLocator.sessionsDataSource
  }

  public lazy var scheduleNavigator: ScheduleNavigator =
      DefaultScheduleNavigator(serviceLocator: serviceLocator,
                               rootNavigator: rootNavigator,
                               navigationController: navigationController!)

  init(rootNavigator: RootNavigator,
       serviceLocator: ServiceLocator = Application.sharedInstance.serviceLocator) {
    let layout = MDCCollectionViewFlowLayout()
    self.rootNavigator = rootNavigator
    self.serviceLocator = serviceLocator
    super.init(collectionViewLayout: layout)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    collectionView.dataSource = viewModel
    viewModel.collectionView = collectionView
    collectionView.register(SearchCollectionViewCell.self,
                            forCellWithReuseIdentifier: SearchCollectionViewCell.reuseIdentifier())
    collectionView.register(SearchResultsSectionHeaderView.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: SearchResultsSectionHeaderView.reuseIdentifier())

    let textFieldContainer = FlexibleTextViewContainerView()
    textFieldContainer.addTitleView(textField)
    navigationItem.titleView = textFieldContainer
    registerForDynamicTypeUpdates()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    textField.becomeFirstResponder()
  }

  private func setupTextField() -> UITextField {
    let textField = UITextField()
    textField.autocapitalizationType = .none
    textField.autocorrectionType = .no
    textField.placeholder = NSLocalizedString("Search",
                                              comment: "Grayed-out placeholder text in a search bar")
    textField.addTarget(self, action: #selector(textFieldDidChangeText(_:)), for: .editingChanged)
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.setContentHuggingPriority(.defaultLow, for: .vertical)
    textField.setContentHuggingPriority(UILayoutPriority(rawValue: 0), for: .horizontal)
    textField.clearButtonMode = .whileEditing

    return textField
  }

  override var minHeaderHeight: CGFloat {
    return UIApplication.shared.statusBarFrame.height + 56
  }

  // MARK: - Layout

  override func collectionView(_ collectionView: UICollectionView,
                               cellHeightAt indexPath: IndexPath) -> CGFloat {
    return SearchCollectionViewCell.cellHeight()
  }

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    return viewModel.collectionView(collectionView,
                                    layout: collectionViewLayout,
                                    referenceSizeForHeaderInSection: section)
  }

  // MARK: UICollectionViewDelegate

  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
    super.collectionView(collectionView, didSelectItemAt: indexPath)
    viewModel.collectionView(collectionView, didSelectItemAt: indexPath)
  }

  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    super.scrollViewDidScroll(scrollView)
    guard scrollView.isDragging else { return }
    if textField.canResignFirstResponder {
      textField.resignFirstResponder()
    }
  }

  public func showSession(_ session: Session) {
    scheduleNavigator.navigate(to: session, popToRoot: false)
  }

  // MARK: - Text field updates

  @objc func textFieldDidChangeText(_ sender: Any) {
    guard let sender = (sender as? UITextField) else { return }
    if let text = sender.text {
      viewModel.query = text
    }
  }

}

class SearchViewModel: NSObject, UICollectionViewDataSource {

  private let searchResultProviders: [AsyncSearchResultProvider]
  private let rootNavigator: RootNavigator

  private var searchResults: [AsyncSearchResultProvider: [SearchResult]] = [:]

  var query: String = "" {
    didSet {
      rebuildSearchResults()
    }
  }

  public weak var collectionView: UICollectionView?

  public init(navigator: RootNavigator,
              sessions: LazyReadonlySessionsDataSource,
              navigationController: UINavigationController?) {
    rootNavigator = navigator
    searchResultProviders = [
      AsyncSearchResultProvider(SessionSearchResultProvider(
        sessions: sessions,
        navigationController: navigationController)
      ),
      AsyncSearchResultProvider(OtherEventsSearchResultProvider(
        sessions: sessions,
        navigationController: navigationController)
      ),
      AsyncSearchResultProvider(InfoDetailSearchProvider()),
      AsyncSearchResultProvider(AgendaSearchResultsProvider())
    ]
    super.init()
  }

  // MARK: - UICollectionViewDataSource

  private func providerForSection(_ section: Int) -> AsyncSearchResultProvider? {
    let providers = searchResultProviders
    guard section >= 0 && section < providers.count else { return nil }
    return providers[section]
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return searchResultProviders.count
  }

  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    guard let provider = providerForSection(section) else { return 0 }
    return searchResults[provider]?.count ?? 0
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: SearchCollectionViewCell.reuseIdentifier(),
      for: indexPath
    ) as! SearchCollectionViewCell
    if let provider = providerForSection(indexPath.section),
        let result = searchResults[provider]?[indexPath.row] {
      cell.populate(searchResult: result, query: query)
    }
    return cell
  }

  func collectionView(_ collectionView: UICollectionView,
                      didSelectItemAt indexPath: IndexPath) {
    if let provider = providerForSection(indexPath.section),
        let result = searchResults[provider]?[indexPath.row] {
      provider.display(searchResult: result, using: rootNavigator)
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      viewForSupplementaryElementOfKind kind: String,
                      at indexPath: IndexPath) -> UICollectionReusableView {
    let view = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: SearchResultsSectionHeaderView.reuseIdentifier(),
      for: indexPath
    ) as! SearchResultsSectionHeaderView

    view.title = providerForSection(indexPath.section)?.title ?? ""
    return view
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      referenceSizeForHeaderInSection section: Int) -> CGSize {
    guard let provider = providerForSection(section), searchResults[provider]?.count ?? 0 > 0 else {
      return .zero
    }
    let height = SearchResultsSectionHeaderView.headerHeight
    return CGSize(width: collectionView.bounds.size.width, height: height)
  }

  // MARK: - Helpers

  private func rebuildSearchResults() {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return
    }

    for i in 0 ..< searchResultProviders.count {
      let provider = searchResultProviders[i]
      provider.matches(query: trimmed) { (results) in
        let oldResults = self.searchResults[provider] ?? []
        self.updateSection(i, provider: provider, new: results, old: oldResults)
      }
    }
  }

  private func updateSection(_ section: Int,
                             provider: AsyncSearchResultProvider,
                             new results: [SearchResult],
                             old oldResults: [SearchResult]) {
    // This function makes use of the fact that search result providers return
    // results sorted by score, and thus order doesn't change between updates.
    func isElementUnchanged(at index: Int) -> Bool {
      if index >= results.count || index >= oldResults.count { return false }
      return results[index] == oldResults[index]
    }

    collectionView?.performBatchUpdates({
      var oldIndexPaths: [IndexPath] = []
      var unchangedIndexPaths: [IndexPath] = []
      for i in 0 ..< oldResults.count {
        if isElementUnchanged(at: i) {
          continue
        }
        let indexPath = IndexPath(item: i, section: section)
        oldIndexPaths.append(indexPath)
      }
      self.collectionView?.deleteItems(at: oldIndexPaths)

      self.searchResults[provider] = results

      var newIndexPaths: [IndexPath] = []
      for i in 0 ..< results.count {
        if isElementUnchanged(at: i) {
          unchangedIndexPaths.append(IndexPath(item: i, section: section))
          continue
        }
        let indexPath = IndexPath(item: i, section: section)
        newIndexPaths.append(indexPath)
      }
      if !unchangedIndexPaths.isEmpty {
        self.collectionView?.reloadItems(at: unchangedIndexPaths)
      }
      if !newIndexPaths.isEmpty {
        self.collectionView?.insertItems(at: newIndexPaths)
      }
    }, completion: { _ in
      self.collectionView?.reloadSections([section])
    })
  }

}

/// Used to stretch the text view
private class FlexibleTextViewContainerView: UIView {

  private var contentView: UIView?

  func addTitleView(_ view: UIView) {
    contentView = view
    view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(view)

    let constraints = [
      NSLayoutConstraint(item: view,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .top,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: view,
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .left,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: view,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .right,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: view,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: self,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: 0)
    ]

    addConstraints(constraints)
  }

  private func closestNavigationBarParent() -> MDCNavigationBar? {
    var view: UIView = self
    while let superview = view.superview {
      if let navBar = superview as? MDCNavigationBar {
        return navBar
      }
      view = superview
    }
    return nil
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    guard let contentView = contentView else { return .zero }
    let navBarHeight = closestNavigationBarParent()?.bounds.height ?? 0
    let contentSize = contentView.sizeThatFits(CGSize(width: size.width, height: navBarHeight))
    print("Size: \(size), contentSize: \(contentSize)")
    return CGSize(width: max(contentSize.width, size.width), height: navBarHeight)
  }

  override var intrinsicContentSize: CGSize {
    return UIView.layoutFittingExpandedSize
  }

  override var frame: CGRect {
    set {
      // Hack since MDCNavigationBar is doing something weird that prevents the view from
      // taking up space where a right bar button would be.
      if let navBar = closestNavigationBarParent() {
        let rightPadding: CGFloat = 16
        let widthDifference = navBar.frame.width - newValue.origin.x - rightPadding
        var newFrame = newValue
        newFrame.size.width = widthDifference
        super.frame = newFrame
      } else {
        super.frame = frame
      }
    }
    get {
      return super.frame
    }
  }

}

extension SearchCollectionViewController {

  func registerForDynamicTypeUpdates() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(dynamicTypeTextSizeDidChange(_:)),
                                           name: UIContentSizeCategory.didChangeNotification,
                                           object: nil)
  }

  @objc func dynamicTypeTextSizeDidChange(_ sender: Any) {
    collectionView?.collectionViewLayout.invalidateLayout()
    collectionView?.reloadData()
  }

}
