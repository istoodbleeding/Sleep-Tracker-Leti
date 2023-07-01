
import Combine
import CoreLocation
import MapKit

extension TrackingView {
  class Model: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var isLocationTrackingEnabled = false
    @Published var location: CLLocation?
    @Published var region = MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
      span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    @Published var pins: [PinLocation] = []

    let mgr: CLLocationManager

    override init() {
      mgr = CLLocationManager()
      mgr.desiredAccuracy = kCLLocationAccuracyBest
      mgr.requestAlwaysAuthorization()
      mgr.allowsBackgroundLocationUpdates = true

      super.init()
      mgr.delegate = self
    }

    func enable() {
      mgr.startUpdatingLocation()
    }

    func disable() {
      mgr.stopUpdatingLocation()
    }

      func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.first {
          location = currentLocation
          appendPin(location: currentLocation)
          updateRegion(location: currentLocation)
        }
      }

    func appendPin(location: CLLocation) {
      pins.append(PinLocation(coordinate: location.coordinate))
    }

    func updateRegion(location: CLLocation) {
      region = MKCoordinateRegion(
        center: location.coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015))
    }

    func startStopLocationTracking() {
      isLocationTrackingEnabled.toggle()
      if isLocationTrackingEnabled {
        enable()
      } else {
        disable()
      }
    }
  }
    
    

  struct PinLocation: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
  }
}
