//
//  ContentView.swift
//  TermFinal
//
//  Created by Jackson Evarts, Eli Werstler, Thomas Creighton on 3/26/23.

import MapKit
import SwiftUI
import CoreLocation

struct MapLocation: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    var photo: UIImage?
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct ContentView: View {
    @State private var showingCamera = false
    @State private var numPinsString = ""
    @State private var numPins = 0
    @State private var selectedImage: UIImage?
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.235830, longitude: -71.811030), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @StateObject private var viewModel = LocationViewModel()
    @State var MapLocations = [MapLocation]()
    @State private var userLocation: CLLocation?
    @State private var zoomToUser = false
    // Ensures user enters integer value
    private var numPinsStringBinding: Binding<String> {
        Binding(
            get: { numPinsString },
            set: {newValue in
                let filteredValue = String(newValue.filter { "0123456789".contains($0) })
                numPinsString = filteredValue
            }
        )
    }

    func userIsNearPin(distance: Double = 5) -> Bool {
        guard let userLocation = userLocation else { return false }
        for location in MapLocations {
            let pinLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            if userLocation.distance(from: pinLocation) <= distance {
                return true
            }
        }
        return false
    }
    
    func closestPinIndex() -> Int? {
        guard let userLocation = userLocation else { return nil }
        var closestPinIndex: Int?
        var closestDistance: CLLocationDistance?
        for (index, location) in MapLocations.enumerated() {
            let pinLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            let distance = userLocation.distance(from: pinLocation)
            if closestDistance == nil || distance < closestDistance! {
                closestDistance = distance
                closestPinIndex = index
            }
        }
        return closestPinIndex
    }

    func pinColor(location: MapLocation) -> Color {
        return location.photo != nil ? .green : .red
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        NavigationView {
            ZStack {
                MapView(region: $region, userLocation: $userLocation, MapLocations: $MapLocations, zoomToUser: $zoomToUser)
                    .ignoresSafeArea()
                    .accentColor(Color(.systemMint))
                    .onAppear {
                        viewModel.checkLocationAuthorization()
                    }
                VStack {
                    Spacer()
                    VStack{
                        TextField("Enter number of pins", text: numPinsStringBinding)
                    }.textFieldStyle(.roundedBorder).frame(width: 300).font(.callout).cornerRadius(40).opacity(numPins > 0 ? 0.0 : 1.0)
                    Button(action:{
                        numPins = Int(numPinsString) ?? 0
                        var deployPins = numPins
                        while (deployPins > 0){
                            deployPins -= 1
                            MapLocations.append(MapLocation(name: "PIN\(deployPins + 1)", latitude: (userLocation?.coordinate.latitude)!  + Double.random(in: -0.00833...0.00833) , longitude: (userLocation?.coordinate.longitude)! + Double.random(in: -0.00833...0.00833) ))
                        }
                        hideKeyboard()
                        zoomToUser = true
                    }){
                        Text("Press to begin").foregroundColor(.black).fontWeight(.bold).frame(width: 150)
                    }.background(Color.blue).clipShape(Capsule()).opacity(numPins > 0 ? 0.0 : 1.0)
                    HStack {
                        Spacer()
                        Button(action: {
                            if userIsNearPin() {
                                showingCamera = true
                            }
                        }) {
                            Image(systemName: "camera.circle.fill")
                                .resizable()
                                .frame(width: 75, height: 75)
                                .padding()
                        }
                        .disabled(!userIsNearPin())
                        .opacity(userIsNearPin() ? 1 : 0.5)
                        .padding()
                        Spacer()
                    }
                }
                .sheet(isPresented: $showingCamera) {
                    ImagePicker(sourceType: .camera) { image in
                        selectedImage = image
                        if let selectedIndex = closestPinIndex(), userLocation?.distance(from: CLLocation(latitude: MapLocations[selectedIndex].latitude, longitude: MapLocations[selectedIndex].longitude)) ?? 0 <= 5 {
                            MapLocations[selectedIndex].photo = image
                        }
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

final class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    
    func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
        } else {
            print("Err")
        }
    }
    
    public func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("Your location is restricted.")
        case .denied:
            print("You denied the location feature for this app.")
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation() // Start updating the user's location
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    // Add this function to update the user location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationManager?.stopUpdatingLocation()
        NotificationCenter.default.post(name: NSNotification.Name("UserLocationUpdated"), object: location)
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var userLocation: CLLocation?
    @Binding var MapLocations: [MapLocation]
    @Binding var zoomToUser: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        if zoomToUser, let userLocation = userLocation {
            region.center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
            region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            view.setRegion(region, animated: true)
            zoomToUser = false
        }
        if let userLocation = userLocation {
            region.center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        }
        view.removeAnnotations(view.annotations)
        for location in MapLocations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = location.name
            view.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var mapView: MapView
        
        init(_ mapView: MapView) {
            self.mapView = mapView
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(userLocationUpdated(notification:)), name: NSNotification.Name("UserLocationUpdated"), object: nil)
        }
        
        @objc func userLocationUpdated(notification: Notification) {
            if let location = notification.object as? CLLocation {
                mapView.userLocation = location
                mapView.region.center = location.coordinate
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let identifier = "MapPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.canShowCallout = true
            } else {
                annotationView!.annotation = annotation
            }
            
            let location = self.mapView.MapLocations.first { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }
            if let location = location, let photo = location.photo {
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 100))
                imageView.image = photo
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                annotationView!.leftCalloutAccessoryView = imageView
            }
            
            (annotationView as? MKMarkerAnnotationView)?.markerTintColor = location?.photo != nil ? .green : .red
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            self.mapView.userLocation = CLLocation(latitude: userLocation.coordinate.latitude,
                                                   longitude: userLocation.coordinate.longitude)
        }
    }
}
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var completionHandler: (UIImage?) -> Void
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = context.coordinator
        return imagePickerController
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(completionHandler: completionHandler)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var completionHandler: (UIImage?) -> Void
        
        init(completionHandler: @escaping (UIImage?) -> Void) {
            self.completionHandler = completionHandler
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                completionHandler(image)
            } else {
                completionHandler(nil)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completionHandler(nil)
        }
    }
}
