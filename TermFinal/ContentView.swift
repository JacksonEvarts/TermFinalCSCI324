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
    
    @StateObject private var viewModel = ContentViewModel() // Making content view model observable
    @State var MapLocations = [MapLocation(name: "PIN 1", latitude: 42.2392, longitude: -71.8080), MapLocation(name: "PIN 2", latitude: 40.8559, longitude: -73.2007)]
    
    var body: some View {
        VStack {
            Map(coordinateRegion: $viewModel.region,
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
