//
//  ContentViewModel.swift
//  TermFinal
//
//  Created by Jack Evarts on 4/2/23.
//

import MapKit

enum MapDetails {
    static let startingLocation = CLLocationCoordinate2D(latitude: 42.235830, longitude: -71.811030) // Default location to start with
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
}

final class ContentViewModel: NSObject, ObservableObject, CLLocationManagerDelegate { // delegate is to make sure if the user changes their location settings, the app will be updated
    
    
    // Published keyword means whenever this changes the UI will update
    @Published var region = MKCoordinateRegion(center: MapDetails.startingLocation,
                                               span: MapDetails.defaultSpan)
    
    var locationManager: CLLocationManager? // Must be optional if the user has turned off location services
    private func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled(){
            locationManager = CLLocationManager()
            locationManager!.delegate = self // force unwrapping
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest // Can use different desired accuracies
            checkLocationAuthorization()
            
        } else {
            // TODO: Show an alert letting them know this is off!
            print("")
            
        }
    }
    
    public func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return } // unwrap the optional so we can use 'locationManager' in the function
        switch locationManager.authorizationStatus {
            
            case .notDetermined: // ask for permission
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                print("Your location is restricted.")
            case .denied:
                print("You denied the location feature for this app.")
            case .authorizedAlways, .authorizedWhenInUse:
            region = MKCoordinateRegion(center: locationManager.location!.coordinate,
                                        span: MapDetails.defaultSpan)
            @unknown default:
                break
            
        }
        
        
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { // delegate method - anytime the location settings change this function will be called
        checkLocationAuthorization()
        
    }
}
