//
//  ViewController.swift
//  BGLocation
//
//  Created by dhaval nagar on 5/13/16.
//  Copyright © 2016 dhaval nagar. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate{

    let locationManager = CLLocationManager()
    var lastLocation: CLLocation?
    var lastReceivedLocation: CLLocation?
    
    var debug: Bool = true
    var timer: NSTimer?
    var isMoving: Bool = false
    
    // Stationary Timeout
    var stationaryTimeout:Double = 60;
    
    // Time based filters to ignore updates outside of the range
    var timeFilterStart = 9
    var timeFilterStop = 18
    var timeFilterEnabled = false
    
    // Distance based filter to ignore updates inside of the distance
    var distanceFilter: Double = 500
    var distanceFilterEnabled = true
    
    var logFileEnabled = false;
    var detailLog = true;
    
    var postUpdateToServer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start the service
        startService()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /*
        Start the Location Update Service
    */
    func startService(){
        self.locationManager.delegate = self
        
        // Accuracty is set to medium and will be adjusted later
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        self.locationManager.requestAlwaysAuthorization();
        
        // Significant Changes will be used later on for passive updates
        self.locationManager.startMonitoringSignificantLocationChanges();

        // Notifications for debuging purpose
        if debug {
            let notificationSettings = UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert, categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        }
    }
    
    func stopService(){
        self.locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    // Stop Significant Changes, Update Accuracy and Start Location Updates
    func startFrequentLocationUpdates(){
        log("Frequent Update Started");
        showNotification("Frequent Update Started");
        
        isMoving = true
        self.locationManager.stopMonitoringSignificantLocationChanges()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.locationManager.allowsBackgroundLocationUpdates = true // Must to set for iOS 9 and later
        
        self.locationManager.startUpdatingLocation()
    }
    
    // Stop Location Updates, Update Accuracy and Start Significant Changes
    func stopFrequentLocationUpdates(){
        log("Frequent Update Stopped");
        showNotification("Frequent Update Stopped");
        
        isMoving = false
        self.locationManager.stopUpdatingLocation()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        self.locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func getHour() -> Int{
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(NSCalendarUnit.Hour, fromDate:  NSDate())
        return components.hour
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(detailLog){
            showUpdateNotification(manager.location!)
        }
        lastReceivedLocation = manager.location!
        
        var meters : CLLocationDistance? = 0;
        
        // Check for Time Filter
        if timeFilterEnabled {
            // check whether current time is within the given time limit
            // or ignore the location
            let hour = getHour()
            if hour < timeFilterStart || hour > timeFilterStop {
                let logStr = "Hour \(hour) out of range \(timeFilterStart)-\(timeFilterStop)"
                log(logStr)
                showNotification(logStr)
                return
            }
        }
        
        // Distance Filter Login Here
        if !isMoving {
            if let loc = lastLocation{
                let currentLocation = CLLocation(latitude: manager.location!.coordinate.latitude, longitude: manager.location!.coordinate.longitude)
                meters = loc.distanceFromLocation(currentLocation)
                
                if !validDistance(meters!) {
                    let logStr = "Checking distance for Movement Detection \(meters!)"
                    log(logStr)
                    showNotification(logStr)
                    return
                }
            }
            
            isMoving = true
            self.startFrequentLocationUpdates()
            lastLocation = manager.location!
            
        }else{
            // Calculate distance from last saved location
            if let location = manager.location {
                let currentLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                meters = lastLocation!.distanceFromLocation(currentLocation)
            }
            
            if !validDistance(meters!) {
                let logStr = "Checking distance for Movement Detection \(meters!)"
                showNotification(logStr)
                return
            }
        }
        
        resetTimer()
        
        log("Distance from last: \(meters!)");
        
        lastLocation = manager.location
        if debug {
            showLocationNotification(manager.location!.coordinate, meters: meters!);
        }
    }
    
    func validDistance(let meters: CLLocationDistance) -> Bool{
        if distanceFilterEnabled {
            return meters > distanceFilter
        }else{
            return true
        }
    }
    
    func resetTimer(){
        if let t = timer{
            t.invalidate()
        }else{
            log("Stop Detection Timer Started")
        }
        
        timer = NSTimer.scheduledTimerWithTimeInterval(stationaryTimeout, target: self, selector: Selector("timerFired"), userInfo: nil, repeats: false)
    }
    
    // Stop Frequent Updates
    func timerFired(){
        self.stopFrequentLocationUpdates()
        lastLocation = lastReceivedLocation
        timer = nil
    }
    
    func showNotification(let text: String){
        let notification = UILocalNotification()
        notification.fireDate = NSDate(timeIntervalSinceNow: 1)
        
        notification.alertBody = text
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func showLocationNotification(let coordinate : CLLocationCoordinate2D, let meters: CLLocationDistance){
        log("Location updated: \(coordinate.latitude), \(coordinate.longitude)")
        let notification = UILocalNotification()
        notification.fireDate = NSDate(timeIntervalSinceNow: 1)
        
        notification.alertBody = "Latitude: \(coordinate.latitude), Longitude: \(coordinate.longitude), Disnance: \(meters)"
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func log(let logStr: String){
        print("\(logStr)")
        
        if(logFileEnabled){
            // log the statement in a file to use later
        }
    }
    
    func showUpdateNotification(let location : CLLocation?){
        let notification = UILocalNotification()
        notification.fireDate = NSDate(timeIntervalSinceNow: 1)
        
        if let loc = location{
            notification.alertBody = "Location Received lat: \(loc.coordinate.latitude), lng: \(loc.coordinate.longitude)"
        }else{
            notification.alertBody = "Location Update Received"
        }
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    
    func postToServer(){
        if !postUpdateToServer {
            return
        }
        
        // Post location data to server
    }
}

