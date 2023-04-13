//
//  ContentView.swift
//  TermFinal
//
//  Created by Jackson Evarts, Eli Werstler, Thomas Creighton on 3/26/23.

import MapKit
import SwiftUI

struct MapLocation: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    var coordinate: CLLocationCoordinate2D{
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct ContentView: View {
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.235830, longitude: -71.811030), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @StateObject private var viewModel = ContentViewModel() // Making content view model observable
    @State var MapLocations = [MapLocation(name: "PIN 1", latitude: 42.2392, longitude: -71.8080), MapLocation(name: "PIN 2", latitude: 40.8559, longitude: -73.2007)]
    
    var body: some View {
        NavigationView{
            VStack {
                ZStack{
                    Map(coordinateRegion: $region,
                        interactionModes: MapInteractionModes.all, showsUserLocation: true,
                        annotationItems: MapLocations,
                        annotationContent: {
                        location in MapMarker(coordinate: location.coordinate, tint: .red)
                    }
                    ) // shows location if we have user's permission
                    .ignoresSafeArea()
                    .accentColor(Color(.systemMint))
                    .onAppear {
                        viewModel.checkLocationAuthorization()
                    }
                    NavigationLink(destination: CameraView()) {
                        
                        Image(systemName: "camera.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 100)

                    }
                    
                    
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

final class ContentViewModel: NSObject, ObservableObject, CLLocationManagerDelegate{
    var locationManager: CLLocationManager?
    
    func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled(){
            locationManager = CLLocationManager()
            locationManager!.delegate = self // force unwrapping
        } else {
            // TODO: Show an alert letting them know this is off!
            print("Err")
            
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
                break
            @unknown default:
                break
            
        }
        
        
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { // delegate method - anytime the location settings change this function will be called
        checkLocationAuthorization()
        
    }
}
