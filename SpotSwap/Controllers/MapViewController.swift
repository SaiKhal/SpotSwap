import UIKit
import MapKit
import CoreLocation

class VehicleOwnerServices {
    private var vehicleOwner: VehicleOwner!
    
    
    static let manager = VehicleOwnerServices()
    private init() {}
    
    public func getVehicleOwner() -> VehicleOwner {
        return vehicleOwner // app should crash if we dont have a vehicle owner
    }
    
    public func startSingleton() {
        DataBaseService.manager.retrieveCurrentVehicleOwner(completion: { vehicleOwner in
            self.vehicleOwner = vehicleOwner
        }) { error in
            print(#function, error)
        }
    }
    
    public func hasReservation() -> Bool {
        return vehicleOwner.reservation != nil
    }
}

class MapViewController: UIViewController {

    // MARK: - Properties
    var contentView: MapView!
    private var initialLaunch = true

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareNavBar()
        prepareContentView()
        LocationService.manager.setDelegate(viewController: self)
        testCreateAccount()
        VehicleOwnerServices.manager.startSingleton()
    }

    // MARK: - Setup - View/Data
    private func prepareNavBar() {
        navigationItem.title = "SpotSwap"
        navigationController?.navigationBar.barTintColor = Stylesheet.Contexts.NavigationController.BarColor
    }

    private func prepareContentView() {
        contentView = MapView(viewController: self)
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(view.snp.edges)
        }
    }
    
    func testCreateAccount(){
            let userEmail = "JazzMorphin@gmail.com"
            let userPassword = "newPassword135"
            AuthenticationService.manager.createUser(email: userEmail, password: userPassword, completion: { (user) in
                let myCar = Car(carMake: "BMW", carModel: "E30", carYear: "1988", carImageId: nil)
                let vehicleOwner = VehicleOwner(user: user, car: myCar, userName: userEmail)
                DataBaseService.manager.addNewVehicleOwner(vehicleOwner: vehicleOwner, user: user, completion: {
                    print("dev: added vehicle owner to the dataBase")
                }, errorHandler: { (error) in
                    print("error in adding a vehicle owner to the data base")
                })
            }) { (error) in
                print(error)
            }
        }

}

extension MapViewController: MKMapViewDelegate {
    
    // Create the pins and the detail view when the pin is tapped
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        // Show blue dot for user's current location
        if annotation is MKUserLocation {
            return nil
        }

        // Get instance of annotationView so we can modify color
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "myAnnotation") as? MKMarkerAnnotationView
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "myAnnotation")
        }

        // Handle if the annotation comes from an open spot, my vehicle location or a spot the user reserved
        switch annotation {
        case is Spot:
            let spot = annotation as! Spot
            // TODO: - Create custom detail view, inject it with `annotation` for data.
            let detailView = UILabel()
            let lat = String(annotation.coordinate.latitude).prefix(5)
            let long = String(annotation.coordinate.longitude).prefix(5)
            
            
            if spot.reservation == nil {
                annotationView?.markerTintColor = Stylesheet.Colors.BlueMain
                detailView.text = "LAT: \(lat), LONG: \(long)"
            } else {
                annotationView?.markerTintColor = Stylesheet.Colors.PinkMain
                detailView.text = "You have \(spot.duration) minutes!"
            }
            
            
            annotationView?.annotation = annotation
            annotationView?.canShowCallout = true
            annotationView?.detailCalloutAccessoryView = detailView
            
            let button = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = button
        default:
            break
        }

        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let markerView = view as! MKMarkerAnnotationView
        // Testing reserving a spot
        // let coord = Coord(coordinate: view.annotation!.coordinate)
        if let spot = view.annotation as? Spot {
            dump(spot)
            let currentUserReservingASpot = VehicleOwnerServices.manager.getVehicleOwner()
            contentView.mapView.removeAnnotation(spot)
            DataBaseService.manager.removeSpot(spotId: spot.spotUID)
            
            spot.reservation = Reservation(spotOwner: spot.owner, spotTaker: currentUserReservingASpot)
            DataBaseService.manager.addSpot(spot: spot)
        }
    }

}

extension MapViewController: LocationServiceDelegate {
    func userLocationDidUpdate(_ userLocation: CLLocation) {
        setMapRegion(around: userLocation)
    }
    
    func spotsUpdatedFromFirebase(_ spots: [Spot]) {
        // TODO: - Refactor. Should add and remove individual annotation
        contentView.mapView.removeAnnotations(contentView.mapView.annotations)
        contentView.mapView.addAnnotations(spots)
    }
    
}

// MARK: - Map helper functions
private extension MapViewController {
    func setMapRegion(around location: CLLocation) {
        if initialLaunch {
            let regionArea = 0.02 // smaller is more zoomed in
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: regionArea, longitudeDelta: regionArea))
            contentView.mapView.setRegion(region, animated: true)
            initialLaunch = false
        }
    }
}
