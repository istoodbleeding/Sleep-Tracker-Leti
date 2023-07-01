
import SwiftUI
import CoreGraphics
import AVFoundation
import BackgroundTasks
import CoreLocation
import MapKit
import CoreData


class TrackingViewModel: NSObject, ObservableObject, CLLocationManagerDelegate{
    
    private var microphoneAccess = false
    private var locationAccess = false
    @Published  var isTracking: Bool = false
    @Published var soundLevel: Int = 0
    @Published var date = Date()
    var soundTime: Date?
    private let audioSession = AVAudioSession.sharedInstance()
    var audioRecorder: AVAudioRecorder! = nil
    var trackingBeginTime: Date?
    var trackingEndTime: Date?
    @Published var trackingDuration: String = "00:00:00"
    private var timerTracking: Timer?
    private var timerRecording: Timer?
    let locationManager: CLLocationManager
    var region : MKCoordinateRegion?
    var didUpdateLocations: [CLLocation] = []
    var currentLocation: CLLocation?
    var locationTime: Date?
    var longitude: Double?
    var latitude: Double?
    private let viewContext = PersistenceController.shared.viewContext
    let formatter = DateFormatter()
    var dayFormat: DateFormatter?
    var url: URL?
    var bathSoundSize = 0
    
    override init() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.requestAlwaysAuthorization()
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = true
        super.init()
        locationManager.delegate = self
        setupNotifications()
        dayFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
    }
    
    
    @MainActor
    func startRecording() {
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !isGranted {
                    fatalError("You must allow audio recording for this demo to work")
                }
            }
        }
        url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let settings: [String:Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVEncoderBitRateKey: 32000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
        ]
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default,  options: [.mixWithOthers,.allowBluetooth,.defaultToSpeaker, .allowAirPlay , .allowBluetoothA2DP])
            audioRecorder = try AVAudioRecorder(url: url!, settings: settings)
            audioRecorder.prepareToRecord()
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()
            try audioSession.setActive(true)
        }catch {
            print("error to start recording")
        }
        trackingBeginTime = Date()
        trackingEndTime = Date ()
        timerRecording = Timer.scheduledTimer(withTimeInterval: 0.2,  repeats: true)  {
            [ self] _ in
            date = Date()
            trackingEndTime = date
            bluetoothAudioConnected()
            if audioRecorder != nil {
                
                audioRecorder.updateMeters()
                
                soundLevel = Int( audioRecorder.averagePower(forChannel: 0) + 80)
                soundTime = Date()
                if bluetoothAudioConnected(){
                    soundLevel = 0
                }
                print("Sound: noise - \(soundLevel) at \(formatter.string(from: soundTime!))")
            
                 addSoundToCoreData(soundNoise: soundLevel, soundTime: soundTime!)

                
            }
            trackingTime()
            
        }
    }
    @MainActor
    func stopRecording() {
        timerRecording?.invalidate()
        print("Timer invalidated")
        timerRecording = nil
        if audioRecorder != nil {
            audioRecorder.stop()
            print("audio invalidated")
            audioRecorder = nil
        }
       
        do {
            try audioSession.setActive(false)
            try  FileManager.default.removeItem(at: url!)
        } catch {
            print("Error stopping recording")
        }
    }
    
    func setupNotifications() {
        // Get the default notification center instance.
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(handleInterruption),
                       name: AVAudioSession.interruptionNotification,
                       object: AVAudioSession.sharedInstance())
    }
    
    @MainActor @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        // Switch over the interruption type.
        switch type {
            
        case .began:
            // An interruption began. Update the UI as necessary.
            stopRecording()
            
        case .ended:
            // An interruption ended. Resume playback, if appropriate.
            startRecording()
            
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // An interruption ended. Resume playback.
            } else {
                // An interruption ended. Don't resume playback.
            }
            
        default: ()
        }
    }
    
    
    func startTracking(){
        startStopLocationTracking()
        if timerTracking == nil{
            timerTracking = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [self]_ in
                if isTracking == false {timerTracking?.invalidate()}
                latitude = currentLocation?.coordinate.latitude
                longitude = currentLocation?.coordinate.longitude
                locationTime = currentLocation?.timestamp
                
                print("Location: longitude - \(longitude), \n latitude - \(latitude) at \(formatter.string(from: locationTime!))")
                
                    addLocationToCoreData(locationLongitude: longitude!, locationLatitude: latitude!, locationTime: locationTime!)
            }
        }
    }
    
    func stopTracking(){
        timerTracking?.invalidate()
        timerTracking = nil
        startStopLocationTracking()
    }
    
    func toogleTracking(){
        self.isTracking.toggle()
    }
    
    func trackingTime(){
        let difference = trackingEndTime!.timeIntervalSince(trackingBeginTime!)
        let hours = Int(difference / 3600)
        let minutes = Int((difference.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(difference.truncatingRemainder(dividingBy: 60))
        trackingDuration = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        
    }
    
    
    func bluetoothAudioConnected() -> Bool{
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        for output in outputs{
            if output.portType == AVAudioSession.Port.bluetoothA2DP || output.portType == AVAudioSession.Port.bluetoothHFP || output.portType == AVAudioSession.Port.bluetoothLE{
                return true
            }
        }
        return false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      currentLocation = locations.first
      
    }
    
    
    func startStopLocationTracking() {
        locationAccess.toggle()
        if locationAccess {
            enable()
        } else {
            disable()
        }
        
    }
    func enable() {
        locationManager.startUpdatingLocation()
    }
    
    func disable() {
        locationManager.stopUpdatingLocation()
    }
    
    
    func addSoundToCoreData (soundNoise: Int, soundTime: Date ){
        let sound = Sound(context: viewContext)
        sound.id = UUID()
        sound.noise = Int16(soundNoise)
        sound.time = soundTime
        bathSoundSize += 1
        if bathSoundSize == 150 {
               viewContext.saveContext()
            bathSoundSize = 0
        }
    }
    func addLocationToCoreData (locationLongitude: Double, locationLatitude: Double, locationTime: Date){
        let location = Location(context: viewContext)
        location.id = UUID()
        location.longitude = locationLongitude
        location.latitude = locationLatitude
        location.time = locationTime
        viewContext.saveContext()

    }
    func dayFormatter(){
        dayFormat = DateFormatter()
        dayFormat!.dateFormat = "dd, MMMM"
    }

    func dayString(date: Date) -> String {
        let time = dayFormat!.string(from: date)
        return time
    }

    
    
}






