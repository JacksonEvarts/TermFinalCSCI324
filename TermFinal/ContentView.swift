//
//  ContentView.swift
//  TermFinal
//
//  Created by Jackson Evarts, Eli Werstler, Thomas Creighton on 3/26/23.

import MapKit
import SwiftUI
import CoreLocation

// struct that holds the latitude and longitude coordinates of a pin, as well as a photo
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
    @State private var countDownTimer = 0
    @State private var timerRunning = false
    @State private var showingCamera = false
    @State private var numPinsString = ""
    @State private var numPins = 0
    @State private var selectedImage: UIImage?
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.235830, longitude: -71.811030), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @StateObject private var viewModel = LocationViewModel()
    @State var MapLocations = [MapLocation]()
    @State private var userLocation: CLLocation?
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect() // timer that fires every second and publishes the time to the view
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
    // returns true if user is within specified radius of pin
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
    
    // returns the index of the pin closest to the user's current location
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
    
    // returns the color of a pin based on whether it has a photo
    func pinColor(location: MapLocation) -> Color {
        return location.photo != nil ? .green : .red
    }
    
    // hides the keyboard
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
                    HStack{
                        // button which when pressed, shifts view to zoom in to set depth centered at user location
                        Button(action:{
                            zoomToUser = zoomToUser ? false : true
                        }){
                            Text("Zoom to location").foregroundColor(.black).fontWeight(.bold).frame(width: 150)
                        }.background(Color.blue).clipShape(Capsule()).padding()
                        Spacer()
                        // displays clock, which counts down
                        Text("\(countDownTimer/60):\(countDownTimer % 60, specifier: "%02d")").onReceive(timer){ _ in
                            if countDownTimer > 0  && timerRunning{
                                countDownTimer -= 1
                            } else {
                                timerRunning = false
                            }
                            
                        }.background(Color.white).clipShape(Capsule()).opacity(timerRunning ? 1.0 : 0.0).font(.title).foregroundColor(Color.black).frame(width: 150)
                    }
                    Spacer()
                    VStack{
                        // at start of game, displays text field for user to enter desired number of pins
                        TextField("Enter number of pins", text: numPinsStringBinding)
                    }.textFieldStyle(.roundedBorder).frame(width: 300).font(.callout).cornerRadius(40).opacity(numPins > 0 ? 0.0 : 1.0)
                    // button which accepts entered value in text field
                    Button(action:{
                        numPins = Int(numPinsString) ?? 0
                        // two minutes per pin
                        countDownTimer = numPins * 120
                        timerRunning = true
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
                        // camera button, which activates only when user is in range of a pin
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
                // opens camera view and allows user to take photo. Photo is assigned to closest pin in range
                .sheet(isPresented: $showingCamera) {
                    ImagePicker(sourceType: .camera) { image in
                        selectedImage = image
                        if let selectedIndex = MapLocations.firstIndex(where: { userLocation?.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) ?? 0 <= 5 }) {
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
    
    // checks if user has enabled location services
    func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
        } else {
            print("Err")
        }
    }
    
    // checks the authorization status for using the user's location. if not determined, asks. If denied, user can't use location features
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
    
    // delegate method that gets called when the authorization status changes. It calls checkLocationAuthorization() to check the new status
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    // called when the location manager updates the user's location. Updates user location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationManager?.stopUpdatingLocation()
        NotificationCenter.default.post(name: NSNotification.Name("UserLocationUpdated"), object: location)
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion // region that map displays at given moment
    @Binding var userLocation: CLLocation? // user's location
    @Binding var MapLocations: [MapLocation] // array of pins
    @Binding var zoomToUser: Bool // boolean whether map should zoom to user's location
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    // called whenever the view needs to be updated, such as when the user's location changes. This function updates the map's region and annotations based on the bound data
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
    
    // creates and returns a new instance of Coordinator, which is an internal class used to handle interactions with the map view
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // class with several functions that handle events such as changes to the user's location or taps on map annotations
    class Coordinator: NSObject, MKMapViewDelegate {
        var mapView: MapView
        
        init(_ mapView: MapView) {
            self.mapView = mapView
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(userLocationUpdated(notification:)), name: NSNotification.Name("UserLocationUpdated"), object: nil)
        }
        
        // called whenever the user's location is updated. It updates the MapView struct's userLocation property and sets the map's center to the user's new location
        @objc func userLocationUpdated(notification: Notification) {
            if let location = notification.object as? CLLocation {
                mapView.userLocation = location
                mapView.region.center = location.coordinate
            }
        }
        // called whenever the map view needs to display an annotation, such as a pin
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil } // guard statement checks if the annotation is not the user's location annotation. If it is, the function returns nil
            let identifier = "MapPin" // string identifier for the annotation view. Used to dequeue reusable annotation views and improve performance when displaying many annotations on the map
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) // attempts to dequeue a reusable annotation view from the map view's reuse queue using the identifier we defined earlier. If there's no reusable view available, a new one is created
            // checks if a reusable annotation view was dequeued or a new one was created in the previous line. If a reusable view was dequeued, it is assigned to annotationView. If a new view was created, it is assigned to annotationView and some additional properties are set
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.canShowCallout = true
            } else {
                annotationView!.annotation = annotation
            }
            // finds the MapLocation object that corresponds to the current annotation by checking if its latitude and longitude match the annotation's coordinates
            let location = self.mapView.MapLocations.first { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }
            // checks if the MapLocation object corresponding to the annotation has a photo. If it does, a new UIImageView is created with the photo and added as a left callout accessory view to the annotation view
            if let location = location, let photo = location.photo {
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 100))
                imageView.image = photo
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                annotationView!.leftCalloutAccessoryView = imageView
            }
            
            (annotationView as? MKMarkerAnnotationView)?.markerTintColor = location?.photo != nil ? .green : .red // sets the marker tint color of the annotation view to green if the corresponding MapLocation object has a photo and red otherwise
            
            return annotationView
        }
        // called when the user's location is updated. Sets the userLocation property of the MapView to a new CLLocation object with the updated coordinates
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            self.mapView.userLocation = CLLocation(latitude: userLocation.coordinate.latitude,
                                                   longitude: userLocation.coordinate.longitude)
        }
    }
}

// struct handles image picking functionality for the user
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType // will be used to determine the source of the image
    var completionHandler: (UIImage?) -> Void
    
    // required by the UIViewControllerRepresentable protocol. Creates a new UIImagePickerController, sets its sourceType, and assigns the context's coordinator as its delegate
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = context.coordinator
        return imagePickerController
    }
    
    // required function by protocol. Does nothing
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }
    
    // required function by protocol. Creates a new Coordinator object that will handle the image picker delegate methods
    func makeCoordinator() -> Coordinator {
        return Coordinator(completionHandler: completionHandler)
    }
    
    //
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var completionHandler: (UIImage?) -> Void
        // Initializes the Coordinator object and sets its completionHandler property to the passed in closure
        init(completionHandler: @escaping (UIImage?) -> Void) {
            self.completionHandler = completionHandler
        }
        
        // required function by protocol. Checks if an image was selected by the user and calls the completionHandler closure with the image or nil accordingly
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                completionHandler(image)
            } else {
                completionHandler(nil)
            }
        }
        
        // required function by protocol. Calls the completionHandler closure with nil since the user cancelled the selection process
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completionHandler(nil)
        }
    }
}
