//
//  DemoLocationViewController.swift
//  AC3.2-CoreLocation-MKMaps
//
//  Created by Ana Ma on 1/5/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class DemoLocationViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    let locationManager: CLLocationManager = {
        let locMan: CLLocationManager = CLLocationManager()
        //more here later
        locMan.desiredAccuracy = 100.0
        locMan.distanceFilter = 10.0
        return locMan
    }()
    
    // MARK: -MKMapView Delegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer: MKCircleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
        circleRenderer.lineWidth = 1.0
        circleRenderer.strokeColor = UIColor.blue
        circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
        
        return circleRenderer
    }
    
    let geocoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        self.locationManager.delegate = self
        self.mapView.delegate = self
        
        setupViewHierarchy()
        configureConstraints()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configureConstraints() {
        let _ = [
            latLabel,
            longLabel,
            geocodeLocationLabel,
            mapView,
            permissionButton
            ].map{ $0.translatesAutoresizingMaskIntoConstraints = false}
        
        let _ = [
            // labels
            latLabel.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 8.0),
            latLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            longLabel.topAnchor.constraint(equalTo: latLabel.bottomAnchor, constant: 8.0),
            longLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            geocodeLocationLabel.topAnchor.constraint(equalTo: longLabel.bottomAnchor, constant: 8.0),
            geocodeLocationLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            // map
            mapView.topAnchor.constraint(equalTo: geocodeLocationLabel.bottomAnchor, constant: 16.0),
            mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: permissionButton.topAnchor, constant: -16.0),
            
            // buttons
            permissionButton.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor, constant: -16.0),
            permissionButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            ].map { $0.isActive = true }
    }
    
    func setupViewHierarchy() {
        //add labels
        self.view.addSubview(latLabel)
        self.view.addSubview(longLabel)
        self.view.addSubview(geocodeLocationLabel)
        
        //add buttons
        self.view.addSubview(permissionButton)
        
        //add map
        self.view.addSubview(mapView)
        
        permissionButton.addTarget(self, action: #selector(didPressPermissionButton(sender:)), for: .touchUpInside)
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Oh woah, locations updated!")
        //dump(locations)
        
        //http://stackoverflow.com/questions/27338573/rounding-a-double-value-to-x-number-of-decimal-places-in-swift
        guard let validLocation: CLLocation = locations.last else {return}
        let latitude = String(format: "%.4f", validLocation.coordinate.latitude)
        let longtitude = String(format: "%.4f", validLocation.coordinate.longitude)
        self.latLabel.text = "Latitude: \(latitude)"
        self.longLabel.text = "Longtitude: \(longtitude)"
        
        //self.mapView.setCenter(validLocation.coordinate, animated: true)
        self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(validLocation.coordinate, 500.0, 500.0), animated: true)
        
        // Add pointAnnotation
        let pinAnnotation: MKPointAnnotation = MKPointAnnotation()
        pinAnnotation.title = "Hey, you're here!"
        pinAnnotation.coordinate = validLocation.coordinate
        mapView.addAnnotation(pinAnnotation)
        
        // Add subview to the pointAnnotation
        let circleOverlay: MKCircle = MKCircle(center: validLocation.coordinate, radius: 50.0)
        mapView.add(circleOverlay)
        
        geocoder.reverseGeocodeLocation(validLocation) { (placemarks:[CLPlacemark]?, error: Error?) in
            if error != nil {
                dump(error!)
            }
            dump(placemarks)
            guard let validPlaceMarks: [CLPlacemark] = placemarks,
                let validPlace: CLPlacemark = validPlaceMarks.last else { return }
            self.geocodeLocationLabel.text = "\(validPlace.name!) \t \(validPlace.locality!)"
        }
        
//        The following code it works but not ideal
//        let latitudeWithRound = Double(round(10000*validLocations.coordinate.latitude)/10000)
//        let longtitudeWithRound = Double(round(10000*validLocations.coordinate.longitude)/10000)
//        self.latLabel.text = "Latitude: \(latitudeWithRound)"
//        self.longLabel.text = "Longtitude: \(longtitudeWithRound)"
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("All good")
            //just like .resume() in URLRequest
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("Nope")
        case .notDetermined:
            print("IDK")
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error encounter")
        dump(error)
    }
    
    // MARK: - Actions
    internal func didPressPermissionButton(sender: UIButton) {
        print("Tapped Permission")
        
        // Check for permissions
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            print("All good")
            locationManager.startMonitoringSignificantLocationChanges()
        case .denied, .restricted:
            print("Nope")
            //locationManager.requestAlwaysAuthorization()
            guard let validSettingURL: URL = URL(string: UIApplicationOpenSettingsURLString) else {return}
            UIApplication.shared.open(validSettingURL, options: [:], completionHandler: nil)
        case .notDetermined:
            print("IDK")
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    // MARK: - lazy Instances
    internal lazy var latLabel: UILabel = {
        let label: UILabel = UILabel()
        label.text = "Latitude: "
        label.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightHeavy)
        return label
    }()
    
    internal lazy var longLabel: UILabel = {
        let label: UILabel = UILabel()
        label.text = "Longtitude: "
        label.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightHeavy)
        return label
    }()
    
    internal var geocodeLocationLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFont(ofSize: 24.0, weight: UIFontWeightThin)
        return label
    }()
    
    internal var mapView: MKMapView = {
        let map: MKMapView = MKMapView()
        // more on this later
        map.mapType = MKMapType.satellite
        return map
    }()
    
    internal var permissionButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setTitle("Prompt for Permission", for: .normal)
        button.backgroundColor = .yellow
        button.setTitleColor(.blue, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        // The following does not work, it compresses the words
        //button.titleEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        return button
    }()
    
}
