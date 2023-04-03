//
//  ContentView.swift
//  TermFinal
//
//  Created by Jackson Evarts, Eli Werstler, Thomas Creighton on 3/26/23.

import MapKit
import SwiftUI


struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel() // Making content view model observable
    
    
    var body: some View {
        VStack {
            Map(coordinateRegion: $viewModel.region, showsUserLocation: true) // shows location if we have user's permission
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
