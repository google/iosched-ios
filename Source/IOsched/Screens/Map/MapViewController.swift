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
import MapKit

import Firebase
import GoogleMaps
import MaterialComponents

class MapViewController: UIViewController {

  enum MapVariant: String {
    case day
    case night
    case concert
  }

  let appBar = MDCAppBar()

  private(set) var variant: MapVariant = .day {
    didSet {
      refreshUI()
    }
  }

  fileprivate enum Constants {
    /// Location of the venue. The large venue marker is displayed at this location.
    static let venueCoordinates = CLLocationCoordinate2D(latitude: 37.425842,
                                                         longitude: -122.079933)

    static let venueCameraZoomDefault: Float = 16.4
    static let venueCameraZoom: Float = 15

    static let defaultBearing: Double = 0

    static let labelMarkerExtraPaddingWidth: CGFloat = 27
    static let labelMarkerExtraPaddingHeight: CGFloat = 0
    static let markerWidth: CGFloat = 27
    static let markerHeight: CGFloat = 60
    static let markerFont = UIFont.mdc_preferredFont(forMaterialTextStyle: .caption)

    /// Original position of the camera that shows the venue.
    static let cameraPosition = GMSCameraPosition(target: Constants.venueCoordinates,
                                                  zoom: Constants.venueCameraZoomDefault,
                                                  bearing: Constants.defaultBearing,
                                                  viewingAngle: 0.0)

    static let APIKey = Configuration.sharedInstance.googleMapsApiKey
    static let headerBackgroundColor = UIColor.white
    static let titleColor = UIColor(hex: "#747474")
    static let titleHeight: CGFloat = 24.0
    static let titleFont = "Product Sans"
    static let title = NSLocalizedString("Map", comment: "Title for map page")
  }

  // MARK: - Properties
  private static var initializedAPIKey = false
  fileprivate lazy var mapView: GMSMapView = self.setupMapView()
  private lazy var tileLayer: GMSTileLayer = self.setupCustomMapTileLayer(for: variant)
  private lazy var card: MapCardView = MapCardView()

  fileprivate let viewModel: MapViewModel
  private let locationManager: CLLocationManager
  fileprivate var googleMarkers = [GMSMarker]()
  fileprivate var activeMarkers = [GMSMarker]()
  fileprivate var isCardVisible = false {
    didSet {
      card.isHidden = !isCardVisible
    }
  }

  init(viewModel: MapViewModel) {
    self.viewModel = viewModel
    locationManager = CLLocationManager()

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    viewModel.update(for: variant)
    self.refreshUI()
  }

  private let variantButton: MDCFloatingButton = {
    let button = MDCFloatingButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(variantButtonTapped(_:)), for: .touchUpInside)
    button.backgroundColor = UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
    let filterImage = UIImage(named: "ic_map_layers")?.withRenderingMode(.alwaysTemplate)
    button.setImage(filterImage, for: .normal)
    button.tintColor = UIColor.white
    button.accessibilityLabel =
      NSLocalizedString("Change map layers",
                        comment: "Accessibility label for users to change layers in the map view.")
    button.setElevation(ShadowElevation.init(rawValue: 2), for: .normal)
    return button
  }()

  @objc private func variantButtonTapped(_ sender: Any) {
    let initiallyHidden = variantSelectorView.isHidden
    if initiallyHidden {
      variantSelectorView.alpha = 0
      variantSelectorView.isHidden = false

      UIView.animate(withDuration: 0.15) {
        self.variantSelectorView.alpha = 1
      }
    } else {
      UIView.animate(withDuration: 0.15, animations: {
        self.variantSelectorView.alpha = 0
      }, completion: { _ in
        self.variantSelectorView.isHidden = true
        self.variantSelectorView.alpha = 1
      })
    }
  }

  private lazy var variantSelectorView: MapVariantSelectorView = {
    let view = MapVariantSelectorView()
    view.buttonPressedCallback = { [weak self] variant in
      guard let self = self else { return }
      self.variant = variant
      self.variantButtonTapped(self.variantButton)
    }
    return view
  }()

  func refreshUI() {
    // Remove any existing markers.
    for marker in googleMarkers {
      marker.map = nil
      marker.userData = nil
    }
    googleMarkers.removeAll()
    viewModel.update(for: variant)

    // Create new markers from updated view model.
    let newMarkers: [GMSMarker] = viewModel.mapItems.map { mapItem in
      let position =
          CLLocationCoordinate2D(latitude: mapItem.latitude, longitude: mapItem.longitude)
      let googleMarker = GMSMarker(position: position)
      googleMarker.title = mapItem.title
      googleMarker.appearAnimation = GMSMarkerAnimation.pop

      var width = CGFloat(Constants.markerWidth)
      var height = CGFloat(Constants.markerHeight)
      if let title = googleMarker.title {
        width = title.boundingRect(with: CGSize(width: 1000, height: Constants.markerHeight),
                                   options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                   attributes: [NSAttributedString.Key.font: Constants.markerFont],
                                   context: nil).size.width
        width += Constants.labelMarkerExtraPaddingWidth
        height += Constants.labelMarkerExtraPaddingHeight
      }

      let iconView = MapMarkerIconView(frame: CGRect(x: 0, y: 0, width: width, height: height),
                                       mapItem: mapItem)
      iconView.title = googleMarker.title
      googleMarker.iconView = iconView
      googleMarker.tracksViewChanges = false
      googleMarker.map = mapView
      googleMarker.userData = mapItem
      googleMarker.zIndex = 1
      return googleMarker
    }
    googleMarkers.append(contentsOf: newMarkers)
    updateMarkerVisibility()
  }

  func select(roomId: String?) {
    guard let roomId = roomId else { return }

    let matchingMarker = googleMarkers.first { marker in
      if let mapItem = mapItem(marker: marker), mapItem.id == roomId {
        return true
      }
      return false
    }
    guard let marker = matchingMarker else { return }
    selectActiveMarker(marker: marker)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Application.sharedInstance.analytics.logEvent(AnalyticsEventSelectContent, parameters: [
      AnalyticsParameterContentType: AnalyticsParameters.screen,
      AnalyticsParameterItemID: AnalyticsParameters.map
    ])

    // Don't request until after the screen is displayed to the user to give more context.
    locationManager.requestWhenInUseAuthorization()
    mapView.isMyLocationEnabled = true
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func viewWillDisappear(_ animated: Bool) {
    mapView.isMyLocationEnabled = false
    super.viewWillDisappear(animated)
  }

  private func setupMapView() -> GMSMapView {
    // API key should not be initialized more than once.
    if !MapViewController.initializedAPIKey {
      let apiKey = Constants.APIKey
      if !GMSServices.provideAPIKey(apiKey) {
        NSLog("Google maps API key invalid.")
      }
      MapViewController.initializedAPIKey = true
    }

    let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: Constants.cameraPosition)
    do {
      if let styleURL = Bundle.main.url(forResource: "maps_style", withExtension: "json") {
        mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
      } else {
        NSLog("Unable to find style.json")
      }
    } catch {
      NSLog("One or more of the map styles failed to load. \(error)")
    }
    // Turn on accessibility, it is turned off by default.
    mapView.accessibilityElementsHidden = false
    mapView.settings.myLocationButton = false
    mapView.settings.compassButton = true
    mapView.preferredFrameRate = preferredFrameRate
    mapView.setMinZoom(16, maxZoom: 19.75)

    let bounds = GMSCoordinateBounds(
      coordinate: CLLocationCoordinate2D(
        latitude: 37.428343,
        longitude: -122.074584
      ), coordinate: CLLocationCoordinate2D(
        latitude: 37.423205,
        longitude: -122.081757
      )
    )
    mapView.cameraTargetBounds = bounds

    tileLayer.map = mapView
    return mapView
  }

  private var preferredFrameRate: GMSFrameRate {
    if ProcessInfo.processInfo.isLowPowerModeEnabled {
      return .powerSave
    } else {
      return .conservative
    }
  }

  private func setupCustomMapTileLayer(for mapVariant: MapVariant) -> GMSURLTileLayer {
    func urlString(variant: String,
                   tileSize: Int,
                   zoomLevel: UInt,
                   tileX: UInt,
                   tileY: UInt) -> String {
      return "https://storage.googleapis.com/io2019-festivus/images/maptiles/\(variant)/\(tileSize)/\(zoomLevel)/\(tileX)_\(tileY).png"
    }
    let baseTileSize = 256
    let tileSizeScalar = Int(UIScreen.main.scale.rounded())
    let tileSize = baseTileSize * tileSizeScalar
    let urls: GMSTileURLConstructor = { (x, y, zoom) in
      let url = urlString(variant: mapVariant.rawValue,
                          tileSize: tileSize,
                          zoomLevel: zoom,
                          tileX: x,
                          tileY: y)
      return URL(string: url)
    }

    // Create the GMSTileLayer
    let layer = GMSURLTileLayer(urlConstructor: urls)

    layer.zIndex = 100
    return layer
  }

  private func setupViews() {
    title = Constants.title
    addChild(appBar.headerViewController)
    appBar.headerViewController.headerView.backgroundColor = Constants.headerBackgroundColor
    appBar.navigationBar.tintColor = Constants.titleColor

    let font = UIFont(name: Constants.titleFont, size: Constants.titleHeight)
    var attributes: [NSAttributedString.Key: Any] =
        [ NSAttributedString.Key.foregroundColor: Constants.titleColor ]
    if let font = font {
      attributes[NSAttributedString.Key.font] = font
    }
    appBar.navigationBar.titleTextAttributes = attributes

    edgesForExtendedLayout = []

    mapView.delegate = self
    view.addSubview(mapView)
    mapView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(variantButton)
    view.addSubview(variantSelectorView)
    variantSelectorView.isHidden = true

    card.delegate = self
    view.addSubview(card)
    card.translatesAutoresizingMaskIntoConstraints = false
    isCardVisible = activeMarkers.count >= 1

    appBar.addSubviewsToParent()

    let views: [String: UIView] = [
      "mapView": mapView,
      "headerView": appBar.headerViewController.headerView,
      "card": card
    ]
    var constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[mapView]|",
                                                     options: [],
                                                     metrics: nil,
                                                     views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[headerView][mapView]|",
                                                  options: [],
                                                  metrics: nil,
                                                  views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:[card]-8-|",
                                                  options: [],
                                                  metrics: nil,
                                                  views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-6-[card]-6-|",
                                                  options: [],
                                                  metrics: nil,
                                                  views: views)
    constraints += [
      NSLayoutConstraint(item: variantButton,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: bottomLayoutGuide,
                         attribute: .top,
                         multiplier: 1,
                         constant: -44),
      NSLayoutConstraint(item: variantButton,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: view,
                         attribute: .right,
                         multiplier: 1,
                         constant: -16)
    ]

    constraints += [
      NSLayoutConstraint(item: variantSelectorView,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: variantButton,
                         attribute: .top,
                         multiplier: 1,
                         constant: -12),
      NSLayoutConstraint(item: variantSelectorView,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: view,
                         attribute: .right,
                         multiplier: 1,
                         constant: -10)
    ]
    NSLayoutConstraint.activate(constraints)
  }

  func deselectActiveMarkers() {
    if activeMarkers.count > 0 {
      for marker in activeMarkers {
        marker.tracksViewChanges = true
        if let customIconView = markerIconView(marker: marker) {
          customIconView.selected = false
        }
        marker.tracksViewChanges = false
      }
    }
    activeMarkers.removeAll(keepingCapacity: true)
    isCardVisible = false
  }

  func selectActiveMarker(marker: GMSMarker) {
    guard !activeMarkers.contains(marker) else {
      return
    }

    deselectActiveMarkers()
    activeMarkers.append(marker)
    marker.tracksViewChanges = true

    let update = GMSCameraUpdate.setTarget(marker.position)
    mapView.animate(with: update)

    if let customIconView = markerIconView(marker: marker) {
      customIconView.selected = true
    }
    marker.tracksViewChanges = false

    if let mapItem = mapItem(marker: marker), !mapItem.title.isEmpty {
      card.title = mapItem.title
      card.subtitle = mapItem.subtitle
      card.details = mapItem.description
      isCardVisible = true
      logSelectedMapItem(withTitle: mapItem.title)
    } else {
      isCardVisible = false
    }
  }

  func logSelectedMapItem(withTitle title: String) {
    Application.sharedInstance.analytics.logEvent(AnalyticsEventSelectContent, parameters: [
      AnalyticsParameterItemID: AnalyticsParameters.itemID(forPinTitle: title),
      AnalyticsParameterContentType: AnalyticsParameters.uiEvent,
      AnalyticsParameters.uiAction: AnalyticsParameters.mapPinSelect
    ])
  }

  func mapItem(marker: GMSMarker) -> MapItemViewModel? {
    return marker.userData as? MapItemViewModel
  }

  func markerIconView(marker: GMSMarker) -> MapMarkerIconView? {
    return marker.iconView as? MapMarkerIconView
  }

  func updateMarkerVisibility() {
    // Hide or show markers based on zoom level.
    let position = mapView.camera
    if position.zoom < Constants.venueCameraZoom {
      for marker in googleMarkers {
        marker.map = nil
      }
    } else {
      for marker in googleMarkers {
        if let view = markerIconView(marker: marker),
          view.shouldShowTitleButton(zoomLevel: position.zoom, mapViewSize: mapView.frame.size) {
          marker.map = mapView
        } else {
          marker.map = nil
        }
      }
    }
  }
}

// MARK: - MapCardViewDelegate

extension MapViewController: MapCardViewDelegate {
  func viewDidTapDismiss() {
    isCardVisible = false
    deselectActiveMarkers()
  }
}

// MARK: - GMSMapViewDelegate

extension MapViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
    if activeMarkers.contains(marker) {
      deselectActiveMarkers()
    } else {
      selectActiveMarker(marker: marker)
    }
    return true
  }

  func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
    deselectActiveMarkers()
  }

  func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
    updateMarkerVisibility()
  }
}
