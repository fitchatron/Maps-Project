//
//  MainController.swift
//  Maps Project
//
//  Created by James Fitch on 11/11/19.
//  Copyright © 2019 Fitchatron. All rights reserved.
//

import UIKit
import SwiftUI
import MapKit
import LBTATools

extension MainController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //if the annotation is a MKPointAnnotion then show pins else return nil
        if (annotation is MKPointAnnotation) {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "id")
            annotationView.canShowCallout = true
            //annotationView.image = #imageLiteral(resourceName: "tourist")
            return annotationView
        }
        return nil
    }
}

extension MainController: CLLocationManagerDelegate {
    fileprivate func requestUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            print("Received authorization of user location")
            // request for where the user actually is
            locationManager.startUpdatingLocation()
        default:
            print("Failed to authorize")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let firstLocation = locations.first else { return }
        mapView.setRegion(.init(center: firstLocation.coordinate, span: .init(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: false)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let customAnnotation = view.annotation as? CustomMapItemAnnotation else { return }
        //search array of location items annotation name
        guard let index = self.locationsController.items.firstIndex(where: {$0.name == customAnnotation.mapItem?.name}) else { return }
        //scroll to index
        self.locationsController.collectionView.scrollToItem(at: [0, index], at: .centeredHorizontally, animated: true)
    }
}

class MainController: UIViewController {
    
    //create a class to use over the default annotation. Allows you to assign map item to annotation for more reliable search and greater customerisation
    class CustomMapItemAnnotation: MKPointAnnotation {
        var mapItem: MKMapItem?
    }
        
    let locationManager = CLLocationManager()
    let mapView = MKMapView()
    fileprivate let searchTextField = UITextField(placeholder: "Search query")
    fileprivate let locationsController = LocationsCaroselController(scrollDirection: .horizontal)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestUserLocation()
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        view.addSubview(mapView)
        mapView.fillSuperview()
        
        setupRegionForMap()
        setupSearchUI()
        setupLocationsCarosel()
        locationsController.mainController = self
    }
    
    //creating annotations example
    fileprivate func setupAnnotations() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: 37.7666, longitude: -122.427290)
        annotation.title = "San Francisco"
        annotation.subtitle = "CA"
        
        mapView.addAnnotation(annotation)
        
        let appleAnnotation = MKPointAnnotation()
        appleAnnotation.coordinate = CLLocationCoordinate2D(latitude: 37.3326, longitude: -122.030024)
        appleAnnotation.title = "Apple HQ"
        appleAnnotation.subtitle = "Cupertino, CA"
        
        mapView.addAnnotation(appleAnnotation)
        mapView.showAnnotations(self.mapView.annotations, animated: true)
    }
    
    fileprivate func setupRegionForMap() {
        let centerLocation = CLLocationCoordinate2D(latitude: 37.7666, longitude: -122.427290)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: centerLocation, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    fileprivate func performLocalSearch() {
        print("region is", mapView.region)
        let request = MKLocalSearch.Request()
        
        request.naturalLanguageQuery = searchTextField.text
        request.region = mapView.region //uses the mapView's region for the search term
        
        let localSearch = MKLocalSearch(request: request)
        localSearch.start { (response, error) in
            if let err = error {
                print("Failed local search:" ,err)
                return
            }
            //remove old annotations before adding the search results annotations back in
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.locationsController.items.removeAll()
            //success returns an array of responses loop through and
            response?.mapItems.forEach({ (mapItem) in
                               
                //create the annotation using MKMapItem
                self.createAnnotation(mapItem: mapItem)
                
                //tell LocationsCaroselController the response results
                self.locationsController.items.append(mapItem)
            })
            
            //bring the detail controller back to the first item
            self.locationsController.collectionView.scrollToItem(at: [0, 0], at: .centeredHorizontally, animated: true)
            //show annotations
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
    }
    
    fileprivate func setupSearchUI() {
        let whiteContainer = UIView(backgroundColor: .white)
        
        view.addSubview(whiteContainer)
        whiteContainer.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 16, bottom: 0, right: 16))
        whiteContainer.stack(searchTextField).withMargins(.allSides(16))
        
        //search throttling using the new NotificationCenter
        _ = NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: searchTextField)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { (_) in
                self.performLocalSearch()
        }
    }
    
    fileprivate func setupLocationsCarosel() {
        let locationView = locationsController.view!
        
        view.addSubview(locationView)
        
        locationView.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, size: .init(width: 0, height: 150))
    }
    
    fileprivate func createAnnotation(mapItem: MKMapItem) {
        let annotation = CustomMapItemAnnotation()
        annotation.mapItem = mapItem
        annotation.coordinate =  mapItem.placemark.coordinate
        annotation.title = mapItem.name
        self.mapView.addAnnotation(annotation)
    }
}

struct MainPreview: PreviewProvider {
    
    static var previews: some View {
        ContainerView().edgesIgnoringSafeArea(.all )
    }
    
    struct ContainerView: UIViewControllerRepresentable {
        func makeUIViewController(context: UIViewControllerRepresentableContext<MainPreview.ContainerView>) -> MainController {
            return MainController()
        }
        
        func updateUIViewController(_ uiViewController: MainController, context: UIViewControllerRepresentableContext<MainPreview.ContainerView>) {
            
        }
        
        typealias UIViewControllerType = MainController
    }
}

extension MKMapItem {
    func address() -> String {
        var addressString = String()
        
        if let unit = placemark.subThoroughfare {
            addressString.append(unit + " ")
        }
        if let streetAddress = placemark.thoroughfare {
            addressString.append(streetAddress + ", ")
        }
        if let suburb = placemark.locality {
            addressString.append(suburb + ", ")
        }
        if let postcode = placemark.postalCode {
            addressString.append(postcode + ", ")
        }
        if let state = placemark.administrativeArea {
            addressString.append(state + ", ")
        }
        if let country = placemark.countryCode {
            addressString.append(country)
        }
        return addressString
    }
}
