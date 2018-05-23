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
import Platform

class MapViewController: UIViewController {

  let appBar = MDCAppBar()

  fileprivate enum Constants {
    /// Location of the venue. The large venue marker is displayed at this location.
    static let venueCoordinates = CLLocationCoordinate2D(latitude: 37.426360, 
                                                         longitude: -122.079552)
    static let degreesLongitude = 0.005900
    static let degreesLatitude = 0.005600
    static let startingLongitude = -122.082526
    static let startingLatitude = 37.422600
    static let overlaySouthWest = CLLocationCoordinate2D(latitude: startingLatitude, longitude: startingLongitude)
    static let overlayNorthEast = CLLocationCoordinate2D(latitude: startingLatitude + degreesLatitude,
                                                         longitude: startingLongitude + degreesLongitude)
    static let venueCameraZoomDefault: Float = 17.7
    static let venueCameraZoom: Float = 17.7

    static let defaultBearing: Double = 0

    static let overlayWidth: CGFloat = 950
    static let overlayHeight: CGFloat = 1170

    static let labelMarkerExtraPaddingWidth: CGFloat = 27
    static let labelMarkerExtraPaddingHeight: CGFloat = 0
    static let markerWidth: CGFloat = 27
    static let markerHeight: CGFloat = 60
    static let markerFont = MDCTypography.fontLoader().mediumFont(ofSize: 12)!

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
    static let filterButtonTitle =
        NSLocalizedString("Filter", comment: "Button title that opens a list of filters")
    static let enableFilterFeature = false
    static let placeIcon = "ic_place"
  }

  // MARK: - Properties
  private static var initializedAPIKey = false
  fileprivate lazy var mapView: GMSMapView = self.setupMapView()
  private lazy var overlay: GMSOverlay = self.setupOverlay()
  private lazy var card: MapCardView = self.setupMapCardView()

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
    viewModel.update {
      self.refreshUI()
    }
  }

  func refreshUI() {
    // Remove any existing markers.
    for marker in googleMarkers {
      marker.map = nil
      marker.userData = nil
    }
    googleMarkers.removeAll()

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
                                   attributes: [NSAttributedStringKey.font: Constants.markerFont],
                                   context: nil).size.width
        width += Constants.labelMarkerExtraPaddingWidth
        height += Constants.labelMarkerExtraPaddingHeight
      }

      let iconView = MapMarkerIconView(frame: CGRect(x: 0, y: 0, width: width, height: height),
                                       mapItemType: mapItem.type)
      iconView.title = googleMarker.title
      googleMarker.iconView = iconView
      if mapItem.type == .label {
        googleMarker.groundAnchor = CGPoint(x: 0.5, y: 0)
      }
      googleMarker.tracksViewChanges = false
      googleMarker.map = mapView
      googleMarker.userData = mapItem
      googleMarker.zIndex = mapItem.type == .label ? 2 : 1
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

  func setupFilterButton() -> UIBarButtonItem {
    let button = UIBarButtonItem.init(title: Constants.filterButtonTitle,
                                      style: .plain,
                                      target: self,
                                      action: #selector(filterAction))
    button.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: Constants.titleColor],
                                  for: .normal)
    return button
  }

  func setupCenterButton() -> UIBarButtonItem {
    let button = UIBarButtonItem.init(image: UIImage(named: Constants.placeIcon)?.withRenderingMode(.alwaysTemplate),
                                      style: .plain,
                                      target: self,
                                      action: #selector(centerAction))
    button.tintColor = Constants.titleColor
    button.accessibilityLabel = NSLocalizedString("Center conference on map", comment: "Accessibility label for center button.")
    return button
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
    mapView.settings.myLocationButton = true
    mapView.settings.compassButton = true
    overlay.map = mapView
    return mapView
  }

  private func setupOverlay() -> GMSOverlay {
    let mapImage = UIImage(named: "map.png")
    let overlayBounds = GMSCoordinateBounds(coordinate: Constants.overlaySouthWest, coordinate: Constants.overlayNorthEast)

    let overlay = GMSGroundOverlay(bounds: overlayBounds, icon: mapImage)
    overlay.bearing = 0
    return overlay
  }

  private func setupMapCardView() -> MapCardView {
    return MapCardView()
  }

  private func setupViews() {
    self.title = Constants.title
    self.addChildViewController(appBar.headerViewController)
    appBar.headerViewController.headerView.backgroundColor = Constants.headerBackgroundColor
    appBar.navigationBar.tintColor = Constants.titleColor

    let font = UIFont(name: Constants.titleFont, size: Constants.titleHeight)
    var attributes: [NSAttributedStringKey: Any] =
        [ NSAttributedStringKey.foregroundColor: Constants.titleColor ]
    if let font = font {
      attributes[NSAttributedStringKey.font] = font
    }
    appBar.navigationBar.titleTextAttributes = attributes

    edgesForExtendedLayout = []

    mapView.delegate = self
    view.addSubview(mapView)
    mapView.translatesAutoresizingMaskIntoConstraints = false

    card.delegate = self
    view.addSubview(card)
    card.translatesAutoresizingMaskIntoConstraints = false
    isCardVisible = activeMarkers.count >= 1

    appBar.addSubviewsToParent()
    if (Constants.enableFilterFeature) {
      self.navigationItem.rightBarButtonItems = [setupFilterButton(), setupCenterButton()]
    } else {
      self.navigationItem.rightBarButtonItems = [setupCenterButton()]
    }

    let views: [String: UIView] = ["mapView": mapView, "headerView": appBar.headerViewController.headerView, "card": card]
    var constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[mapView]|",
                                                     options: [],
                                                     metrics: nil,
                                                     views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[headerView][mapView]|",
                                                  options: [],
                                                  metrics: nil,
                                                  views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:[card]-8-|", options: [], metrics: nil, views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-6-[card]-6-|", options: [], metrics: nil, views: views)
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

    if let mapItem = mapItem(marker: marker), mapItem.title != "" {
      card.title = mapItem.title
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
    if let mapItem = marker.userData as? MapItemViewModel {
      return mapItem
    }
    return nil
  }

  func markerIconView(marker: GMSMarker) -> MapMarkerIconView? {
    return marker.iconView as? MapMarkerIconView
  }

  func pairedMarker(markerNeedingPair: GMSMarker) -> GMSMarker? {
    guard let mapItemNeedingPair = mapItem(marker: markerNeedingPair) else { return nil }
    guard let tagNeedingPair = mapItemNeedingPair.tag else { return nil }
    for marker in googleMarkers {
      if marker == markerNeedingPair {
        continue
      }
      if let mapItem = mapItem(marker: marker), let tag = mapItem.tag, tag == tagNeedingPair {
        return marker
      }
    }
    return nil
  }

  func updateMarkerVisibility() {
    // Hide or show markers based on zoom level.
    let position = mapView.camera
    if position.zoom < Constants.venueCameraZoom {
      for marker in googleMarkers {
        marker.map = nil
      }
    } else if !viewModel.anyItemsSelected {
      // Check if no items are selected, meaning we should show everything.
      for marker in googleMarkers {
        marker.map = mapView
      }
    } else {
      // Check each individual selection state and add any matching labels.
      var visibleMarkers: [GMSMarker] = []
      for marker in googleMarkers {
        if let mapItem = mapItem(marker: marker), mapItem.selected {
          visibleMarkers.append(marker)
          if let pairedMaker = pairedMarker(markerNeedingPair: marker) {
            visibleMarkers.append(pairedMaker)
          }
        }
      }
      for marker in googleMarkers {
        if visibleMarkers.contains(marker) {
          marker.map = mapView
        } else {
          marker.map = nil
        }
      }
    }
  }
}

// MARK: - Actions
extension MapViewController {
  @objc func filterAction() {
    let filterViewController = MapFilterViewController(viewModel: viewModel, delegate: self)
    self.present(filterViewController, animated: true, completion: nil)
  }

  @objc func centerAction() {
    mapView.animate(to: Constants.cameraPosition)
  }
}

// MARK: - MapFilterViewControllerDelegate
extension MapViewController: MapFilterViewControllerDelegate {
  func viewControllerDidFinish() {
    self.presentedViewController?.dismiss(animated: true, completion: {
    })
    // Update map based on filtering.
    updateMarkerVisibility()
  }
}

// MARK: - MapCardViewDelegate
extension MapViewController: MapCardViewDelegate {
  func viewDidTapDismiss() {
    isCardVisible = false
  }
}

// MARK: - GMSMapViewDelegate

extension MapViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
    var markerToSelect = marker
    // If the marker is a label, try to select the matching marker.
    if let mapIcon = markerIconView(marker: marker), mapIcon.mapItemType == .label {
      if let pairedMarker = pairedMarker(markerNeedingPair: marker) {
        markerToSelect = pairedMarker
      } else {
        return true
      }
    }

    if activeMarkers.contains(markerToSelect) {
      deselectActiveMarkers()
    } else {
      selectActiveMarker(marker: markerToSelect)
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
