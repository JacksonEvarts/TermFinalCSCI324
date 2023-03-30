//
//  ContentView.swift
//  TermFinal
//
//  Created by Jackson Evarts, Eli Werstler, Thomas Creighton on 3/26/23.

import MapKit
import SwiftUI


struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel() // Making content view model observable
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.235830, longitude: -71.811030),
                                                   span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
    // Setting span to 0.01 looks pretty good too TODO: Experiment with the scale
    
    var body: some View {
        VStack {
            Map(coordinateRegion: $region, showsUserLocation: true) // shows location if we have user's permission
                .ignoresSafeArea()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

final class ContentViewModel: ObservableObject {
    // TODO: look into using classes in Swift + why is this final? what is an observable object? why is it a class?
    
    var locationManager: CLLocationManager? // Must be optional if the user has turned off location services
    func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled(){
            locationManager = CLLocationManager()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest // Can use different desired accuracies
        } else {
            // TODO: Show an alert letting them know this is off!
            print("")
            
        }
            // Currently at 9:30 in https://www.youtube.com/watch?v=hWMkimzIQoU
            
    }
    /*
    func checkLocationAuthorization() {
        guard
            // TODO: Look into how guard works and unwrapping works in tutorials
    } */
}
