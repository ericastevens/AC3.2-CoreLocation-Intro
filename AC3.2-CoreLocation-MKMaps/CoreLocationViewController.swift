//
//  CoreLocationViewController.swift
//  SampleMKMapKit
//
//  Created by Louis Tur on 1/3/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class CoreLocationViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
  
  let locationManager: CLLocationManager = {
    let locMan: CLLocationManager = CLLocationManager()
    locMan.desiredAccuracy = kCLLocationAccuracyHundredMeters
    locMan.distanceFilter = 50.0
    return locMan
  }()
  
  let geocoder: CLGeocoder = CLGeocoder()
  
  
  // MARK: View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    locationManager.delegate = self
    mapView.delegate = self
    
    setupViewHierarchy()
    configureConstraints()
    adjustSubclass()
  }
  
  
  // MARK: - Setup
  private func configureConstraints() {
    let _ = [
      permissionsButton,
      clearPermissionsButton,
      latLabel,
      longLabel,
      geocodeLabel,
      mapView,
      ].map { $0.translatesAutoresizingMaskIntoConstraints = false }
    
    let _ = [
      // permission button
      permissionsButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
      permissionsButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
      
      clearPermissionsButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
      clearPermissionsButton.topAnchor.constraint(equalTo: permissionsButton.bottomAnchor, constant: 16.0),
      
      // lat
      latLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
      latLabel.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 16.0),
      
      // long
      longLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
      longLabel.topAnchor.constraint(equalTo: self.latLabel.bottomAnchor, constant: 8.0),
      
      // geocode
      geocodeLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
      geocodeLabel.topAnchor.constraint(equalTo: self.longLabel.bottomAnchor, constant: 8.0),
      
      // map
      mapView.topAnchor.constraint(equalTo: clearPermissionsButton.bottomAnchor, constant: 8.0),
      mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0),
      mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0),
      mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8.0),
      
      ].map { $0.isActive = true }
  }
  
  private func setupViewHierarchy() {
    self.view.addSubview(permissionsButton)
    self.view.addSubview(clearPermissionsButton)
    
    self.view.addSubview(latLabel)
    self.view.addSubview(longLabel)
    self.view.addSubview(geocodeLabel)
    
    self.view.addSubview(mapView)
    
    self.permissionsButton.addTarget(self, action: #selector(didTapPermissionButton(sender:)), for: .touchUpInside)
    self.clearPermissionsButton.addTarget(self, action: #selector(didTapRemovePermissionButton(sender:)), for: .touchUpInside)
  }
  
  private func adjustSubclass() {
    self.view.backgroundColor = .white
  }
  
  
  // MARK: - CoreLocation Delegate
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    
    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
      print("Authorized, start tracking")
      manager.startUpdatingLocation()
//      manager.startMonitoringSignificantLocationChanges()
      
    case .denied, .restricted:
      print("Denied or restricted, change in settings!")
      
    default:
      self.locationManager.requestAlwaysAuthorization()
    }
    
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    print("Receiving location info!:")
    dump(locations)
    
    guard let validLocation = locations.first else { return }
    
    self.latLabel.text = String(format: "Lat: %0.3f", validLocation.coordinate.latitude)
    self.longLabel.text = String(format: "Long: %0.3f", validLocation.coordinate.longitude)
    
//    mapView.setCenter(validLocation.coordinate, animated: true)
    let coordinateRegion = MKCoordinateRegionMakeWithDistance(validLocation.coordinate, 500, 500)
    mapView.setRegion(coordinateRegion, animated: true)
    
    let annotation: MKPointAnnotation = MKPointAnnotation()
    annotation.coordinate = validLocation.coordinate
    annotation.title = "This is you"
    annotation.subtitle = "I see you. - Apple"
    mapView.addAnnotation(annotation)
    
    let circleOverlay: MKCircle = MKCircle(center: annotation.coordinate, radius: 100.0)
    mapView.add(circleOverlay)
    
    geocoder.reverseGeocodeLocation(validLocation) { (placemark: [CLPlacemark]?, error: Error?) in
      if error != nil {
        dump(error!)
        return
      }
      
      dump(placemark)
      guard let validPlacemark: CLPlacemark = placemark?.last else { return }
      
      self.geocodeLabel.text = "\(validPlacemark.name!) \t \(validPlacemark.locality!)"
    }
  }
  
  
  // MARK: - Mapview Delegate
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let circleOverlayRenderer: MKCircleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
    circleOverlayRenderer.fillColor = UIColor.green.withAlphaComponent(0.25)
    circleOverlayRenderer.strokeColor = UIColor.green
    circleOverlayRenderer.lineWidth = 1.0
    
    return circleOverlayRenderer
  }
  
  
  // MARK: - Action
  internal func didTapPermissionButton(sender: UIButton) {
    
    // 1. Check authorization status:
    switch CLLocationManager.authorizationStatus() {
    case .authorizedAlways, .authorizedWhenInUse: print("All Good")
    case .denied, .restricted:
      guard let validSettingsURL: URL = URL(string: UIApplicationOpenSettingsURLString) else { return }
      UIApplication.shared.open(validSettingsURL, options: [:], completionHandler: nil)
    default:
      self.locationManager.requestAlwaysAuthorization()
    }
    
  }
  
  // 2. Toggling authorization via settings
  internal func didTapRemovePermissionButton(sender: UIButton) {
    
    switch CLLocationManager.authorizationStatus() {
    case .authorizedAlways, .authorizedWhenInUse:
      guard let validSettingsURL: URL = URL(string: UIApplicationOpenSettingsURLString) else { return }
      UIApplication.shared.open(validSettingsURL, options: [:], completionHandler: nil)
      
    default:
      print("All Good")
    }
  }
  
  // MARK: - Lazys
  lazy var permissionsButton: UIButton = {
    let button: UIButton = UIButton(type: UIButtonType.system)
    button.setTitle("Prompt for Permission".uppercased(), for: .normal)
    button.backgroundColor = .yellow
    button.contentEdgeInsets = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0)
    return button
  }()
  
  lazy var clearPermissionsButton: UIButton = {
    let button: UIButton = UIButton(type: UIButtonType.system)
    button.setTitle("Turn off Permission".uppercased(), for: .normal)
    button.backgroundColor = .red
    button.contentEdgeInsets = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0)
    return button
  }()
  
  internal lazy var latLabel: UILabel = {
    let label: UILabel = UILabel()
    label.font = UIFont.systemFont(ofSize: 24.0)
    label.text = "LAT:"
    return label
  }()
  
  internal lazy var longLabel: UILabel = {
    let label: UILabel = UILabel()
    label.font = UIFont.systemFont(ofSize: 24.0)
    label.text = "LONG:"
    return label
  }()
  
  internal lazy var geocodeLabel:  UILabel = {
    let label: UILabel = UILabel()
    label.font = UIFont.systemFont(ofSize: 24.0)
    return label
  }()
  
  internal lazy var mapView: MKMapView = {
    let mapView: MKMapView = MKMapView()
    return mapView
  }()
}
