import UIKit
import MapKit
import CoreLocation

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
            let userEmail = "Sai@gmail.com"
            let userPassword = "newPassword135"
            AuthenticationService.manager.createUser(email: userEmail, password: userPassword, completion: { (user) in
                let myCar = Car(carMake: "Rimac Automobili", carModel: "Concept One", carYear: "2018", carImageId: nil)
                let vehicleOwner = VehicleOwner(userName: "AlD", userImage: nil, userUID: user.uid, car: myCar, rewardPoints: 100, swapUserUID: nil)
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

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let markerView = view as! MKMarkerAnnotationView
        // Testing reserving a spot
        // let coord = Coord(coordinate: view.annotation!.coordinate)
        markerView.markerTintColor = Stylesheet.Colors.PinkMain
    }
    
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
            // TODO: - Create custom detail view, inject it with `annotation` for data.
            let detailView = UILabel()
            let lat = String(annotation.coordinate.latitude).prefix(5)
            let long = String(annotation.coordinate.longitude).prefix(5)
            detailView.text = "LAT: \(lat), LONG: \(long)"
            
            annotationView?.annotation = annotation
            annotationView?.markerTintColor = Stylesheet.Colors.BlueMain
            annotationView?.canShowCallout = true
            annotationView?.detailCalloutAccessoryView = detailView
            
            let button = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = button
        default:
            break
        }

        return annotationView
    }

}

extension MapViewController: LocationServiceDelegate {
    func userLocationDidUpdate(_ userLocation: CLLocation) {
        setMapRegion(around: userLocation)
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
