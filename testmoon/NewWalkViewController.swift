//
//  NewRunViewController.swift
//  testmoon
//
//  Created by Jiameng Cen on 14/4/18.
//  Copyright © 2018 Jiameng Cen. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import CoreMotion
import Dispatch
import Firebase
import UserNotifications
//import FirebaseFirestore

class NewWalkViewController: UIViewController {
    
    @IBOutlet weak var launchPromptStackView: UIStackView!
    @IBOutlet weak var dataStackView: UIStackView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var stepCountLabel: UILabel!
    @IBOutlet weak var activityTypeLabel: UILabel!
    private var run: Run?
    private let locationManager = LocationManager.shared
    private var seconds = 0
    private var timer: Timer?
    private var distance = Measurement(value: 0, unit: UnitLength.meters)
    private var locationList: [CLLocation] = []
    
    let motionManager = MotionManager()
    // Authorization Check
    let pedometer = CMPedometer()
    let now = Date()
    let activityManager = CMMotionActivityManager()
    var shouldStartUpdating: Bool = false
    var startDate: Date? = nil
    
    //Firestore
    var db:Firestore!
    var userWalkArray = [userWalk]()
    
    
    //Mark :helper methonds
    
    func alerPedometerError(msg : String){
        let alert = UIAlertController(title:"Pedometer Access Error!",message:msg,preferredStyle:UIAlertControllerStyle.alert)
        let alertAction = UIAlertAction(title:"OK",style:UIAlertActionStyle.default){(UIAlertAction) -> Void in}
        alert.addAction(alertAction)
        present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataStackView.isHidden = true // required to work around behavior change in Xcode 9 beta 1
        locationManager.delegate = self as CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        pedometer.queryPedometerData(from:now, to:now) { (data, error) in
            if let code = error?._code {
                if code == CMErrorMotionActivityNotAuthorized.rawValue {
                    // Ask the user for authorization!
                }
            }
        }
        checkIfUserIsLoggedIn()
        db = Firestore.firestore()
    }
    
    func checkIfUserIsLoggedIn(){
        //user is not logged in
        if Auth.auth().currentUser?.uid == nil{
            //perform(#selector (handleLogout),with:nil,afterDelay:0)
            print("No currentUser login")
        } else {
            let uid = Auth.auth().currentUser?.uid
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value,with:{ (snapshot) in
                print(snapshot)
                
            })
        }
    }
    
    
    //show the step number animation
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let startDate = startDate else { return }
        updateStepsCountLabelUsing(startDate: startDate)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        locationManager.stopUpdatingLocation()
    }
    
    @IBAction func startTapped() {
        startRun()
        onStart()
    }
    
    @IBAction func stopTapped() {
        let alertController = UIAlertController(title: "End run?",
                                                message: "Do you wish to end your run?",
                                                preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Save and Uploaded", style: .default) { _ in
            self.stopRun()
            self.saveRun()
            self.performSegue(withIdentifier: .details, sender: nil)
 
        })
        alertController.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
            self.stopRun()
            _ = self.navigationController?.popToRootViewController(animated: true)
            
        })
        
        present(alertController, animated: true)
        onStop()
        handleUpload()
    }
    // some problems for upload even discard

    
    @objc func handleUpload(){
        let ref = Database.database().reference().child("UploadSteps")
        // is it there best thing to include the name inside of the message node
        let childRef = ref.childByAutoId()
        let toId = Auth.auth().currentUser?.uid
        let userEmail = UserDefaults.standard.string(forKey: "userEmail")
        let name = UserDefaults.standard.string(forKey:"userName")
        let timestamp = NSDate().timeIntervalSince1970
        let values = ["Steps":stepCountLabel.text,"fromId" :toId, "UserEmail": userEmail,"name":name,"timestamp":timestamp ] as [String : Any]
        //还是要学会变通啊
        childRef.updateChildValues(values)
        
        // next for FireStore
        let step = stepCountLabel.text
        //let email = userEmail
        let newuserWalk = userWalk(email:userEmail!,step:step!,timeStamp:Date())
        var refstore:DocumentReference? = nil
        refstore = self.db.collection("userWalk").addDocument(data: newuserWalk.dictionary){
            error in
            if let error = error {
                print("Error adding document: \(error.localizedDescription) ")
                
            }else{
                print("Document added with ID: \(refstore!.documentID)")
            }
        }
        
        
    }
    
    private func startRun() {
        launchPromptStackView.isHidden = true
        dataStackView.isHidden = false
        startButton.isHidden = true
        stopButton.isHidden = false
        mapContainerView.isHidden = false
        mapView.removeOverlays(mapView.overlays)
        
        seconds = 0
        distance = Measurement(value: 0, unit: UnitLength.meters)
        locationList.removeAll()
        updateDisplay()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.eachSecond()
        }
        startLocationUpdates()
    }
    
    private func stopRun() {
        launchPromptStackView.isHidden = false
        dataStackView.isHidden = true
        startButton.isHidden = false
        stopButton.isHidden = true
        mapContainerView.isHidden = true
        
        locationManager.stopUpdatingLocation()
    }
    
    func eachSecond() {
        seconds += 1
        updateDisplay()
    }
    
    private func updateDisplay() {
        let formattedDistance = FormatDisplay.distance(distance)
        let formattedTime = FormatDisplay.time(seconds)
        let formattedPace = FormatDisplay.pace(distance: distance,
                                               seconds: seconds,
                                               outputUnit: UnitSpeed.minutesPerMile)
        
        distanceLabel.text = "Distance:  \(formattedDistance)"
        timeLabel.text = "Time:  \(formattedTime)"
        paceLabel.text = "Pace:  \(formattedPace)"
    }
    
    private func startLocationUpdates() {
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
    }
    
    private func saveRun() {
        let newRun = Run(context: CoreDataStack.context)
        newRun.distance = distance.value
        newRun.duration = Int16(seconds)
        newRun.timestamp = Date()
        
        for location in locationList {
            let locationObject = Location(context: CoreDataStack.context)
            locationObject.timestamp = location.timestamp
            locationObject.latitude = location.coordinate.latitude
            locationObject.longitude = location.coordinate.longitude
            newRun.addToLocations(locationObject)
        }
        
        CoreDataStack.saveContext()
        
        run = newRun
    }
}

// MARK: - Navigation

extension NewWalkViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case details = "RunDetailsViewController"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .details:
            let destination = segue.destination as! RunDetailsViewController
            destination.run = run
        }
    }
}

// MARK: - Location Manager Delegate

extension NewWalkViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for newLocation in locations {
            let howRecent = newLocation.timestamp.timeIntervalSinceNow
            guard newLocation.horizontalAccuracy < 20 && abs(howRecent) < 10 else { continue }
            
            if let lastLocation = locationList.last {
                let delta = newLocation.distance(from: lastLocation)
                distance = distance + Measurement(value: delta, unit: UnitLength.meters)
                let coordinates = [lastLocation.coordinate, newLocation.coordinate]
                mapView.add(MKPolyline(coordinates: coordinates, count: 2))
                let region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 500, 500)
                mapView.setRegion(region, animated: true)
            }
            
            locationList.append(newLocation)
        }
    }
}

// MARK: - Map View Delegate

extension NewWalkViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = .blue
        renderer.lineWidth = 3
        return renderer
    }
}

extension NewWalkViewController {
    func onStart() {
        //startButton.setTitle("Stop", for: .normal)
        startDate = Date()
        checkAuthorizationStatus()
        startUpdating()
    }
    
    func onStop() {
        //startButton.setTitle("Start", for: .normal)
        startDate = nil
        stopUpdating()
    }
    //Start getting updates
    func startUpdating() {
        if CMMotionActivityManager.isActivityAvailable() {
            startTrackingActivityType()
        } else {
            activityTypeLabel.text = "Not available"
        }
        
        if CMPedometer.isStepCountingAvailable() {
            startCountingSteps()
        } else {
            stepCountLabel.text = "Not available"
        }
    }
    
    func stopUpdating() {
        activityManager.stopActivityUpdates()
        pedometer.stopUpdates()
        pedometer.stopEventUpdates()
    }
    
    func checkAuthorizationStatus() {
        switch CMMotionActivityManager.authorizationStatus() {
        case CMAuthorizationStatus.denied:
            onStop()
            activityTypeLabel.text = "Not available"
            stepCountLabel.text = "Not available"
        default:break
        }
    }
    
    func on(error: Error) {
        //handle error
    }
    
    func updateStepsCountLabelUsing(startDate: Date) {
        pedometer.queryPedometerData(from: startDate, to: Date()) {
            [weak self] pedometerData, error in
            if let error = error {
                self?.on(error: error)
            } else if let pedometerData = pedometerData {
                DispatchQueue.main.async {
                    self?.stepCountLabel.text = String(describing: pedometerData.numberOfSteps)
                    // this step show changing data
                }
            }
        }
    }
    
    func startTrackingActivityType() {
        activityManager.startActivityUpdates(to: OperationQueue.main) {
            [weak self] (activity: CMMotionActivity?) in
            guard let activity = activity else { return }
            DispatchQueue.main.async {
                if activity.walking {
                    self?.activityTypeLabel.text = "Walking"
                } else if activity.stationary {
                    self?.activityTypeLabel.text = "Stationary"
                } else if activity.running {
                    self?.activityTypeLabel.text = "Running"
                } else if activity.automotive {
                    self?.activityTypeLabel.text = "Automotive"
                }
            }
        }
    }
    
    // Create a method for tracking activity events
    func startCountingSteps() {
        pedometer.startUpdates(from: Date()) {
            [weak self] pedometerData, error in
            guard let pedometerData = pedometerData, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.stepCountLabel.text = pedometerData.numberOfSteps.stringValue
            }
        }
    }
}


